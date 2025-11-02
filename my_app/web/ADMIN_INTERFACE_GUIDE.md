# 🌾 Admin Interface Guide - Mazra3ti il Mabrouka

## 📋 Overview

The admin interface (`admin.html`) is a web-based dashboard for managing the WiEmpower Smart Irrigation System. It connects directly to your Flask backend API to manage farmers, plants, and system configuration.

---

## 🚀 Setup Instructions

### 1. **Ensure Backend is Running**

```bash
cd backend
python app.py
```

Backend should be running on: `http://localhost:5000`

### 2. **Open Admin Interface**

Simply open `admin.html` in your web browser:
- **Chrome/Edge**: Just double-click the file, or
- **From VS Code**: Right-click → "Open with Live Server"

---

## 🔗 Backend API Integration

The admin interface connects to these backend endpoints:

### **User Management**
- `POST /api/admin/users` - Create new farmer account
- `GET /api/admin/users` - List all farmers
- `PUT /api/admin/users/<user_id>` - Update farmer details
- `DELETE /api/admin/users/<user_id>` - Delete farmer

### **Plant Management**
- `POST /api/admin/users/<user_id>/plants` - Add plant to farmer
- `DELETE /api/admin/users/<user_id>/plants/<plant_name>` - Remove plant

### **Statistics**
- `GET /api/admin/stats` - System statistics (total users, plants, etc.)

---

## 📊 Features

### 1. **System Statistics Dashboard**
- Real-time overview of the system
- Shows:
  - Total number of farmers
  - Active AI-enabled users
  - Total plants across all farms

### 2. **Users List**
- View all registered farmers
- See their location, plant count, and AI mode status
- Displays user IDs (needed for other operations)

### 3. **Create Farmer Account**
Fill in:
- **Name**: Farmer's name (e.g., "Mabrouka")
- **Email**: Email address (for identification)
- **Password**: Not used in current backend, but can be added later
- **Location**: Farm location (e.g., "Zaghouan")
- **Farm Size**: In hectares

**Output**: Returns the new `user_id` which is automatically filled in the vegetation form.

### 4. **Add Plants to Farm**
Fill in:
- **Farmer ID**: The user_id from account creation
- **Plant Types**: Comma-separated list (e.g., "tomato, potato, onion")

The backend will:
- Look up plant features from the Tunisia crops database
- Generate features for unknown plants using Gemini AI
- Add each plant with default area (100 sqm)

### 5. **Update Farm Settings**
Fill in:
- **Farmer ID**: The user_id
- **Control Mode**: 
  - Automatic (AI decides irrigation)
  - Manual (farmer controls valve)
- **Valve Status**: Open or Closed

---

## 🎯 Typical Workflow

### **Adding a New Farmer (e.g., Mabrouka)**

1. **Create Account**:
   ```
   Name: Mabrouka
   Email: mabrouka@farm.tn
   Location: Zaghouan
   Farm Size: 2.5
   ```
   → Click "إنشاء حساب"
   → Note the `user_id` displayed (e.g., `mabrouka_1234567`)

2. **Add Plants**:
   ```
   Farmer ID: mabrouka_1234567 (auto-filled)
   Plant Types: tomato, potato, olive
   ```
   → Click "إضافة النباتات"
   → Backend adds all 3 plants with their features

3. **Configure Settings**:
   ```
   Farmer ID: mabrouka_1234567
   Control Mode: Automatic
   Valve Status: Closed
   ```
   → Click "حفظ القياسات"
   → AI mode is now enabled for this farmer

4. **Verify**:
   - Click "تحديث الإحصائيات" to see updated counts
   - Click "تحديث القائمة" to see Mabrouka in the users table

---

## 🔧 Configuration

### **Changing Backend URL**

If your backend is running on a different port or server:

```javascript
// In admin.html, line ~175
const API_BASE_URL = 'http://localhost:5000/api/admin';

// Change to:
const API_BASE_URL = 'http://YOUR_SERVER_IP:5000/api/admin';
```

### **For Production Deployment**

Update the URL to your deployed backend:
```javascript
const API_BASE_URL = 'https://api.yourdomain.com/api/admin';
```

---

## 🧪 Testing

### **Test Backend Connection**

1. Open browser console (F12)
2. Type:
```javascript
fetch('http://localhost:5000/api/admin/stats')
  .then(r => r.json())
  .then(console.log)
```

**Expected Response**:
```json
{
  "success": true,
  "stats": {
    "total_users": 0,
    "active_ai_users": 0,
    "total_plants": 0
  }
}
```

### **Test Create User**

Use the form to create a test user, or use curl:
```bash
curl -X POST http://localhost:5000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User",
    "location": "Tunis",
    "soil_properties": {
      "soil_type": "loam",
      "soil_compaction": 55,
      "slope_degrees": 3.5
    },
    "plants": []
  }'
```

---

## 🐛 Troubleshooting

### **Issue: "خطأ: Failed to fetch"**

**Cause**: Backend is not running or wrong URL

**Solution**:
1. Verify backend is running:
   ```bash
   curl http://localhost:5000/health
   ```
2. Check browser console for CORS errors
3. Ensure `CORS(app)` is enabled in `backend/app.py`

### **Issue: "خطأ: Invalid user_id"**

**Cause**: User doesn't exist in Firebase

**Solution**:
1. Click "تحديث القائمة" to see existing user IDs
2. Copy the exact user_id from the table
3. Use that ID in the forms

### **Issue: Plants not showing up**

**Cause**: Plant features might not be generated

**Solution**:
1. Check backend logs for errors
2. Ensure `.env` file has `GEMINI_API_KEY`
3. Try common Tunisia crops first (tomato, potato, wheat)

---

## 📱 Integration with Mobile App

Once you create a farmer account using the admin interface:

1. **User ID** is stored in Firebase
2. **Mobile app** can load this user by their `user_id`
3. **Farmer** sees their plants, measurements, and AI decisions
4. **Backend API** handles all logic for both admin and farmer

The data flow:
```
Admin Interface (web) → Backend API → Firebase
                                          ↓
Mobile App (Flutter) ← Backend API ← Firebase
```

---

## 🎨 Customization

### **Add More Form Fields**

Edit the HTML form and update the corresponding API call:

```javascript
// Example: Add phone number field
const result = await apiCall('/users', 'POST', {
    email: email,
    name: name,
    location: location,
    phone: document.getElementById('farmerPhone').value, // New field
    soil_properties: { ... },
    plants: []
});
```

### **Change Language**

The interface is in Arabic (RTL). To change to English:

1. Change `<html lang="ar" dir="rtl">` to `<html lang="en" dir="ltr">`
2. Update all button and label text
3. Adjust CSS for left-to-right layout

---

## ✅ Complete Feature List

| Feature | Status | Description |
|---------|--------|-------------|
| **View Statistics** | ✅ | Real-time system stats |
| **List Users** | ✅ | All farmers with details |
| **Create User** | ✅ | Add new farmer account |
| **Add Plants** | ✅ | Assign crops to farmer |
| **Update Settings** | ✅ | AI mode and valve control |
| **Auto-refresh** | ✅ | Loads data on page open |
| **Error Handling** | ✅ | Clear error messages |
| **Success Messages** | ✅ | Confirms actions |

---

## 🚀 Next Steps

1. **Deploy backend** to a cloud server (Heroku, AWS, etc.)
2. **Update API_BASE_URL** in admin.html
3. **Add authentication** (login for admins)
4. **Add more features**:
   - Edit existing users
   - Delete users
   - View irrigation history per farmer
   - Real-time dashboard updates

---

## 📞 Support

For issues or questions:
1. Check backend logs: `backend/app.py` console output
2. Check browser console (F12 → Console tab)
3. Verify Firebase connection in `firebase_client.py`

---

**Built for**: 🇹🇳 Women farmers in Tunisia  
**Powered by**: Flask + Firebase + Gemini AI  
**Interface**: HTML + JavaScript (Vanilla)
