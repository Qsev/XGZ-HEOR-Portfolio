library(survival)
library(jsonlite)

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0) y else x

read_segments <- function(path) {
  x <- read.csv(path, stringsAsFactors = FALSE)
  names(x) <- c("arm", "start", "end", "surv")
  x[order(x$start, x$end), ]
}

read_nar_json <- function(path) {
  fromJSON(path, simplifyVector = TRUE)
}

event_drops_from_segments <- function(segments, min_drop = 0.002) {
  previous <- 1.0
  out <- list()
  for (i in seq_len(nrow(segments))) {
    drop <- previous - segments$surv[i]
    if (drop >= min_drop) {
      out[[length(out) + 1]] <- data.frame(
        time = max(0, segments$start[i]),
        surv_before = previous,
        surv_after = segments$surv[i],
        drop = drop
      )
    }
    previous <- min(previous, segments$surv[i])
  }
  if (length(out) == 0) {
    data.frame(time = numeric(), surv_before = numeric(), surv_after = numeric(), drop = numeric())
  } else {
    do.call(rbind, out)
  }
}

interval_index <- function(t, interval_times) {
  idx <- findInterval(t, interval_times, rightmost.closed = FALSE)
  pmin(pmax(idx, 1), length(interval_times) - 1)
}

km_median_manual <- function(ipd) {
  at_risk <- nrow(ipd)
  surv <- 1.0
  for (tt in sort(unique(ipd$time))) {
    d <- sum(ipd$time == tt & ipd$status == 1)
    c <- sum(ipd$time == tt & ipd$status == 0)
    if (d > 0 && at_risk > 0) {
      surv <- surv * (1 - d / at_risk)
      if (surv <= 0.5) return(tt)
    }
    at_risk <- at_risk - d - c
  }
  NA_real_
}

reconstruct_arm <- function(arm_name, segment_path, nar_times, nar_values, target_events) {
  segments <- read_segments(segment_path)
  drops <- event_drops_from_segments(segments)

  weighted <- list()
  running_risk <- nar_values[-length(nar_values)]
  if (nrow(drops) > 0) {
    for (i in seq_len(nrow(drops))) {
      int_idx <- interval_index(drops$time[i], nar_times)
      ratio <- max(0, min(1, drops$surv_after[i] / drops$surv_before[i]))
      raw_events <- max(0, running_risk[int_idx] * (1 - ratio))
      if (raw_events > 0) {
        weighted[[length(weighted) + 1]] <- data.frame(
          time = drops$time[i],
          surv_before = drops$surv_before[i],
          surv_after = drops$surv_after[i],
          drop = drops$drop[i],
          interval = int_idx,
          raw_events = raw_events,
          events = round(raw_events)
        )
        running_risk[int_idx] <- max(0, running_risk[int_idx] - raw_events)
      }
    }
  }
  weighted <- if (length(weighted) == 0) {
    data.frame(time = numeric(), surv_before = numeric(), surv_after = numeric(), drop = numeric(),
               interval = integer(), raw_events = numeric(), events = integer())
  } else {
    do.call(rbind, weighted)
  }

  excess <- sum(weighted$events) - target_events
  if (nrow(weighted) > 0 && excess > 0) {
    ranked <- order(weighted$drop, -weighted$time)
    while (excess > 0 && any(weighted$events > 0)) {
      for (k in ranked) {
        if (excess <= 0) break
        if (weighted$events[k] > 0) {
          weighted$events[k] <- weighted$events[k] - 1
          excess <- excess - 1
        }
      }
    }
  } else if (nrow(weighted) > 0 && excess < 0) {
    deficit <- -excess
    ranked <- order(weighted$raw_events, decreasing = TRUE)
    i <- 1
    while (deficit > 0) {
      k <- ranked[((i - 1) %% length(ranked)) + 1]
      weighted$events[k] <- weighted$events[k] + 1
      deficit <- deficit - 1
      i <- i + 1
    }
  }

  ipd <- data.frame(id = character(), arm = character(), time = numeric(), status = integer())
  next_id <- 1
  event_rows <- data.frame(interval = integer(), time = numeric(), events = integer())
  censor_rows <- data.frame(interval = integer(), censors = integer())

  for (i in seq_len(length(nar_times) - 1)) {
    start <- nar_times[i]
    end <- nar_times[i + 1]
    nrisk <- nar_values[i]
    desired_next <- nar_values[i + 1]
    w <- weighted[weighted$interval == i, , drop = FALSE]
    interval_events <- data.frame(time = numeric(), events = integer())

    if (nrow(w) > 0) {
      for (j in seq_len(nrow(w))) {
        d <- max(0, min(w$events[j], nrisk))
        if (d > 0) {
          interval_events <- rbind(interval_events, data.frame(time = w$time[j], events = d))
          nrisk <- nrisk - d
        }
      }
    }

    c_count <- max(0, nrisk - desired_next)
    last_event_t <- if (nrow(interval_events) > 0) max(interval_events$time) else start
    c_start <- min(end, max(start, last_event_t + 1e-4))
    censor_times <- if (c_count == 0) {
      numeric()
    } else if (c_count == 1) {
      (c_start + end) / 2
    } else {
      c_start + (end - c_start) * seq_len(c_count) / (c_count + 1)
    }

    if (nrow(interval_events) > 0) {
      for (j in seq_len(nrow(interval_events))) {
        for (k in seq_len(interval_events$events[j])) {
          ipd <- rbind(ipd, data.frame(
            id = sprintf("%s_%d", arm_name, next_id),
            arm = arm_name,
            time = interval_events$time[j],
            status = 1
          ))
          next_id <- next_id + 1
        }
      }
      event_rows <- rbind(event_rows, transform(interval_events, interval = i))
    }

    for (tt in censor_times) {
      ipd <- rbind(ipd, data.frame(
        id = sprintf("%s_%d", arm_name, next_id),
        arm = arm_name,
        time = tt,
        status = 0
      ))
      next_id <- next_id + 1
    }
    censor_rows <- rbind(censor_rows, data.frame(interval = i, censors = length(censor_times)))
  }

  remaining <- nar_values[length(nar_values)]
  last_time <- max(c(segments$end, nar_times[length(nar_times)]))
  if (remaining > 0) {
    for (k in seq_len(remaining)) {
      ipd <- rbind(ipd, data.frame(
        id = sprintf("%s_%d", arm_name, next_id),
        arm = arm_name,
        time = last_time,
        status = 0
      ))
      next_id <- next_id + 1
    }
  }

  validation <- data.frame(
    time_months = nar_times,
    published_nar = nar_values,
    reconstructed_nar = sapply(nar_times, function(tt) sum(ipd$time >= tt - 1e-9))
  )
  validation$difference <- validation$reconstructed_nar - validation$published_nar

  list(
    ipd = ipd,
    event_rows = event_rows,
    censor_rows = censor_rows,
    validation = validation,
    summary = data.frame(
      arm = arm_name,
      n = nrow(ipd),
      events = sum(ipd$status),
      target_events = target_events,
      event_difference = sum(ipd$status) - target_events,
      median_months = km_median_manual(ipd)
    )
  )
}

run_reconstruction <- function(base_dir = getwd()) {
  nar <- read_nar_json(file.path(base_dir, "dMMR_PFS_nar.json"))
  specs <- list(
    pembro_chemo = list(path = "dMMR_PFS_pembro_step_segments.csv", meta = nar$arms$pembro_chemo),
    placebo_chemo = list(path = "dMMR_PFS_placebo_step_segments_revised.csv", meta = nar$arms$placebo_chemo)
  )

  results <- list()
  all_ipd <- data.frame(id = character(), arm = character(), time = numeric(), status = integer())
  for (arm in names(specs)) {
    res <- reconstruct_arm(
      arm,
      file.path(base_dir, specs[[arm]]$path),
      nar$time_months,
      specs[[arm]]$meta$nar,
      specs[[arm]]$meta$events_reported
    )
    results[[arm]] <- res
    all_ipd <- rbind(all_ipd, res$ipd)
    write.csv(res$ipd, file.path(base_dir, sprintf("%s_dMMR_PFS_pseudo_ipd_R.csv", arm)), row.names = FALSE)
    write.csv(res$validation, file.path(base_dir, sprintf("%s_nar_validation_R.csv", arm)), row.names = FALSE)
  }
  write.csv(all_ipd, file.path(base_dir, "dMMR_PFS_pseudo_ipd_combined_R.csv"), row.names = FALSE)

  all_ipd$arm <- factor(all_ipd$arm, levels = c("placebo_chemo", "pembro_chemo"))
  fit <- survfit(Surv(time, status) ~ arm, data = all_ipd)
  cox <- coxph(Surv(time, status) ~ arm, data = all_ipd)
  hr <- exp(coef(cox))[1]
  ci <- exp(confint(cox))[1, ]
  med <- summary(fit)$table[, "median"]
  stats <- data.frame(
    metric = c("Cox HR pembro vs placebo", "HR CI lower", "HR CI upper", "Median placebo", "Median pembro"),
    value = c(hr, ci[1], ci[2], med["arm=placebo_chemo"], med["arm=pembro_chemo"]),
    target = c(0.30, 0.19, 0.48, 7.6, NA)
  )
  write.csv(stats, file.path(base_dir, "dMMR_PFS_statistical_validation_R.csv"), row.names = FALSE)
  print(do.call(rbind, lapply(results, `[[`, "summary")))
  print(stats)
}

args <- commandArgs(trailingOnly = TRUE)
run_reconstruction(if (length(args) >= 1) args[1] else getwd())
