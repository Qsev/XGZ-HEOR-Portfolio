#!/usr/bin/env python3
"""
Event-drop cleaning reconstruction for Kaplan-Meier pseudo-IPD.

This script is intended for the post-digitisation stage:

  accepted/revised KM step segments
    -> event-drop cleaning under NAR + reported-event constraints
    -> pseudo-IPD
    -> optional reconstructed-KM overlay on the published figure

It does not perform HSV image digitisation. Use it only after the raw/step
curve has been visually validated.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import random
from dataclasses import dataclass
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw
except ImportError:  # pragma: no cover - overlay is optional
    Image = None
    ImageDraw = None


@dataclass
class Segment:
    start: float
    end: float
    survival: float


@dataclass
class Drop:
    time: float
    target_survival: float
    raw_drop: float
    interval: int


def read_segments(path: Path) -> list[Segment]:
    rows: list[Segment] = []
    with path.open(newline="") as f:
        for row in csv.DictReader(f):
            rows.append(
                Segment(
                    start=float(row["start_time_months"]),
                    end=float(row["end_time_months"]),
                    survival=float(row["survival"]),
                )
            )
    return sorted(rows, key=lambda x: (x.start, x.end))


def read_nar(path: Path, arm: str) -> tuple[list[float], list[int], int, dict[str, Any]]:
    nar = json.loads(path.read_text())
    arm_meta = nar["arms"][arm]
    target_events = int(arm_meta["events_reported"])
    return list(map(float, nar["time_months"])), list(map(int, arm_meta["nar"])), target_events, nar


def interval_index(t: float, times: list[float]) -> int:
    for i in range(len(times) - 1):
        if times[i] <= t < times[i + 1]:
            return i
    return len(times) - 2


def identify_drops(segments: list[Segment], times: list[float], min_drop: float) -> list[Drop]:
    previous = 1.0
    drops: list[Drop] = []
    for seg in segments:
        drop = previous - seg.survival
        if drop >= min_drop:
            drops.append(
                Drop(
                    time=max(0.0, seg.start),
                    target_survival=seg.survival,
                    raw_drop=drop,
                    interval=interval_index(seg.start, times),
                )
            )
        previous = min(previous, seg.survival)
    return drops


def seed_event_allocation(
    drops: list[Drop],
    drops_by_interval: dict[int, list[int]],
    removals_by_interval: list[int],
    target_events: int,
    max_events_per_drop: int,
) -> list[int]:
    events = [0] * len(drops)
    interval_used = [0] * len(removals_by_interval)
    ranked = sorted(range(len(drops)), key=lambda k: drops[k].raw_drop, reverse=True)

    for k in ranked:
        if sum(events) >= target_events:
            break
        i = drops[k].interval
        if interval_used[i] < removals_by_interval[i]:
            events[k] = 1
            interval_used[i] += 1

    while sum(events) < target_events:
        changed = False
        for k in ranked:
            i = drops[k].interval
            if interval_used[i] < removals_by_interval[i] and events[k] < max_events_per_drop:
                events[k] += 1
                interval_used[i] += 1
                changed = True
                if sum(events) >= target_events:
                    break
        if not changed:
            break

    if sum(events) != target_events:
        raise ValueError(
            f"Could not seed {target_events} events under NAR interval removals; seeded {sum(events)}."
        )

    return events


def is_feasible(
    events: list[int],
    drops_by_interval: dict[int, list[int]],
    removals_by_interval: list[int],
    target_events: int,
) -> bool:
    if sum(events) != target_events:
        return False
    return all(
        sum(events[k] for k in drops_by_interval[i]) <= removals_by_interval[i]
        for i in range(len(removals_by_interval))
    )


def build_ipd_and_score(
    *,
    arm: str,
    events: list[int],
    drops: list[Drop],
    drops_by_interval: dict[int, list[int]],
    times: list[float],
    nar_values: list[int],
    removals_by_interval: list[int],
    segments: list[Segment],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], float]:
    ipd: list[dict[str, Any]] = []
    cleaning_table: list[dict[str, Any]] = []
    next_id = 1
    sse = 0.0
    n_points = 0
    global_survival = 1.0

    for i in range(len(times) - 1):
        risk = nar_values[i]
        interval_drop_ids = drops_by_interval[i]
        remaining_censors = removals_by_interval[i] - sum(events[k] for k in interval_drop_ids)

        for k in interval_drop_ids:
            allocated_events = events[k]
            drop = drops[k]
            censors_before = 0

            if allocated_events > 0 and drop.target_survival < global_survival and risk > 0:
                denominator = max(1e-9, 1.0 - drop.target_survival / global_survival)
                desired_risk = allocated_events / denominator
                censors_before = round(risk - desired_risk)
                censors_before = max(0, min(remaining_censors, censors_before))

            censor_time = max(times[i], drop.time - 1e-4)
            for _ in range(censors_before):
                ipd.append(
                    {
                        "id": f"{arm}_{next_id}",
                        "arm": arm,
                        "time": round(censor_time, 6),
                        "status": 0,
                    }
                )
                next_id += 1

            risk -= censors_before
            remaining_censors -= censors_before

            if allocated_events > 0 and risk > 0:
                actual_events = min(allocated_events, risk)
                for _ in range(actual_events):
                    ipd.append(
                        {
                            "id": f"{arm}_{next_id}",
                            "arm": arm,
                            "time": round(drop.time, 6),
                            "status": 1,
                        }
                    )
                    next_id += 1
                global_survival *= 1.0 - actual_events / risk
                risk -= actual_events
            else:
                actual_events = 0

            error = global_survival - drop.target_survival
            sse += error * error
            n_points += 1
            cleaning_table.append(
                {
                    "drop_id": k + 1,
                    "interval": i + 1,
                    "time_months": round(drop.time, 6),
                    "raw_target_survival": round(drop.target_survival, 6),
                    "raw_drop": round(drop.raw_drop, 6),
                    "allocated_events": actual_events,
                    "censors_before_drop": censors_before,
                    "reconstructed_survival_after_drop": round(global_survival, 6),
                    "survival_error": round(error, 6),
                    "cleaning_action": "kept" if actual_events > 0 else "removed_or_merged",
                }
            )

        # Put any remaining interval censors after the last observed drop in the interval.
        if interval_drop_ids:
            censor_time = min(times[i + 1], drops[interval_drop_ids[-1]].time + 1e-4)
        else:
            censor_time = (times[i] + times[i + 1]) / 2.0

        for _ in range(remaining_censors):
            ipd.append(
                {
                    "id": f"{arm}_{next_id}",
                    "arm": arm,
                    "time": round(censor_time, 6),
                    "status": 0,
                }
            )
            next_id += 1

    final_censors = nar_values[-1]
    final_time = round(max([seg.end for seg in segments] + [times[-1]]), 6)
    for _ in range(final_censors):
        ipd.append({"id": f"{arm}_{next_id}", "arm": arm, "time": final_time, "status": 0})
        next_id += 1

    rmse = math.sqrt(sse / max(1, n_points))
    return ipd, cleaning_table, rmse


def optimise_events(
    *,
    arm: str,
    drops: list[Drop],
    drops_by_interval: dict[int, list[int]],
    removals_by_interval: list[int],
    target_events: int,
    times: list[float],
    nar_values: list[int],
    segments: list[Segment],
    iterations: int,
    max_events_per_drop: int,
    seed: int,
    initial_temperature: float,
    final_temperature: float,
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[int], float]:
    rng = random.Random(seed)
    current_events = seed_event_allocation(
        drops, drops_by_interval, removals_by_interval, target_events, max_events_per_drop
    )
    current_ipd, current_table, current_score = build_ipd_and_score(
        arm=arm,
        events=current_events,
        drops=drops,
        drops_by_interval=drops_by_interval,
        times=times,
        nar_values=nar_values,
        removals_by_interval=removals_by_interval,
        segments=segments,
    )

    best_events = current_events[:]
    best_ipd = current_ipd
    best_table = current_table
    best_score = current_score

    for it in range(iterations):
        candidate = current_events[:]
        positive = [i for i, value in enumerate(candidate) if value > 0]
        if not positive:
            break
        src = rng.choice(positive)
        dst = rng.randrange(len(candidate))
        if src == dst:
            continue
        candidate[src] -= 1
        candidate[dst] += 1
        if candidate[dst] > max_events_per_drop:
            continue
        if not is_feasible(candidate, drops_by_interval, removals_by_interval, target_events):
            continue

        ipd, table, score = build_ipd_and_score(
            arm=arm,
            events=candidate,
            drops=drops,
            drops_by_interval=drops_by_interval,
            times=times,
            nar_values=nar_values,
            removals_by_interval=removals_by_interval,
            segments=segments,
        )

        progress = it / max(1, iterations)
        temperature = max(final_temperature, initial_temperature * (1.0 - progress))
        accept = score < current_score
        if not accept and temperature > 0:
            accept = rng.random() < math.exp((current_score - score) / temperature)

        if accept:
            current_events = candidate
            current_ipd = ipd
            current_table = table
            current_score = score
            if score < best_score:
                best_events = candidate[:]
                best_ipd = ipd
                best_table = table
                best_score = score

    return best_ipd, best_table, best_events, best_score


def write_csv(path: Path, rows: list[dict[str, Any]], columns: list[str]) -> None:
    with path.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)


def km_path(ipd_rows: list[dict[str, Any]]) -> list[tuple[float, float]]:
    rows = [
        {"time": float(row["time"]), "status": int(row["status"])}
        for row in ipd_rows
    ]
    if not rows:
        return []
    at_risk = len(rows)
    survival = 1.0
    points = [(0.0, 1.0)]
    for t in sorted({row["time"] for row in rows}):
        d = sum(1 for row in rows if row["time"] == t and row["status"] == 1)
        c = sum(1 for row in rows if row["time"] == t and row["status"] == 0)
        if d and at_risk > 0:
            points.append((t, survival))
            survival *= 1.0 - d / at_risk
            points.append((t, survival))
        at_risk -= d + c
    points.append((max(row["time"] for row in rows), survival))
    return points


def draw_overlay(
    *,
    image_path: Path,
    summary_json: Path,
    output_path: Path,
    ipd_rows: list[dict[str, Any]],
    colour: tuple[int, int, int, int],
    line_width: int,
) -> None:
    if Image is None or ImageDraw is None:
        raise RuntimeError("Pillow is required for overlay output but is not installed.")

    summary = json.loads(summary_json.read_text())
    cal = summary["axis_calibration"]

    def to_xy(t: float, s: float) -> tuple[float, float]:
        x = (t - cal["x_intercept_months"]) / cal["x_months_per_pixel"]
        y = cal["y_surv1_pixel"] + (1.0 - s) * (cal["y_surv0_pixel"] - cal["y_surv1_pixel"])
        return x, y

    image = Image.open(image_path).convert("RGBA")
    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    points = [to_xy(t, s) for t, s in km_path(ipd_rows)]
    if len(points) > 1:
        draw.line(points, fill=colour, width=line_width)
    Image.alpha_composite(image, overlay).convert("RGB").save(output_path)


def parse_colour(value: str) -> tuple[int, int, int, int]:
    named = {
        "magenta": (255, 0, 180, 230),
        "cyan": (0, 210, 255, 230),
        "orange": (255, 110, 0, 230),
    }
    if value in named:
        return named[value]
    parts = [int(x) for x in value.split(",")]
    if len(parts) == 3:
        parts.append(230)
    if len(parts) != 4:
        raise ValueError("Colour must be a name or R,G,B[,A].")
    return tuple(parts)  # type: ignore[return-value]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--segments", required=True, type=Path, help="Accepted/revised KM step segments CSV.")
    parser.add_argument("--nar-json", required=True, type=Path, help="NAR/published constraints JSON.")
    parser.add_argument("--arm", required=True, help="Arm key in the NAR JSON, e.g. pembro_chemo.")
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument("--prefix", required=True, help="Output filename prefix.")
    parser.add_argument("--min-drop", type=float, default=0.002)
    parser.add_argument("--iterations", type=int, default=120000)
    parser.add_argument("--max-events-per-drop", type=int, default=7)
    parser.add_argument("--seed", type=int, default=1092)
    parser.add_argument("--initial-temperature", type=float, default=0.018)
    parser.add_argument("--final-temperature", type=float, default=0.0002)
    parser.add_argument("--image", type=Path, help="Original plot image for optional overlay.")
    parser.add_argument("--summary-json", type=Path, help="Extraction summary JSON for optional overlay.")
    parser.add_argument("--overlay-colour", default="magenta", help="magenta, cyan, orange, or R,G,B[,A].")
    parser.add_argument("--line-width", type=int, default=4)
    args = parser.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    segments = read_segments(args.segments)
    times, nar_values, target_events, _ = read_nar(args.nar_json, args.arm)
    removals_by_interval = [nar_values[i] - nar_values[i + 1] for i in range(len(nar_values) - 1)]
    drops = identify_drops(segments, times, args.min_drop)
    drops_by_interval = {i: [] for i in range(len(times) - 1)}
    for k, drop in enumerate(drops):
        drops_by_interval[drop.interval].append(k)

    ipd, cleaning_table, event_allocation, score = optimise_events(
        arm=args.arm,
        drops=drops,
        drops_by_interval=drops_by_interval,
        removals_by_interval=removals_by_interval,
        target_events=target_events,
        times=times,
        nar_values=nar_values,
        segments=segments,
        iterations=args.iterations,
        max_events_per_drop=args.max_events_per_drop,
        seed=args.seed,
        initial_temperature=args.initial_temperature,
        final_temperature=args.final_temperature,
    )

    pseudo_ipd_path = args.output_dir / f"{args.prefix}_pseudo_ipd.csv"
    cleaning_path = args.output_dir / f"{args.prefix}_event_drop_cleaning.csv"
    report_path = args.output_dir / f"{args.prefix}_report.json"

    write_csv(pseudo_ipd_path, ipd, ["id", "arm", "time", "status"])
    write_csv(
        cleaning_path,
        cleaning_table,
        [
            "drop_id",
            "interval",
            "time_months",
            "raw_target_survival",
            "raw_drop",
            "allocated_events",
            "censors_before_drop",
            "reconstructed_survival_after_drop",
            "survival_error",
            "cleaning_action",
        ],
    )

    report: dict[str, Any] = {
        "arm": args.arm,
        "segments": str(args.segments),
        "nar_json": str(args.nar_json),
        "min_drop": args.min_drop,
        "iterations": args.iterations,
        "max_events_per_drop": args.max_events_per_drop,
        "seed": args.seed,
        "rmse_vs_raw_digitised_step": score,
        "n": len(ipd),
        "events": sum(int(row["status"]) for row in ipd),
        "target_events": target_events,
        "nar_validation": [
            {
                "time_months": t,
                "published_nar": published,
                "reconstructed_nar": sum(1 for row in ipd if float(row["time"]) >= t - 1e-9),
                "difference": sum(1 for row in ipd if float(row["time"]) >= t - 1e-9) - published,
            }
            for t, published in zip(times, nar_values)
        ],
        "events_by_interval": {
            str(i + 1): sum(event_allocation[k] for k in drops_by_interval[i])
            for i in range(len(times) - 1)
        },
        "raw_drops": len(drops),
        "cleaned_event_drops": sum(1 for value in event_allocation if value > 0),
        "outputs": {
            "pseudo_ipd": str(pseudo_ipd_path),
            "event_drop_cleaning": str(cleaning_path),
            "report": str(report_path),
        },
    }

    if args.image and args.summary_json:
        overlay_path = args.output_dir / f"{args.prefix}_overlay.png"
        draw_overlay(
            image_path=args.image,
            summary_json=args.summary_json,
            output_path=overlay_path,
            ipd_rows=ipd,
            colour=parse_colour(args.overlay_colour),
            line_width=args.line_width,
        )
        report["outputs"]["overlay"] = str(overlay_path)

    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
