import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'farm_model.dart';

/// Example widget showing how to display vegetation from Firebase
class VegetationDisplayWidget extends StatelessWidget {
  const VegetationDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FarmModel>(
      builder: (context, model, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'النباتات المزروعة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (model.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (model.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (!model.hasVegetation())
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(Icons.grass, size: 48, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'لا يوجد نباتات مضافة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: model.vegetation.map((veg) {
                          return _buildVegetationChip(
                            context,
                            veg,
                            model.getVegetationIconForName(veg),
                            model.getVegetationColorForName(veg),
                            model.getVegetationDisplayName(veg),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'العدد الإجمالي: ${model.getVegetationCount()}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
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

  Widget _buildVegetationChip(
    BuildContext context,
    String veg,
    IconData icon,
    Color color,
    String displayName,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
