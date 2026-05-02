import os
import argparse
import shutil
import json
from pathlib import Path
from datetime import datetime

# ----------------------------------------------------
# Paths and Environment Configuration
# ----------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DIR = BASE_DIR / "raw"
META_DIR = BASE_DIR / "meta"
MAP_FILE = META_DIR / "notebook_map.md"
WATCH_LIST_FILE = META_DIR / "watch_list.json"

def setup():
    """Initialize infrastructure and ensure mapping table layout conforms to HTA Wiki standards."""
    META_DIR.mkdir(exist_ok=True)
    RAW_DIR.mkdir(exist_ok=True)
    if not MAP_FILE.exists():
        with open(MAP_FILE, "w", encoding="utf-8") as f:
            f.write("| Filename | TA Number | Drug | Indication | Compile Date | Status |\n")
            f.write("| :--- | :--- | :--- | :--- | :--- | :--- |\n")
    if not WATCH_LIST_FILE.exists():
        with open(WATCH_LIST_FILE, "w", encoding="utf-8") as f:
            json.dump([], f)

# ----------------------------------------------------
# Core Logic: Incremental Metadata Management
# ----------------------------------------------------
def get_processed_metadata():
    """Retrieve metadata for all processed files by parsing the HTA Mapping Table."""
    setup()
    metadata = {}
    if not MAP_FILE.exists():
        return metadata
    with open(MAP_FILE, "r", encoding="utf-8") as f:
        # Skip header and separator lines
        lines = [l for l in f.readlines() if "|" in l][2:]
        for line in lines:
            parts = [p.strip() for p in line.split("|")]
            # Format: | Filename | TA Number | Drug | Indication | Compile Date | Status |
            # parts[0]="" parts[1]=Filename ... parts[6]=Status parts[7]=""
            if len(parts) >= 7:
                filename = parts[1]
                if not filename:
                    continue
                metadata[filename] = {
                    "ta_number": parts[2],
                    "drug":      parts[3],
                    "condition": parts[4],
                    "date":      parts[5],
                    "status":    parts[6],
                }
    return metadata

def update_map(filename, ta_number="-", drug="-", condition="-", status="Done"):
    """
    Update the mapping table.
    Usage (invoked by Agent after ingestion):
        python3 scripts/compile_wiki.py --log TA938_Pembrolizumab.md \
            --ta TA938 --drug Pembrolizumab --condition "Cervical Cancer"
    """
    setup()
    old_metadata = get_processed_metadata()

    # Protection logic: Inherit old values if new inputs are defaults ("-")
    if filename in old_metadata:
        if ta_number  == "-" and old_metadata[filename]["ta_number"]  != "-":
            ta_number  = old_metadata[filename]["ta_number"]
        if drug       == "-" and old_metadata[filename]["drug"]       != "-":
            drug       = old_metadata[filename]["drug"]
        if condition  == "-" and old_metadata[filename]["condition"]  != "-":
            condition  = old_metadata[filename]["condition"]

    date_str = datetime.now().strftime("%Y-%m-%d")
    new_row = f"| {filename} | {ta_number} | {drug} | {condition} | {date_str} | {status} |\n"

    lines = []
    if MAP_FILE.exists():
        with open(MAP_FILE, "r", encoding="utf-8") as f:
            lines = f.readlines()

    new_lines = []
    found = False
    for line in lines:
        if "|" in line:
            parts = line.split("|")
            if len(parts) > 1 and parts[1].strip() == filename:
                new_lines.append(new_row)
                found = True
                continue
        new_lines.append(line)

    if not found:
        new_lines.append(new_row)

    with open(MAP_FILE, "w", encoding="utf-8") as f:
        f.writelines(new_lines)
    print(f"🎯 Mapping synchronized: {filename} ({ta_number} | {drug} | {condition})")

# ----------------------------------------------------
# Import Function: Copy MD files from external paths to /raw
# ----------------------------------------------------
def is_file_identical(src, dst):
    if not dst.exists():
        return False
    return os.path.getsize(src) == os.path.getsize(dst)

def import_single_file(src_path):
    src = Path(src_path)
    if not src.exists():
        return False
    if src.suffix.lower() != ".md":
        print(f"⏩  Skipping non-MD file: {src.name}")
        return False
    target = RAW_DIR / src.name
    if is_file_identical(src, target):
        print(f"⏩  File unchanged, skipping: {src.name}")
        return False
    shutil.copy2(src, target)
    print(f"✅  Imported successfully: {src.name}")
    return True

def handle_ingestion(path_str, list_only=False, filter_str=None):
    setup()
    dirs = []
    if not path_str:
        if WATCH_LIST_FILE.exists():
            with open(WATCH_LIST_FILE, "r", encoding="utf-8") as f:
                dirs = json.load(f)
    else:
        dirs = [path_str]

    for d in dirs:
        p = Path(d)
        if not p.exists():
            print(f"⚠️  Path does not exist: {d}")
            continue
        if p.is_file():
            import_single_file(p)
            continue

        print(f"📂 Scanning external directory: {d}")
        found = []
        for entry in p.glob("*.md"):
            if filter_str and filter_str.lower() not in entry.name.lower():
                continue
            found.append(entry)

        if list_only:
            for f in found:
                print(f"  - {f.name}")
        else:
            for f in found:
                import_single_file(f)

# ----------------------------------------------------
# Main Workflow: Scan /raw, report new files and incremental updates
# ----------------------------------------------------
def run_main_workflow():
    setup()
    metadata = get_processed_metadata()
    files = sorted(RAW_DIR.glob("*.md"))

    has_tasks = False
    for f in files:
        if f.name not in metadata:
            has_tasks = True
            print(f"\n✨ [New File Pending]: {f.name}")
            print(f"  - Suggestion: Run Ingest to split this file into 4 Wiki nodes.")
        else:
            current_mtime = f.stat().st_mtime
            # Coarse date comparison for updates
            recorded_date = metadata[f.name]["date"]
            file_date = datetime.fromtimestamp(current_mtime).strftime("%Y-%m-%d")
            if file_date > recorded_date:
                has_tasks = True
                print(f"\n🔄 [Incremental Update Detected]: {f.name}")
                print(f"  - Last Compiled: {recorded_date}, File Modified: {file_date}")
                print(f"  - Suggestion: Append updates to corresponding Wiki nodes per RULES.md Section 8.")

    if not has_tasks:
        print("🌱 [HTA Intelligence Hub] Scan complete. All files in /raw are synchronized.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="NICE HTA Wiki Compile Engine V2.0")
    parser.add_argument("--import", dest="path", help="Import MD files from external paths to /raw")
    parser.add_argument("--list",   action="store_true", help="Preview mode, no actual import")
    parser.add_argument("--filter", help="Filter filenames by keyword")
    parser.add_argument("--log",    help="Synchronize mapping table: input filename")
    parser.add_argument("--ta",        default="-", help="TA number, e.g., TA938")
    parser.add_argument("--drug",      default="-", help="Drug name, e.g., Pembrolizumab")
    parser.add_argument("--condition", default="-", help="Indication, e.g., Cervical Cancer")
    parser.add_argument("--status",    default="Done", help="Status: Done / Partial / Pending")

    args = parser.parse_args()

    if args.log:
        update_map(args.log, args.ta, args.drug, args.condition, args.status)
    elif args.path or args.list:
        handle_ingestion(args.path, args.list, args.filter)
    else:
        run_main_workflow()
