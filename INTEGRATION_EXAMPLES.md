# Integration Examples - Using Frontend with Backend

This file contains practical examples of how to use the integrated frontend-backend system.

## Example 1: Loading Farm Data on App Start

```dart
// In your StatefulWidget's initState or a button press handler

import 'package:provider/provider.dart';
import 'farm_model.dart';

class FarmDashboard extends StatefulWidget {
  @override
  _FarmDashboardState createState() => _FarmDashboardState();
}

class _FarmDashboardState extends State<FarmDashboard> {
  String farmerId = 'mabrouka_id'; // Replace with actual farmer ID from login
  
  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }
  
  Future<void> _loadFarmData() async {
    final farmModel = Provider.of<FarmModel>(context, listen: false);
    
    // Check if backend is available
    bool backendHealthy = await farmModel.checkBackendHealth();
    
    if (backendHealthy) {
      print('✅ Backend is healthy, loading from API...');
      await farmModel.loadFarmStateFromApi(farmerId);
      
      // Also listen to Firebase for real-time updates
      farmModel.listenToMeasurements(farmerId);
    } else {
      print('⚠️ Backend unavailable, using Firebase only...');
      await farmModel.loadFarmerData(farmerId);
      farmModel.listenToMeasurements(farmerId);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<FarmModel>(
      builder: (context, model, child) {
        if (model.isLoading) {
          return CircularProgressIndicator();
        }
        
        return Column(
          children: [
            Text('Farm: ${model.farmerName ?? "Loading..."}'),
            Text('Soil: ${model.getSoilMoistureText()}'),
            Text('Valve: ${model.getValveStatusText()}'),
          ],
        );
      },
    );
  }
}
```

## Example 2: Manual Valve Control

```dart
// Button to open valve

class ValveControlButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final farmModel = Provider.of<FarmModel>(context);
    
    return ElevatedButton(
      onPressed: () async {
        if (farmModel.controlMode == ControlMode.manual) {
          bool success = await farmModel.openValveViaApi(
            'tomato',  // Plant name
            30,        // Duration in minutes
          );
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Valve opened successfully!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Failed to open valve')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('⚠️ Switch to manual mode first')),
          );
        }
      },
      child: Text('Open Valve'),
    );
  }
}

// Button to close valve

class CloseValveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final farmModel = Provider.of<FarmModel>(context);
    
    return ElevatedButton(
      onPressed: () async {
        bool success = await farmModel.closeValveViaApi();
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Valve closed successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed to close valve')),
          );
        }
      },
      child: Text('Close Valve'),
    );
  }
}
```

## Example 3: Toggle AI Automatic Mode

```dart
class AiModeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final farmModel = Provider.of<FarmModel>(context);
    
    return SwitchListTile(
      title: Text('AI Automatic Mode'),
      subtitle: Text(
        farmModel.controlMode == ControlMode.automatic
            ? 'AI will control irrigation automatically'
            : 'Manual control enabled',
      ),
      value: farmModel.controlMode == ControlMode.automatic,
      onChanged: (bool value) async {
        bool success = await farmModel.toggleAiModeViaApi(value);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value 
                  ? '🤖 AI mode enabled' 
                  : '👤 Manual mode enabled'
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed to toggle AI mode')),
          );
        }
      },
    );
  }
}
```

## Example 4: Display Irrigation History

```dart
class IrrigationHistoryScreen extends StatefulWidget {
  @override
  _IrrigationHistoryScreenState createState() => _IrrigationHistoryScreenState();
}

class _IrrigationHistoryScreenState extends State<IrrigationHistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    setState(() => isLoading = true);
    
    final farmModel = Provider.of<FarmModel>(context, listen: false);
    final historyData = await farmModel.getHistoryFromApi(limit: 20);
    
    setState(() {
      history = historyData;
      isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final event = history[index];
        return ListTile(
          leading: Icon(
            event['action'] == 'open' ? Icons.water_drop : Icons.close,
            color: event['action'] == 'open' ? Colors.blue : Colors.grey,
          ),
          title: Text(event['plant_name'] ?? 'Unknown'),
          subtitle: Text(
            '${event['action']} - ${event['duration_minutes'] ?? 0} minutes',
          ),
          trailing: Text(event['timestamp'] ?? ''),
        );
      },
    );
  }
}
```

## Example 5: Request AI Decision

```dart
class RequestAiDecisionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.psychology),
      label: Text('Get AI Recommendation'),
      onPressed: () async {
        final farmModel = Provider.of<FarmModel>(context, listen: false);
        
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Center(child: CircularProgressIndicator()),
        );
        
        final decision = await farmModel.requestAiDecision();
        
        // Hide loading
        Navigator.of(context).pop();
        
        if (decision != null && decision['success'] == true) {
          // Show AI decision in dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('🤖 AI Recommendation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Should Irrigate: ${decision['should_irrigate']}'),
                  SizedBox(height: 8),
                  Text('Confidence: ${decision['confidence']}%'),
                  SizedBox(height: 8),
                  Text('Reason: ${decision['reasoning'] ?? 'N/A'}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed to get AI decision')),
          );
        }
      },
    );
  }
}
```

## Example 6: Complete Dashboard with Backend Integration

```dart
class CompleteFarmDashboard extends StatefulWidget {
  final String farmerId;
  
  const CompleteFarmDashboard({required this.farmerId});
  
  @override
  _CompleteFarmDashboardState createState() => _CompleteFarmDashboardState();
}

class _CompleteFarmDashboardState extends State<CompleteFarmDashboard> {
  bool backendAvailable = false;
  
  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }
  
  Future<void> _initializeDashboard() async {
    final farmModel = Provider.of<FarmModel>(context, listen: false);
    
    // Check backend health
    backendAvailable = await farmModel.checkBackendHealth();
    
    if (backendAvailable) {
      // Load from backend API
      await farmModel.loadFarmStateFromApi(widget.farmerId);
      
      // Set up periodic refresh every 5 minutes
      Timer.periodic(Duration(minutes: 5), (timer) {
        if (mounted) {
          farmModel.loadFarmStateFromApi(widget.farmerId);
        } else {
          timer.cancel();
        }
      });
    }
    
    // Also listen to Firebase for real-time sensor data
    farmModel.listenToMeasurements(widget.farmerId);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مزرعتي'),
        actions: [
          // Backend status indicator
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              backendAvailable ? Icons.cloud_done : Icons.cloud_off,
              color: backendAvailable ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Consumer<FarmModel>(
        builder: (context, model, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Farm Status Card
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          model.farmerName ?? 'Loading...',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Text('Soil: ${model.getSoilMoistureText()}'),
                        Text('Valve: ${model.getValveStatusText()}'),
                        Text('Mode: ${model.getControlModeText()}'),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 16),
                
                // AI Mode Toggle
                AiModeToggle(),
                
                SizedBox(height: 16),
                
                // Valve Controls
                if (model.controlMode == ControlMode.manual) ...[
                  Row(
                    children: [
                      Expanded(child: ValveControlButton()),
                      SizedBox(width: 8),
                      Expanded(child: CloseValveButton()),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
                
                // AI Decision Button
                if (backendAvailable)
                  RequestAiDecisionButton(),
                
                SizedBox(height: 16),
                
                // History Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => IrrigationHistoryScreen(),
                      ),
                    );
                  },
                  child: Text('View History'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Example 7: Error Handling Pattern

```dart
class RobustApiCall extends StatelessWidget {
  Future<void> safeApiCall(BuildContext context) async {
    final farmModel = Provider.of<FarmModel>(context, listen: false);
    
    try {
      // Check backend availability first
      bool isHealthy = await farmModel.checkBackendHealth();
      
      if (!isHealthy) {
        throw Exception('Backend is not available');
      }
      
      // Make API call
      bool success = await farmModel.openValveViaApi('tomato', 30);
      
      if (!success) {
        throw Exception('API call returned unsuccessful result');
      }
      
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Operation successful'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // Error occurred
      print('Error: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => safeApiCall(context),
          ),
        ),
      );
      
      // Optionally, fallback to Firebase
      // await farmModel.loadFarmerData(farmerId);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => safeApiCall(context),
      child: Text('Perform Safe API Call'),
    );
  }
}
```

## Testing Tips

1. **Always check backend health before critical operations**
2. **Use Firebase as fallback when backend is unavailable**
3. **Show loading indicators during API calls**
4. **Provide clear error messages to users**
5. **Implement retry mechanisms for failed operations**
6. **Log errors for debugging**
7. **Test with backend both online and offline**

## Common Patterns

### Pattern 1: Try Backend, Fallback to Firebase
```dart
Future<void> loadData() async {
  bool backendOk = await model.checkBackendHealth();
  if (backendOk) {
    await model.loadFarmStateFromApi(farmerId);
  } else {
    await model.loadFarmerData(farmerId);
  }
}
```

### Pattern 2: Show Loading State
```dart
setState(() => isLoading = true);
try {
  await apiCall();
} finally {
  setState(() => isLoading = false);
}
```

### Pattern 3: User Feedback
```dart
final result = await apiCall();
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(result ? '✅ Success' : '❌ Failed')),
);
```

## Next Steps

1. Implement authentication to get real farmer IDs
2. Add caching to reduce API calls
3. Implement offline mode with queued operations
4. Add real-time updates via WebSocket
5. Implement push notifications for alerts
