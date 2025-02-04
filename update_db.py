import sys
from pymongo import MongoClient

# MongoDB connection settings (using port-forwarding)
MONGO_URI = "mongodb://localhost:27017"  # Connecting via kubectl port-forward
DB_NAME = "testing"
COLLECTION_NAME = "ue_profile"

def update_ips(ip_suffixes):
    try:
        # Connect to MongoDB
        client = MongoClient(MONGO_URI)
        db = client[DB_NAME]
        collection = db[COLLECTION_NAME]

        # Fetch all documents sorted by SrcIp
        documents = collection.find().sort("SrcIp", 1)
        docs_list = list(documents)

        if len(docs_list) != len(ip_suffixes):
            print(f"Error: Provided {len(ip_suffixes)} IP suffixes but found {len(docs_list)} documents.")
            sys.exit(1)

        # Update each document with new SrcIp
        for doc, new_suffix in zip(docs_list, ip_suffixes):
            old_ip = doc["SrcIp"]
            new_ip = f"10.42.0.{new_suffix}"

            collection.update_one({"_id": doc["_id"]}, {"$set": {"SrcIp": new_ip}})
            print(f"Updated: {old_ip} -> {new_ip}")

        print("All IPs updated successfully!")

    except Exception as e:
        print(f"Error: {e}")

    finally:
        client.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python update_db.py <suffix1> <suffix2> <suffix3> ...")
        sys.exit(1)

    # Extract IP suffixes from command-line arguments
    ip_suffixes = sys.argv[1:]

    update_ips(ip_suffixes)
