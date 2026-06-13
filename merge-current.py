#!/usr/bin/env python3
"""Merge 'current data' (account) and 'current streams' into a single data/ folder.

Reads:
  current data/2026-27/*.json   — monthly account arrays
  current streams/2026/**/*.json — per-event stream files

Writes:
  data/YYYY/MM/DD/{slug}.json   — merged per-event records
"""

import json, os, re

ACCT_DIR = "current data/2026-27"
STREAM_DIR = "current streams/2026"
OUT_DIR = "data"

ALL_RECORDS = {}  # slug -> record dict


def slugify(date_str, name):
    """Produce a slug like 260527-Eugenia-Manojlovic from YYYY-MM-DD and name."""
    yy = date_str[2:4]
    mm = date_str[5:7]
    dd = date_str[8:10]
    clean = re.sub(r"[^A-Za-z0-9 ]", "", name)
    clean = clean.replace(" ", "-")
    clean = re.sub(r"-+", "-", clean).strip("-")
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
    for f in [
        "title", "dacast_id", "stream_url", "recording_url",
        "contact_name", "contact_telephone", "contact_email",
        "recording_text", "tribute_url",
    ]:
        if stream_rec.get(f):
            merged[f] = stream_rec[f]
    # Stream "deceased" -> "name" if missing
    if stream_rec.get("deceased") and not merged.get("name"):
        merged["name"] = stream_rec["deceased"]
    # Stream datetime -> date + time
    dt = stream_rec.get("datetime", "")
    if dt and not merged.get("date"):
        merged["date"] = dt[:10]
    if dt and not merged.get("time") and len(dt) > 10:
        merged["time"] = dt[11:16]


def match_key(acct_row):
    """Return possible match keys for an account row."""
    date = acct_row.get("date", "")
    name = (acct_row.get("name") or "").strip().lower()
    desc = (acct_row.get("description") or "").strip().lower()
    keys = set()
    if date and name:
        keys.add((date, name))
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


# ---- Step 1: Index stream records ----

print("Step 1: Indexing stream records...")
stream_by_slug = {}
stream_by_match = {}
for root, dirs, files in os.walk(STREAM_DIR):
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

# ---- Step 2: Convert account records, merging with streams ----

print("\nStep 2: Converting account records and merging...")
acct_count = 0
matched_count = 0
standalone_count = 0

for root, dirs, files in os.walk(ACCT_DIR):
    for f in sorted(files):
        if not f.endswith(".json"):
            continue
        path = os.path.join(root, f)
        with open(path) as fh:
            rows = json.load(fh)
        for row in rows:
            rec = make_record(row)
            slug = rec["slug"]

            # Try to find a matching stream record
            acct_keys = match_key(row)
            matched_stream = None
            for key in acct_keys:
                if key in stream_by_match:
                    matched_stream = stream_by_match[key]
                    break

            if matched_stream:
                add_stream_fields(matched_stream, rec)
                matched_count += 1
                print(f"  MERGED: {slug} (account + stream)")
            else:
                if slug in stream_by_slug:
                    add_stream_fields(stream_by_slug[slug], rec)
                    matched_count += 1
                    print(f"  MERGED (by slug): {slug}")
                else:
                    standalone_count += 1
                    print(f"  ACCOUNT ONLY: {slug}")

            if slug in ALL_RECORDS:
                print(f"  WARNING: duplicate slug {slug}, skipping")
            ALL_RECORDS[slug] = rec
            acct_count += 1

# ---- Step 3: Add remaining stream-only records ----

for slug, rec in stream_by_slug.items():
    if slug not in ALL_RECORDS:
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

# ---- Step 4: Write per-event files ----

print("\nStep 3: Writing per-event files...")
written = 0
for slug, rec in sorted(ALL_RECORDS.items()):
    date_str = rec.get("date", "")
    if not date_str or date_str == "0000-00-00":
        print(f"  WARNING: no date for {slug}, skipping")
        continue
    year = date_str[:4]
    month = date_str[5:7]
    day = date_str[8:10]
    dest = os.path.join(OUT_DIR, year, month, day)
    os.makedirs(dest, exist_ok=True)
    path = os.path.join(dest, f"{slug}.json")
    with open(path, "w") as fh:
        json.dump(rec, fh, indent=4, ensure_ascii=False)
    written += 1

print(f"  Written {written} records to {OUT_DIR}/")
print("\nDone!")
