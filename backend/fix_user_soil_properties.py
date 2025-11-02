"""
Fix existing Firestore users by adding missing soil_type_encoded field
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from utils.firebase_client import get_db
from firebase_admin import firestore

# Soil type encoding (must match training data)
SOIL_TYPE_ENCODING = {
    'clay': 1,
    'loam': 2,
    'sandy': 3,
    'silty': 4
}

def fix_user_soil_properties(user_id, user_data):
    """Add missing soil_type_encoded field to a user"""
    db = get_db()
    user_ref = db.collection('users').document(user_id)
    
    # Check if soil_properties exists
    if 'soil_properties' not in user_data:
        # Create default soil properties
        soil_properties = {
            'soil_type': 'loam',  # Default
            'soil_type_encoded': 2,
            'soil_compaction': 55.0,
            'slope_degrees': 2.0
        }
        print(f"   Creating new soil_properties with defaults")
        user_ref.update({'soil_properties': soil_properties})
        return True
    
    soil_props = user_data['soil_properties']
    
    # Check if soil_type_encoded is missing
    if 'soil_type_encoded' not in soil_props:
        soil_type = soil_props.get('soil_type', 'loam')
        soil_type_encoded = SOIL_TYPE_ENCODING.get(soil_type, 2)  # Default to loam (2)
        
        # Update with encoded value
        soil_props['soil_type_encoded'] = soil_type_encoded
        user_ref.update({'soil_properties': soil_props})
        print(f"   Added soil_type_encoded = {soil_type_encoded} (for soil_type '{soil_type}')")
        return True
    
    # Check for any other missing fields
    updates_needed = {}
    
    if 'soil_type' not in soil_props:
        updates_needed['soil_properties.soil_type'] = 'loam'
        updates_needed['soil_properties.soil_type_encoded'] = 2
    
    if 'soil_compaction' not in soil_props:
        updates_needed['soil_properties.soil_compaction'] = 55.0
    
    if 'slope_degrees' not in soil_props:
        updates_needed['soil_properties.slope_degrees'] = 2.0
    
    if updates_needed:
        user_ref.update(updates_needed)
        print(f"   Added missing fields: {list(updates_needed.keys())}")
        return True
    
    return False

def fix_all_users():
    """Fix all users in Firestore"""
    print("="*70)
    print("🔧 FIXING USER SOIL PROPERTIES")
    print("="*70)
    print()
    
    db = get_db()
    users_ref = db.collection('users')
    
    fixed_count = 0
    ok_count = 0
    error_count = 0
    
    print("📋 Scanning all users...")
    print()
    
    for doc in users_ref.stream():
        user_id = doc.id
        user_data = doc.to_dict()
        user_name = user_data.get('name', 'Unknown')
        
        print(f"👤 {user_name} ({user_id})")
        
        try:
            was_fixed = fix_user_soil_properties(user_id, user_data)
            if was_fixed:
                print(f"   ✅ Fixed!")
                fixed_count += 1
            else:
                print(f"   ✓ Already OK")
                ok_count += 1
        except Exception as e:
            print(f"   ❌ Error: {e}")
            error_count += 1
        
        print()
    
    print("="*70)
    print("📊 SUMMARY")
    print("="*70)
    print(f"✅ Fixed: {fixed_count}")
    print(f"✓  Already OK: {ok_count}")
    print(f"❌ Errors: {error_count}")
    print()
    
    if fixed_count > 0:
        print("🎉 User profiles updated! The AI decision endpoint should work now.")
    else:
        print("ℹ️  No fixes needed - all profiles are correct.")
    
    print("="*70)

if __name__ == "__main__":
    print()
    print("This script will update all user profiles in Firestore")
    print("to add the missing soil_type_encoded field.")
    print()
    
    response = input("Continue? (yes/no): ")
    
    if response.lower() in ['yes', 'y']:
        fix_all_users()
    else:
        print("❌ Cancelled.")
