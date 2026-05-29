#!/usr/bin/env python3
import csv
import json
import math
from pathlib import Path


HERE = Path(__file__).resolve().parent


def read_segments(path):
    rows = []
    with open(path, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(
                {
                    "arm": row["arm"],
                    "start": float(row["start_time_months"]),
                    "end": float(row["end_time_months"]),
                    "surv": float(row["survival"]),
                }
            )
    rows.sort(key=lambda x: (x["start"], x["end"]))
    return rows


def event_drops_from_segments(segments, min_drop=0.002):
    drops = []
    previous_surv = 1.0
    for seg in segments:
        drop = previous_surv - seg["surv"]
        if drop >= min_drop:
            drops.append(
                {
                    "time": max(0.0, seg["start"]),
                    "surv_before": previous_surv,
                    "surv_after": seg["surv"],
                    "drop": drop,
                }
            )
        previous_surv = min(previous_surv, seg["surv"])
    return drops


def interval_index(t, interval_times):
    for i in range(len(interval_times) - 1):
        if interval_times[i] <= t < interval_times[i + 1]:
            return i
    return len(interval_times) - 2


def reconstruct_arm(arm_name, segment_path, nar_times, nar_values, target_events):
    segments = read_segments(segment_path)
    drops = event_drops_from_segments(segments)

    # Estimate event weights interval by interval, then constrain total event count to
    # the published arm-level number of events. This avoids treating anti-aliased
    # micro-drops as extra events.
    weighted_drops = []
    running_risk = {i: nar_values[i] for i in range(len(nar_times) - 1)}
    for drop in drops:
        i = interval_index(drop["time"], nar_times)
        ratio = max(0.0, min(1.0, drop["surv_after"] / drop["surv_before"]))
        raw_events = max(0.0, running_risk[i] * (1.0 - ratio))
        if raw_events > 0:
            weighted_drops.append({**drop, "interval": i, "raw_events": raw_events})
            running_risk[i] = max(0.0, running_risk[i] - raw_events)

    for d in weighted_drops:
        d["events"] = int(round(d["raw_events"]))

    raw_event_total = sum(d["events"] for d in weighted_drops)
    excess = raw_event_total - target_events
    if excess > 0:
        # Preserve clinically important KM drops and remove excess events
        # preferentially from the smallest visual survival drops that are more
        # likely to reflect anti-aliasing or censor-mark contamination. A late
        # event may have low raw event weight because few patients remain at
        # risk, but it can still create a large KM step and should be retained.
        ranked = sorted(
            range(len(weighted_drops)),
            key=lambda k: (weighted_drops[k]["drop"], -weighted_drops[k]["time"]),
        )
        while excess > 0:
            changed = False
            for k in ranked:
                if excess <= 0:
                    break
                if weighted_drops[k]["events"] > 0:
                    weighted_drops[k]["events"] -= 1
                    excess -= 1
                    changed = True
            if not changed:
                break
    elif excess < 0:
        deficit = -excess
        # Add missing events to the largest observed drops first.
        ranked = sorted(
            range(len(weighted_drops)),
            key=lambda k: weighted_drops[k]["raw_events"],
            reverse=True,
        )
        i = 0
        while deficit > 0 and ranked:
            weighted_drops[ranked[i % len(ranked)]]["events"] += 1
            deficit -= 1
            i += 1

    # Allocate event counts interval by interval. Censoring is placed after observed
    # event drops within each NAR interval to force agreement with published risk sets.
    ipd = []
    event_rows = []
    censor_rows = []
    next_id = 1
    total_events = 0

    drops_by_interval = {i: [] for i in range(len(nar_times) - 1)}
    for drop in weighted_drops:
        drops_by_interval[drop["interval"]].append(drop)

    for i in range(len(nar_times) - 1):
        start = nar_times[i]
        end = nar_times[i + 1]
        nrisk = nar_values[i]
        desired_next = nar_values[i + 1]
        interval_events = []

        for drop in drops_by_interval[i]:
            d = int(drop["events"])
            d = max(0, min(d, nrisk))
            if d > 0:
                interval_events.append((drop["time"], d))
                nrisk -= d
                total_events += d

        # Force the next risk-set count. This is the key NAR constraint.
        c = max(0, nrisk - desired_next)
        if c > 0:
            # Spread censoring after the last event and before the next NAR point.
            last_event_t = max([t for t, _ in interval_events], default=start)
            c_start = min(end, max(start, last_event_t + 1e-4))
            if c == 1:
                censor_times = [(c_start + end) / 2.0]
            else:
                censor_times = [
                    c_start + (end - c_start) * (k + 1) / (c + 1)
                    for k in range(c)
                ]
        else:
            censor_times = []

        for t, d in interval_events:
            for _ in range(d):
                ipd.append(
                    {
                        "id": f"{arm_name}_{next_id}",
                        "arm": arm_name,
                        "time": t,
                        "status": 1,
                    }
                )
                next_id += 1
            event_rows.append({"interval": i, "time": t, "events": d})

        for t in censor_times:
            ipd.append(
                {
                    "id": f"{arm_name}_{next_id}",
                    "arm": arm_name,
                    "time": t,
                    "status": 0,
                }
            )
            next_id += 1
        censor_rows.append({"interval": i, "censors": len(censor_times)})

    # Censor anyone still at risk after the final NAR time at the last observed curve time.
    remaining = nar_values[-1]
    last_time = max([s["end"] for s in segments] + [nar_times[-1]])
    for _ in range(remaining):
        ipd.append(
            {
                "id": f"{arm_name}_{next_id}",
                "arm": arm_name,
                "time": last_time,
                "status": 0,
            }
        )
        next_id += 1

    # Total N can drift if an interval has impossible event/censor allocation after rounding.
    # Keep this visible rather than silently correcting it.
    validation = validate_arm(ipd, nar_times, nar_values, target_events)
    validation["estimated_events_before_event_count_adjustment"] = total_events

    return ipd, event_rows, censor_rows, validation


def validate_arm(ipd, nar_times, nar_values, target_events):
    validation_rows = []
    for t, published in zip(nar_times, nar_values):
        # KM convention: at risk just before t includes patients with event/censor at t.
        reconstructed = sum(1 for row in ipd if row["time"] >= t - 1e-9)
        validation_rows.append(
            {
                "time_months": t,
                "published_nar": published,
                "reconstructed_nar": reconstructed,
                "difference": reconstructed - published,
            }
        )
    events = sum(row["status"] for row in ipd)
    return {
        "n": len(ipd),
        "events": events,
        "target_events": target_events,
        "event_difference": events - target_events,
        "nar_validation": validation_rows,
        "median_months": km_median(ipd),
    }


def km_median(ipd):
    n = len(ipd)
    if n == 0:
        return None
    at_risk = n
    surv = 1.0
    all_times = sorted({row["time"] for row in ipd})
    for t in all_times:
        d = sum(1 for row in ipd if row["time"] == t and row["status"] == 1)
        c = sum(1 for row in ipd if row["time"] == t and row["status"] == 0)
        if d > 0 and at_risk > 0:
            surv *= 1.0 - d / at_risk
        if d > 0 and surv <= 0.5:
            return t
        at_risk -= d + c
    return None


def write_csv(path, rows, columns):
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)


def main():
    nar = json.loads((HERE / "dMMR_PFS_nar.json").read_text())
    nar_times = nar["time_months"]

    segment_paths = {
        "pembro_chemo": HERE / "dMMR_PFS_pembro_step_segments.csv",
        "placebo_chemo": HERE / "dMMR_PFS_placebo_step_segments_revised.csv",
    }

    all_ipd = []
    report = {}
    for arm, path in segment_paths.items():
        meta = nar["arms"][arm]
        ipd, event_rows, censor_rows, validation = reconstruct_arm(
            arm,
            path,
            nar_times,
            meta["nar"],
            meta["events_reported"],
        )
        all_ipd.extend(ipd)
        write_csv(HERE / f"{arm}_dMMR_PFS_pseudo_ipd.csv", ipd, ["id", "arm", "time", "status"])
        write_csv(HERE / f"{arm}_event_allocation.csv", event_rows, ["interval", "time", "events"])
        write_csv(HERE / f"{arm}_censor_allocation.csv", censor_rows, ["interval", "censors"])
        report[arm] = validation

    write_csv(HERE / "dMMR_PFS_pseudo_ipd_combined.csv", all_ipd, ["id", "arm", "time", "status"])
    (HERE / "dMMR_PFS_guyot_style_validation.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8"
    )
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
