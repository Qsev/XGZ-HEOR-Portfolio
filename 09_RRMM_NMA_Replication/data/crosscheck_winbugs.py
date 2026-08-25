"""Cross-check the parsed Table 1 against the WinBUGS data block in Appendix A.

Table 1 and the WinBUGS data are two independent renderings of the same counts,
so agreeing with the appendix is a stronger check than any internal consistency
rule. The appendix also carries what Table 1 does not: the treatment index each
arm was mapped to, which is where the network's node definitions actually live.

Writes rrmm_treatments.csv (the index -> label map) and reports any disagreement.
"""
import csv
import html
import re
import sys
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
APPENDIX = HERE.parent / "_LOCAL_source_paper" / "AppendixA_WinBUGS_code_init_data.docx"
ARMS = HERE / "rrmm_table1_arms.csv"
OUT = HERE / "rrmm_treatments.csv"

# One WinBUGS data row per study, in the column order the appendix declares.
FIELDS = ["r11", "r12", "r13", "r21", "r22", "r23", "n1", "n2", "tx1", "tx2", "na"]


def appendix_text():
    with zipfile.ZipFile(APPENDIX) as zf:
        xml = zf.read("word/document.xml").decode("utf-8")
    lines = []
    for para in re.findall(r"<w:p[ >].*?</w:p>", xml, re.S):
        text = "".join(re.findall(r"<w:t[^>]*>(.*?)</w:t>", para, re.S))
        lines.append(html.unescape(re.sub(r"<[^>]+>", "", text)).strip())
    return lines


def winbugs_rows(lines):
    """Yield (comment, {field: int}) for each study block in the data section."""
    start = lines.index("# Study - Comparison") + 1
    buf = []
    for line in lines[start:]:
        if line == "END":
            break
        if line.startswith("#"):
            if len(buf) == len(FIELDS):
                yield line, dict(zip(FIELDS, buf))
            else:
                print(f"  skipped {line}: {len(buf)} values, expected {len(FIELDS)}")
            buf = []
        elif line.lstrip("-").isdigit():
            buf.append(int(line))


def main():
    rows = list(winbugs_rows(appendix_text()))

    # The appendix repeats the first study as a trailing row. The two copies are
    # not identical: the docx renders GMY302's first count as "10" once and "0"
    # once. dmulti settles it — only the copy that sums to n could have been the
    # input WinBUGS actually ran.
    def sums_to_n(v):
        return all(v[f"r{a}1"] + v[f"r{a}2"] + v[f"r{a}3"] == v[f"n{a}"] for a in (1, 2))

    by_name = {}
    for comment, vals in rows:
        name = comment.lstrip("# ").split(" - ")[0].strip()
        by_name.setdefault(name, []).append((comment, vals))

    studies = []
    for name, copies in by_name.items():
        if len(copies) > 1:
            valid = [c for c in copies if sums_to_n(c[1])]
            print(f"note: {name} appears {len(copies)}x in the data block; "
                  f"{len(valid)} copy/copies satisfy CR+PR+<PR = n")
            copies = valid or copies
        comment, vals = copies[0]
        studies.append((name, comment, vals))

    print(f"{len(studies)} studies read from the WinBUGS data block\n")

    # dmulti requires the three category counts to sum to n, so a row that fails
    # here cannot be what WinBUGS was actually fed.
    artefacts = []
    for name, _, v in studies:
        for arm in (1, 2):
            total = v[f"r{arm}1"] + v[f"r{arm}2"] + v[f"r{arm}3"]
            if total != v[f"n{arm}"]:
                artefacts.append((name, arm, total, v[f"n{arm}"]))

    table1 = {}
    for r in csv.DictReader(ARMS.open(encoding="utf-8")):
        table1.setdefault(r["trial"], {})[int(r["arm"])] = r

    # Table 1 keys studies by trial ID; the appendix comments use the same IDs.
    mismatches, unmatched = [], []
    tx_labels = {}
    for name, comment, v in studies:
        arms = table1.get(name)
        if arms is None:
            unmatched.append(name)
            continue
        for arm in (1, 2):
            t1 = arms[arm]
            for k, col in ((f"r{arm}1", "cr_group"), (f"r{arm}2", "pr_group"),
                           (f"r{arm}3", "lt_pr_group"), (f"n{arm}", "n_itt")):
                if v[k] != int(t1[col]):
                    mismatches.append((name, arm, col, int(t1[col]), v[k]))
            tx_labels.setdefault(v[f"tx{arm}"], set()).add(t1["treatment"])

    if unmatched:
        print(f"trial IDs in the appendix with no Table 1 row: {unmatched}\n")
    if artefacts:
        print("rows where CR + PR + <PR != n (docx extraction artefact, not data):")
        for name, arm, total, n in artefacts:
            print(f"  {name} arm {arm}: sum {total} vs n {n}")
        print()
    if mismatches:
        print("Table 1 vs WinBUGS data disagreements:")
        for name, arm, col, a, b in mismatches:
            print(f"  {name} arm {arm} {col}: Table 1 {a}, appendix {b}")
        print()
    else:
        print("every count in Table 1 matches the WinBUGS data block\n")

    with OUT.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["tx_index", "table1_labels", "n_labels"])
        for idx in sorted(tx_labels):
            labels = sorted(tx_labels[idx])
            w.writerow([idx, " | ".join(labels), len(labels)])

    print(f"{len(tx_labels)} treatment nodes; wrote {OUT.name}")

    # Re-emit the arm-level data carrying the treatment index, so downstream
    # models read node identity from the appendix rather than from label text.
    label_to_tx = {lab: idx for idx, labs in tx_labels.items() for lab in labs}
    arms = list(csv.DictReader(ARMS.open(encoding="utf-8")))
    for r in arms:
        r["tx_index"] = label_to_tx[r["treatment"]]
    analysis = HERE / "rrmm_arms_indexed.csv"
    with analysis.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(arms[0]))
        w.writeheader()
        w.writerows(arms)
    print(f"wrote {analysis.name} ({len(arms)} arms with tx_index)")
    lumped = {i: sorted(l) for i, l in tx_labels.items() if len(l) > 1}
    if lumped:
        print("\nnodes that pool more than one Table 1 label:")
        for idx, labels in lumped.items():
            print(f"  Tx {idx}: {' + '.join(labels)}")

    if mismatches:
        sys.exit(1)


if __name__ == "__main__":
    main()
