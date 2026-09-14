import os
import requests
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGO_URI = os.getenv("MONGO_URI")
OFF_BASE = "https://world.openfoodfacts.org/api/v0/product/{}.json"

client = MongoClient(MONGO_URI)
db = client.get_database("fooddb")
collection = db.get_collection("product_variants")


def fetch_off(barcode):
    try:
        url = OFF_BASE.format(barcode.strip())
        res = requests.get(url, timeout=15)
        data = res.json()

        if data.get("status") != 1:
            return None

        product = data.get("product", {})
        nutriments = product.get("nutriments", {})

        return {
            "sodium": nutriments.get("sodium_100g"),
            "nutriscore_raw": nutriments.get("nutrition-score-fr_100g"),
            "ingredients_text": product.get("ingredients_text"),
        }

    except Exception as e:
        print(f"❌ Error fetching OFF for {barcode}: {e}")
        return None


def update_variant(doc):
    barcode = doc.get("barcodes", [None])[0]
    if not barcode:
        return

    print(f"🔍 Fetching OFF data for {barcode}")

    off_data = fetch_off(barcode)
    if not off_data:
        print(f"⚠️ No OFF data for {barcode}")
        return

    update_fields = {}

    if off_data["sodium"] is not None:
        update_fields["nutriments.sodium_g_100g"] = off_data["sodium"]

    if off_data["nutriscore_raw"] is not None:
        update_fields["nutriscore_score_raw"] = off_data["nutriscore_raw"]

    if off_data["ingredients_text"]:
        update_fields["ingredients_text"] = off_data["ingredients_text"]

    if update_fields:
        collection.update_one(
            {"_id": doc["_id"]},
            {"$set": update_fields}
        )
        print(f"✅ Updated {barcode}")
    else:
        print(f"⚠️ Nothing to update for {barcode}")


def main():
    print("🚀 Starting OFF sync...\n")

    docs = list(collection.find({
        "nutriscore_score_raw": None
    }))

    print(f"Found {len(docs)} documents to update\n")

    for doc in docs:
        update_variant(doc)

    print("\n🎉 Sync complete.")


if __name__ == "__main__":
    main()