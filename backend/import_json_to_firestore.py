"""
Import JSON Data to Firestore
Reads the generated JSON files and imports them to Firestore collections
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import json
from utils.firebase_client import get_db

def import_collection(collection_name, json_file_path):
    """Import a collection from JSON file to Firestore"""
    db = get_db()
    
    print(f"\n📥 Importing {collection_name} collection...")
    
    try:
        with open(json_file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        count = 0
        for doc_id, doc_data in data.items():
            db.collection(collection_name).document(doc_id).set(doc_data)
            print(f"  ✓ Imported: {doc_id}")
            count += 1
        
        print(f"✅ Successfully imported {count} documents to {collection_name}")
        return count
        
    except Exception as e:
        print(f"❌ Error importing {collection_name}: {e}")
        import traceback
        traceback.print_exc()
        return 0

def import_all_data():
    """Import all collections from JSON files to Firestore"""
    print()
    print("="*70)
    print("🔥 FIRESTORE DATA IMPORT")
    print("   Importing from JSON files to Firestore")
    print("="*70)
    print()
    
    base_path = os.path.join(os.path.dirname(__file__), 'firestore_data')
    
    # Check if files exist
    files = {
        'users': os.path.join(base_path, 'users_collection.json'),
        'farmers': os.path.join(base_path, 'farmers_collection.json'),
        'measurements': os.path.join(base_path, 'measurements_collection.json'),
    }
    
    for collection_name, file_path in files.items():
        if not os.path.exists(file_path):
            print(f"❌ File not found: {file_path}")
            print(f"   Please run 'python3 generate_firestore_data.py' first")
            return False
    
    # Import each collection
    total_imported = 0
    
    total_imported += import_collection('users', files['users'])
    total_imported += import_collection('farmers', files['farmers'])
    total_imported += import_collection('measurements', files['measurements'])
    
    print()
    print("="*70)
    print(f"✅ IMPORT COMPLETE!")
    print(f"   Total documents imported: {total_imported}")
    print()
    print("📊 Collections created:")
    print("   - users (Backend API)")
    print("   - farmers (Flutter app)")
    print("   - measurements (Flutter app)")
    print()
    print("🎉 Your Firestore database is now populated!")
    print("   You can now run the Flutter app and select any farmer.")
    print("="*70)
    print()
    
    return True

if __name__ == "__main__":
    print()
    print("🇹🇳 Tunisia Women Farmers - Firestore Data Import")
    print()
    
    # Confirm before proceeding
    response = input("This will import data from JSON files to Firestore. Continue? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        success = import_all_data()
        if not success:
            print("❌ Import failed. Please check the errors above.")
            sys.exit(1)
    else:
        print("❌ Cancelled.")
