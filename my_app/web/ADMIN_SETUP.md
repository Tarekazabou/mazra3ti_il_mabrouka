# Admin Panel Setup Guide

## Overview
This is a simple HTML admin panel for managing Mabrouka's farm accounts, vegetation, and measurements.

## Features
1. **Create Account** - Create a new farmer account with email/password authentication
2. **Add Vegetation** - Assign vegetation types (potato, tomato, onion) to a farmer
3. **Add Measurements** - Record farm sensor data (soil moisture, pump status, etc.)

## Firebase Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Name your project (e.g., "mazra3ti-mabrouka")
4. Follow the setup wizard

### Step 2: Enable Authentication
1. In Firebase Console, go to **Authentication**
2. Click "Get Started"
3. Enable **Email/Password** sign-in method

### Step 3: Create Firestore Database
1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location close to your users

### Step 4: Get Firebase Config
1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to "Your apps"
3. Click the web icon `</>`
4. Register your app with a nickname
5. Copy the `firebaseConfig` object

### Step 5: Update admin.html
1. Open `admin.html`
2. Find this section (around line 340):
```javascript
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
};
```
3. Replace with your actual Firebase config values

## Firestore Data Structure

### Collection: `farmers`
Document ID: `{userId}` (from Firebase Auth)
```json
{
  "name": "اسم المزارعة",
  "email": "email@example.com",
  "farmLocation": "موقع المزرعة",
  "farmSize": 5.5,
  "vegetation": ["potato", "tomato"],
  "createdAt": Timestamp,
  "vegetationUpdatedAt": Timestamp
}
```

### Collection: `measurements`
Document ID: `{userId}` (same as farmer ID)
```json
{
  "farmerId": "userId",
  "soilMoisture": "moderate",
  "pumpStatus": "off",
  "tankWater": "half",
  "weatherAlert": "nothing",
  "controlMode": "automatic",
  "valveStatus": "closed",
  "lastUpdated": Timestamp
}
```

### Collection: `measurementHistory`
Document ID: Auto-generated
```json
{
  "farmerId": "userId",
  "soilMoisture": "moderate",
  "pumpStatus": "off",
  "tankWater": "half",
  "weatherAlert": "nothing",
  "controlMode": "automatic",
  "valveStatus": "closed",
  "timestamp": Timestamp
}
```

## How to Use

### 1. Create a New Account
- Fill in farmer name, email, password, location, and farm size
- Click "إنشاء حساب"
- Copy the generated farmer ID (you'll need it for other operations)

### 2. Add Vegetation
- Enter the farmer ID from step 1
- Select one or more vegetation types
- Click "إضافة النباتات"

### 3. Add Measurements
- Enter the farmer ID
- Select values for all measurements
- Click "حفظ القياسات"

## Running the Admin Panel

### Option 1: Simple HTTP Server (Python)
```bash
cd web
python -m http.server 8000
```
Then open: http://localhost:8000/admin.html

### Option 2: Live Server (VS Code Extension)
1. Install "Live Server" extension in VS Code
2. Right-click `admin.html`
3. Select "Open with Live Server"

### Option 3: Direct File
Simply double-click `admin.html` to open in browser (some features may be limited)

## Security Notes

⚠️ **Important for Production:**
1. Change Firestore rules from test mode to production
2. Add proper authentication checks
3. Implement role-based access control
4. Use environment variables for Firebase config
5. Enable HTTPS only

### Example Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only authenticated users can read/write their own data
    match /farmers/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /measurements/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /measurementHistory/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### Issue: "Firebase not defined"
- Make sure you're accessing the page via HTTP/HTTPS (not file://)
- Check browser console for errors

### Issue: "Permission denied"
- Update Firestore security rules to allow writes
- Make sure authentication is enabled

### Issue: "Farmer ID not found"
- Double-check the farmer ID is correct
- Verify the farmer document exists in Firestore

## Next Steps

To integrate this with your Flutter app:
1. Add `cloud_firestore` package to `pubspec.yaml`
2. Add `firebase_auth` package
3. Configure Firebase for Flutter
4. Create a service class to read from Firestore
5. Update your app to display real-time data

## Support

For Firebase documentation: https://firebase.google.com/docs
