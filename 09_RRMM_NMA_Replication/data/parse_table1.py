"""Parse Table 1 of van Beurden-Tan 2022 (BMC Cancer 22:591) into arm-level rows.

Source: PMC9150316_fulltext.html. The HTML is used rather than the XML because
each Table 1 cell holds one <p> per arm; the XML concatenates them, so "5" and
"41" become "541" with no way to recover the split.

Writes rrmm_table1_arms.csv and asserts CR + PR + <PR == N itt on every arm.
"""
import csv
import html
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SRC = HERE.parent / "_LOCAL_source_paper" / "PMC9150316_fulltext.html"
OUT = HERE / "rrmm_table1_arms.csv"

# Column order in Table 1.
COLS = ["trial", "treatment", "median_age", "prior_lines",
        "n_itt", "cr_group", "pr_group", "lt_pr_group", "duration"]


def cell_paragraphs(cell_html):
    """Return one string per <p> in a cell, tags stripped. Cells with no <p>
    (the Duration column) return a single string."""
    paras = re.findall(r"<p[^>]*>(.*?)</p>", cell_html, re.S)
    if not paras:
        paras = [cell_html]
    out = []
    for p in paras:
        text = re.sub(r"<[^>]+>", "", p)
        out.append(html.unescape(text).replace(" ", " ").strip())
    return out


def main():
    doc = SRC.read_text(encoding="utf-8")
    start = doc.find("<table")
    table = doc[start:doc.find("</table>", start)]
    body = table[table.find("<tbody>"):]

    rows = []
    for row_html in re.findall(r"<tr>(.*?)</tr>", body, re.S):
        cells = re.findall(r"<td[^>]*>(.*?)</td>", row_html, re.S)
        if len(cells) != len(COLS):
            sys.exit(f"unexpected column count {len(cells)} in row: {row_html[:120]}")
        parsed = dict(zip(COLS, (cell_paragraphs(c) for c in cells)))

        trial_id = parsed["trial"][0]
        nct = next((p for p in parsed["trial"] if p.startswith("NCT")), "")
        n_arms = len(parsed["treatment"])

        for arm in range(n_arms):
            def get(col):
                vals = parsed[col]
                # ENDEAVOR puts both arms' N itt in one <p> as "465 464".
                # Splitting on whitespace recovers them; the row-sum check below
                # is what confirms the split landed on the right arm.
                if len(vals) == 1 and n_arms > 1 and len(vals[0].split()) == n_arms:
                    vals = vals[0].split()
                # Duration is one value for the whole trial, not per arm.
                return vals[arm] if len(vals) == n_arms else vals[0]
            rows.append({
                "trial": trial_id,
                "nct": nct,
                "arm": arm + 1,
                "treatment": get("treatment"),
                "median_age": get("median_age"),
                "prior_lines": get("prior_lines"),
                "n_itt": int(get("n_itt")),
                "cr_group": int(get("cr_group")),
                "pr_group": int(get("pr_group")),
                "lt_pr_group": int(get("lt_pr_group")),
                "duration": parsed["duration"][0],
            })

    # The self-check: the three response categories are exhaustive, so they must
    # sum to the ITT population. A mis-split cell fails here rather than silently
    # entering the network.
    bad = [r for r in rows
           if r["cr_group"] + r["pr_group"] + r["lt_pr_group"] != r["n_itt"]]

    with OUT.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

    trials = {r["trial"] for r in rows}
    treatments = {r["treatment"] for r in rows}
    print(f"{len(trials)} trials, {len(rows)} arms, {len(treatments)} distinct treatment labels")
    print(f"wrote {OUT.relative_to(HERE.parent)}")
    if bad:
        print(f"\nFAILED row-sum check on {len(bad)} arm(s):")
        for r in bad:
            total = r["cr_group"] + r["pr_group"] + r["lt_pr_group"]
            print(f"  {r['trial']} arm {r['arm']} ({r['treatment']}): "
                  f"{r['cr_group']}+{r['pr_group']}+{r['lt_pr_group']}={total} vs N={r['n_itt']}")
        sys.exit(1)
    print("row-sum check passed on every arm: CR + PR + <PR == N itt")


if __name__ == "__main__":
    main()
