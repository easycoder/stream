#!/usr/bin/env python3
"""Migrate data from account + streams into filming.eclecity.net.

Steps:
1. Copy existing stream records from stream.eclecity.net
2. Convert account monthly JSONs into per-event files
3. Match records by date+name and merge where they overlap
4. Upload merged data to filming.eclecity.net/data/
"""

import json, os, re, sys, subprocess, tempfile, shutil

REMOTE = "eclecity@eclecity.net"
STREAMS_DATA = "/home/eclecity/stream.eclecity.net/data"
FILMING_DATA = "/home/eclecity/filming.eclecity.net/data"
ACCOUNT_DIR = os.path.join(os.path.dirname(__file__), "data")

WORK = tempfile.mkdtemp(prefix="filming-migrate-")
ALL_RECORDS = {}  # slug -> record dict


def slugify(date_str, name):
    """Produce a slug like 260527-Eugenia-Manojlovic from YYYY-MM-DD and name."""
    yy = date_str[2:4]
    mm = date_str[5:7]
    dd = date_str[8:10]
    clean = re.sub(r'[^A-Za-z0-9 ]', '', name)
    clean = clean.replace(' ', '-')
    clean = re.sub(r'-+', '-', clean).strip('-')
    return f"{yy}{mm}{dd}-{clean}"


def make_record(acct_row):
    """Convert an account row into the merged record shape."""
    kind = acct_row.get("kind", "service")

    paid_val = acct_row.get("paid", False)
    if isinstance(paid_val, str) and paid_val:
        paid_bool = True
        paid_date = paid_val
    elif paid_val is True:
        paid_bool = True
        paid_date = ""
    else:
        paid_bool = False
        paid_date = ""

    date_str = acct_row.get("date", "")
    name = acct_row.get("name") or acct_row.get("description", "")
    slug = slugify(date_str, name)

    # Parse time if present (may be HH:MM or already stored)
    time_str = acct_row.get("time", "")

    record = {
        "slug": slug,
        "kind": kind,
        "date": date_str,
        "time": time_str,
        "deceased": name,
        "datetime": f"{date_str}T{time_str}" if time_str else f"{date_str}T00:00",
        "name": name,
        "location": acct_row.get("location", ""),
        "postcode": acct_row.get("postcode", ""),
        "distance": acct_row.get("distance", ""),
        "contact": acct_row.get("contact", ""),
        "client": acct_row.get("client", ""),
        "mileage": int(acct_row.get("mileage", 0) or 0),
        "expense": int(acct_row.get("expense", 0) or 0),
        "fees": int(acct_row.get("fees", 0) or 0),
        "paid": paid_bool,
        "paidDate": paid_date,
        "linkSent": acct_row.get("linkSent", ""),
        "invoiced": acct_row.get("invoiced", ""),
        "link": acct_row.get("link", ""),
        # Stream fields — empty in account-only records
        "title": acct_row.get("title", ""),
        "dacast_id": acct_row.get("dacast_id", ""),
        "stream_url": acct_row.get("stream_url", ""),
        "recording_url": acct_row.get("recording_url", ""),
        "contact_name": acct_row.get("contact_name", ""),
        "contact_telephone": acct_row.get("contact_telephone", ""),
        "contact_email": acct_row.get("contact_email", ""),
        "recording_text": acct_row.get("recording_text", ""),
        "tribute_url": acct_row.get("tribute_url", ""),
    }
    return record


def add_stream_fields(stream_rec, merged):
    """Overlay stream fields onto a merged record."""
    for f in ["title", "dacast_id", "stream_url", "recording_url",
              "contact_name", "contact_telephone", "contact_email",
              "recording_text", "tribute_url"]:
        if stream_rec.get(f):
            merged[f] = stream_rec[f]
    # Stream recording_text has a default we should preserve
    if stream_rec.get("recording_text"):
        merged["recording_text"] = stream_rec["recording_text"]
    # Stream "name" is stored as "deceased"
    if stream_rec.get("deceased") and not merged.get("name"):
        merged["name"] = stream_rec["deceased"]
    # Stream datetime -> date + time
    dt = stream_rec.get("datetime", "")
    if dt and not merged.get("date"):
        merged["date"] = dt[:10]
    if dt and not merged.get("time") and len(dt) > 10:
        merged["time"] = dt[11:16]
    # Stream has no account financial fields — leave those as-is


def match_key(acct_row):
    """Return a set of possible match keys for an account row."""
    date = acct_row.get("date", "")
    name = (acct_row.get("name") or "").strip().lower()
    desc = (acct_row.get("description") or "").strip().lower()
    keys = set()
    if date and name:
        keys.add((date, name))
        # Also try matching on just the surname
        parts = name.split()
        if len(parts) > 1:
            keys.add((date, parts[-1]))
    if date and desc and desc != name:
        keys.add((date, desc))
    return keys


def stream_match_key(stream_rec):
    """Return possible match keys for a stream record."""
    dt = stream_rec.get("datetime", "")
    date = dt[:10] if dt else ""
    deceased = (stream_rec.get("deceased") or "").strip().lower()
    keys = set()
    if date and deceased:
        keys.add((date, deceased))
        parts = deceased.split()
        if len(parts) > 1:
            keys.add((date, parts[-1]))
    return keys


# ---- Main migration ----

print("Step 1: Copying stream records from server...")
stream_dir = os.path.join(WORK, "streams")
os.makedirs(stream_dir)

ssh_proc = subprocess.Popen(
    ["ssh", REMOTE, f"cd {STREAMS_DATA} && tar czf - ."],
    stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
)
tar_proc = subprocess.Popen(
    ["tar", "xzf", "-", "-C", stream_dir],
    stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)
tar_proc.communicate(input=ssh_proc.communicate()[0])

if ssh_proc.returncode == 0:
    print(f"  Copied stream records to {stream_dir}")
else:
    print("  No stream data found or error copying.")

# Index stream records by slug
stream_by_slug = {}
stream_by_match = {}
for root, dirs, files in os.walk(stream_dir):
    for f in files:
        if not f.endswith(".json"):
            continue
        path = os.path.join(root, f)
        with open(path) as fh:
            rec = json.load(fh)
        slug = rec.get("slug")
        if slug:
            stream_by_slug[slug] = rec
            for key in stream_match_key(rec):
                stream_by_match[key] = rec

print(f"  Indexed {len(stream_by_slug)} stream records")


print("\nStep 2: Converting account monthly JSONs to per-event files...")
acct_count = 0
matched_count = 0
standalone_count = 0

# Walk account data: FY/MM.json
for root, dirs, files in os.walk(ACCOUNT_DIR):
    for f in sorted(files):
        if not f.endswith(".json"):
            continue
        path = os.path.join(root, f)
        # Extract FY from relative path
        rel = os.path.relpath(path, ACCOUNT_DIR)
        # e.g. 2026-27/04.json
        fy_dir = os.path.dirname(rel)
        with open(path) as fh:
            rows = json.load(fh)
        for row in rows:
            rec = make_record(row)
            slug = rec["slug"]

            # Check for matching stream record
            acct_keys = match_key(row)
            matched_stream = None
            for key in acct_keys:
                if key in stream_by_match:
                    matched_stream = stream_by_match[key]
                    break

            if matched_stream:
                add_stream_fields(matched_stream, rec)
                matched_count += 1
                print(f"  MERGED: {slug} (account + stream match)")
            else:
                # Also check if slug exists in stream data
                if slug in stream_by_slug:
                    add_stream_fields(stream_by_slug[slug], rec)
                    matched_count += 1
                    print(f"  MERGED (by slug): {slug}")
                else:
                    standalone_count += 1
                    print(f"  ACCOUNT ONLY: {slug}")

            if slug in ALL_RECORDS:
                # Duplicate slug — should not happen, but handle
                print(f"  WARNING: duplicate slug {slug}, skipping")
            ALL_RECORDS[slug] = rec
            acct_count += 1

# Add remaining stream records that had no account match
for slug, rec in stream_by_slug.items():
    if slug not in ALL_RECORDS:
        # Convert streams record to merged shape
        dt = rec.get("datetime") or ""
        merged = {
            "slug": slug,
            "kind": "service",
            "date": dt[:10],
            "time": dt[11:16] if dt else "",
            "deceased": rec.get("deceased", ""),
            "datetime": dt,
            "name": rec.get("deceased", ""),
            "location": rec.get("location", ""),
            "postcode": "",
            "distance": "",
            "contact": rec.get("contact_name", ""),
            "client": "",
            "mileage": 0,
            "expense": 0,
            "fees": 0,
            "paid": False,
            "paidDate": "",
            "linkSent": "",
            "invoiced": "",
            "link": "",
            "title": rec.get("title", ""),
            "dacast_id": rec.get("dacast_id", ""),
            "stream_url": rec.get("stream_url", ""),
            "recording_url": rec.get("recording_url", ""),
            "contact_name": rec.get("contact_name", ""),
            "contact_telephone": rec.get("contact_telephone", ""),
            "contact_email": rec.get("contact_email", ""),
            "recording_text": rec.get("recording_text", ""),
            "tribute_url": rec.get("tribute_url", ""),
        }
        ALL_RECORDS[slug] = merged
        print(f"  STREAM ONLY: {slug}")

print(f"\n  Total account rows: {acct_count}")
print(f"  Matched/merged: {matched_count}")
print(f"  Account-only: {standalone_count}")
print(f"  Stream-only: {len(stream_by_slug) - matched_count}")
print(f"  Total records: {len(ALL_RECORDS)}")


print("\nStep 3: Writing per-event files...")
out_dir = os.path.join(WORK, "merged")
for slug, rec in ALL_RECORDS.items():
    date_str = rec.get("date", "")
    if not date_str or date_str == "0000-00-00":
        print(f"  WARNING: no date for {slug}, skipping")
        continue
    year = date_str[:4]
    month = date_str[5:7]
    day = date_str[8:10]
    dest = os.path.join(out_dir, year, month, day)
    os.makedirs(dest, exist_ok=True)
    path = os.path.join(dest, f"{slug}.json")
    with open(path, "w") as fh:
        json.dump(rec, fh, indent=4, ensure_ascii=False)

print(f"  Written to {out_dir}")


print("\nStep 4: Uploading to filming.eclecity.net...")
# Tar and pipe to server
proc = subprocess.Popen(
    ["ssh", REMOTE, f"mkdir -p {FILMING_DATA} && cd {FILMING_DATA} && tar xzf -"],
    stdin=subprocess.PIPE
)
tar = subprocess.Popen(
    ["tar", "czf", "-", "-C", out_dir, "."],
    stdout=subprocess.PIPE
)
proc.communicate(input=tar.communicate()[0])

if proc.returncode == 0:
    print("  Upload complete!")
else:
    print(f"  Upload failed (exit {proc.returncode})")


# Cleanup
print(f"\nCleaning up {WORK}...")
shutil.rmtree(WORK)

# Verify
print("\nVerifying: fetching booking count from server...")
result = subprocess.run(
    ["ssh", REMOTE, f"find {FILMING_DATA} -name '*.json' | wc -l"],
    capture_output=True, text=True
)
print(f"  Records on server: {result.stdout.strip()}")

print("\nDone!")
