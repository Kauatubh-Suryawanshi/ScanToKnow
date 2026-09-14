#!/usr/bin/env python3
"""
update_additive_source_tag.py

Connects to MongoDB (MONGO_URI must be set in env) and updates ONLY the
`source_tag` field of documents in `fooddb.additives` according to the
numeric `health_rating`.

Mapping:
  85-100 -> "🔵"
  70-84  -> "🟢"
  50-69  -> "🟡"
  30-49  -> "🟠"
  0-29   -> "🔴"

This script performs updates immediately (no dry-run).
"""

import os
import sys
from pymongo import MongoClient
from dotenv import load_dotenv

# Load .env if present
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
if not MONGO_URI:
    print("ERROR: MONGO_URI not set in environment. Set it and re-run.")
    sys.exit(1)

DB_NAME = "fooddb"
COLLECTION_NAME = "additives"

def map_health_to_tag(hr):
    try:
        r = float(hr)
    except Exception:
        return None
    if 85 <= r <= 100:
        return "🔵"
    if 70 <= r <= 84:
        return "🟢"
    if 50 <= r <= 69:
        return "🟡"
    if 30 <= r <= 49:
        return "🟠"
    if 0 <= r <= 29:
        return "🔴"
    return None

def main():
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    coll = db[COLLECTION_NAME]

    # Find documents with a numeric health_rating present
    cursor = coll.find({}, {"health_rating": 1, "source_tag": 1})
    updated = 0
    skipped_no_rating = 0
    skipped_same = 0
    errors = 0

    for doc in cursor:
        _id = doc.get("_id")
        hr = doc.get("health_rating", None)

        new_tag = map_health_to_tag(hr)
        if new_tag is None:
            skipped_no_rating += 1
            continue

        old_tag = doc.get("source_tag", None)
        if old_tag == new_tag:
            skipped_same += 1
            continue

        try:
            res = coll.update_one({"_id": _id}, {"$set": {"source_tag": new_tag}})
            if res.modified_count:
                updated += 1
                print(f"Updated {_id} : {old_tag} -> {new_tag}")
            else:
                # Document matched but not modified (maybe same value or concurrency)
                skipped_same += 1
        except Exception as e:
            print(f"ERROR updating {_id}: {e}")
            errors += 1

    print("\nSummary:")
    print(f"  Updated count      : {updated}")
    print(f"  Skipped (no rating): {skipped_no_rating}")
    print(f"  Skipped (same tag) : {skipped_same}")
    print(f"  Errors             : {errors}")

    client.close()

if __name__ == "__main__":
    main()