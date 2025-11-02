# Firebase Integration Guide for Flutter App

## 📦 What Was Added

### New Files:
1. **`lib/firebase_service.dart`** - Service class for Firebase operations
2. **`lib/firebase_options.dart`** - Firebase configuration
3. Updated **`lib/farm_model.dart`** - Added Firebase data loading
4. Updated **`lib/main.dart`** - Firebase initialization
5. Updated **`pubspec.yaml`** - Added Firebase dependencies

## 🔧 Setup Steps

### Step 1: Install Dependencies

Run this command in your terminal:
```powershell
cd my_app
flutter pub get
```

### Step 2: Configure Firebase

You have two options:

#### Option A: Using FlutterFire CLI (Recommended)
```powershell
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (it will auto-generate firebase_options.dart)
flutterfire configure
```

#### Option B: Manual Configuration
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Add your app for each platform (Web, Android, iOS)
4. Copy the configuration values to `lib/firebase_options.dart`

### Step 3: Configure Firebase for Web

Update `web/index.html` to include Firebase SDK. Add this before the closing `</body>` tag:

```html
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
```

### Step 4: Enable Firestore

1. In Firebase Console, go to **Firestore Database**
2. Create database in test mode
3. Choose a location

### Step 5: Update Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read their own data
    match /farmers/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /measurements/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null;
    }
    
    match /measurementHistory/{document} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 🎯 How to Use in Your App

### Loading Data from Firebase

In `main.dart`, update the FarmModel initialization:

```dart
ChangeNotifierProvider(
  create: (context) {
    final model = FarmModel();
    // Load farmer data once
    model.loadFarmerData('FARMER_ID_HERE');
    
    // OR listen to real-time updates
    model.listenToMeasurements('FARMER_ID_HERE');
    
    return model;
  },
  child: const MyApp(),
),
```

### Accessing Vegetation Data

```dart
// In any widget with access to FarmModel:
final model = Provider.of<FarmModel>(context);

// Get vegetation list
List<String> vegetation = model.vegetation;

// Check if has vegetation
if (model.hasVegetation()) {
  // Display vegetation
  String vegText = model.getVegetationListText();
}

// Get vegetation count
int count = model.getVegetationCount();

// Get icon and color for a vegetation
for (var veg in model.vegetation) {
  IconData icon = model.getVegetationIconForName(veg);
  Color color = model.getVegetationColorForName(veg);
  String name = model.getVegetationDisplayName(veg);
}
```

### Displaying Dynamic Vegetation

Example widget to display vegetation:

```dart
Consumer<FarmModel>(
  builder: (context, model, child) {
    if (model.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (!model.hasVegetation()) {
      return Text('لا يوجد نباتات');
    }
    
    return Wrap(
      spacing: 10,
      children: model.vegetation.map((veg) {
        return Chip(
          avatar: Icon(
            model.getVegetationIconForName(veg),
            color: model.getVegetationColorForName(veg),
          ),
          label: Text(model.getVegetationDisplayName(veg)),
        );
      }).toList(),
    );
  },
)
```

## 📊 Data Flow

### From Admin Panel to Flutter App:

1. **Admin creates account** → Firestore `farmers` collection
2. **Admin adds vegetation** → Updates `vegetation` array in farmer document
3. **Admin adds measurements** → Updates `measurements` document
4. **Flutter app loads data** → `FarmModel.loadFarmerData()` fetches data
5. **Flutter app listens** → `FarmModel.listenToMeasurements()` gets real-time updates

### Real-time Updates:

When you use `listenToMeasurements()`, the app automatically updates when:
- Admin changes measurements in admin panel
- Vegetation is added/updated
- Any farmer data changes

## 🔐 Authentication Flow (Optional)

If you want users to login:

```dart
import 'package:firebase_auth/firebase_auth.dart';

// In your login screen
Future<void> loginUser(String email, String password) async {
  try {
    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: email,
          password: password,
        );
    
    final userId = userCredential.user?.uid;
    if (userId != null) {
      // Load farmer data
      Provider.of<FarmModel>(context, listen: false)
          .loadFarmerData(userId);
    }
  } catch (e) {
    print('Login error: $e');
  }
}
```

## 🧪 Testing

### 1. Test Admin Panel
- Create a farmer account
- Note the farmer ID from the success message
- Add vegetation for that farmer
- Add measurements

### 2. Test Flutter App
- Update `main.dart` with the farmer ID
- Run the app: `flutter run -d chrome` (for web)
- Check that data loads correctly

### 3. Test Real-time Updates
- Use `listenToMeasurements()` in main.dart
- Keep the app running
- Update measurements in admin panel
- Watch the app update automatically

## 🎨 Vegetation Display Features

The FarmModel now supports:

- **Dynamic vegetation loading** from Firebase (not limited to 3 types)
- **Custom vegetation names** in Arabic or English
- **Automatic icon/color mapping** for known types (potato, tomato, onion)
- **Fallback defaults** for unknown vegetation types
- **Real-time updates** when vegetation is added/changed

### Known Vegetation Types:
- `بطاطس` or `potato` → Brown, Eco icon
- `طماطم` or `tomato` → Red, Florist icon  
- `بصل` or `onion` → Purple, Spa icon
- Any other name → Green, Grass icon (default)

## 🚀 Running the App

```powershell
# For web
flutter run -d chrome

# For Android (with device connected)
flutter run -d android

# For iOS (Mac only)
flutter run -d ios
```

## 📱 Example Usage in UI

```dart
// In overview_screen.dart or any screen
Widget _buildVegetationSection() {
  return Consumer<FarmModel>(
    builder: (context, model, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('النباتات المزروعة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          if (model.isLoading)
            CircularProgressIndicator()
          else if (model.hasVegetation())
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: model.vegetation.map((veg) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: model.getVegetationColorForName(veg).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: model.getVegetationColorForName(veg),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        model.getVegetationIconForName(veg),
                        color: model.getVegetationColorForName(veg),
                        size: 20,
                      ),
                      SizedBox(width: 6),
                      Text(
                        model.getVegetationDisplayName(veg),
                        style: TextStyle(
                          color: model.getVegetationColorForName(veg),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text('لا يوجد نباتات مضافة'),
        ],
      );
    },
  );
}
```

## 🐛 Troubleshooting

### Issue: Firebase not initialized
**Solution**: Make sure `Firebase.initializeApp()` is called in `main()` with `await`

### Issue: Data not loading
**Solution**: 
- Check Firebase Console for the farmer ID
- Verify Firestore security rules allow reading
- Check console for error messages

### Issue: Real-time updates not working
**Solution**:
- Make sure you're using `listenToMeasurements()` not `loadFarmerData()`
- Check internet connection
- Verify Firestore rules allow reads

### Issue: Vegetation not showing
**Solution**:
- Check that vegetation array exists in Firestore
- Verify the farmer document has the `vegetation` field
- Use `model.hasVegetation()` to check if data is loaded

## 📚 Next Steps

1. ✅ Set up Firebase project
2. ✅ Configure firebase_options.dart
3. ✅ Run `flutter pub get`
4. ✅ Create a farmer account in admin panel
5. ✅ Add vegetation and measurements
6. ✅ Update main.dart with farmer ID
7. ✅ Test the app
8. 🔜 Add login screen
9. 🔜 Add profile management
10. 🔜 Add historical data charts

## 💡 Tips

- Use `listenToMeasurements()` for real-time dashboard
- Use `loadFarmerData()` for one-time data fetch
- The `_vegetation` list stores any string values from Firebase
- You can add as many vegetation types as needed via admin panel
- The app handles both Arabic and English vegetation names

## 🔗 Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Cloud Firestore Guide](https://firebase.google.com/docs/firestore)
