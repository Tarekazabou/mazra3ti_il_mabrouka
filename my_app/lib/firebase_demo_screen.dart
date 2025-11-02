import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'farm_model.dart';
import 'measurements_display_widget.dart';
import 'vegetation_display_widget.dart';

/// Example screen showing Firebase data integration
/// This demonstrates how to display all data loaded from Firebase
class FirebaseDemoScreen extends StatefulWidget {
  const FirebaseDemoScreen({super.key});

  @override
  State<FirebaseDemoScreen> createState() => _FirebaseDemoScreenState();
}

class _FirebaseDemoScreenState extends State<FirebaseDemoScreen> {
  final TextEditingController _farmerIdController = TextEditingController();
  bool _isListening = false;

  @override
  void dispose() {
    _farmerIdController.dispose();
    super.dispose();
  }

  void _loadData() {
    final farmerId = _farmerIdController.text.trim();
    if (farmerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال معرف المزارعة')),
      );
      return;
    }

    final model = Provider.of<FarmModel>(context, listen: false);
    
    if (_isListening) {
      // Listen to real-time updates
      model.listenToMeasurements(farmerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تفعيل التحديثات الفورية')),
      );
    } else {
      // Load once
      model.loadFarmerData(farmerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل البيانات...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مزرعة المبروكة'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF00ACC1)],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Farmer ID Input Card
              _buildFarmerIdInput(),
              
              // Farmer Info
              _buildFarmerInfo(),
              
              // Measurements Display
              const MeasurementsDisplayWidget(),
              
              // Vegetation Display
              const VegetationDisplayWidget(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerIdInput() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'معرف المزارعة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _farmerIdController,
              decoration: const InputDecoration(
                hintText: 'أدخل معرف المزارعة من لوحة التحكم',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: _isListening,
                  onChanged: (value) {
                    setState(() {
                      _isListening = value ?? false;
                    });
                  },
                ),
                const Text('تفعيل التحديثات الفورية'),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.download),
              label: Text(_isListening ? 'بدء الاستماع للتحديثات' : 'تحميل البيانات'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: const Color(0xFF00BCD4),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerInfo() {
    return Consumer<FarmModel>(
      builder: (context, model, child) {
        if (model.farmerId == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.teal[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle, size: 32, color: Colors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model.farmerName ?? 'المزارعة',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'معرف: ${model.farmerId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (model.isLoading)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget to show data source information
class DataSourceInfo extends StatelessWidget {
  const DataSourceInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'مصدر البيانات: Firebase Firestore',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDataItem('رطوبة التربة', 'measurements/{farmerId}.soilMoisture'),
            _buildDataItem('الخزان', 'measurements/{farmerId}.tankWater'),
            _buildDataItem('المضخة', 'measurements/{farmerId}.pumpStatus'),
            _buildDataItem('الصمام', 'measurements/{farmerId}.valveStatus'),
            _buildDataItem('الطقس', 'measurements/{farmerId}.weatherAlert'),
            _buildDataItem('النباتات', 'farmers/{farmerId}.vegetation'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_left, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: path,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
