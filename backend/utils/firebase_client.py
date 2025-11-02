"""
Firebase initialization and database reference
Shared across all services
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase (singleton)
_db = None

def get_db():
    """Get Firestore database instance"""
    global _db
    if _db is None:
        # Initialize Firebase if not already done
        if not firebase_admin._apps:
            cred_path = os.path.join(os.path.dirname(__file__), '..', 
                                     'wieempower-b06dc-firebase-adminsdk-fbsvc-ffdf13ae17.json')
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
    return _db
