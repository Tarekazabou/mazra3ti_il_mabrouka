import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'farm_model.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final TextEditingController _userIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Sample user IDs from the generated users
  final List<Map<String, String>> _sampleUsers = [
    {'id': 'mabrouka_ba7847bb', 'name': 'Mabrouka', 'location': 'Sfax'},
    {'id': 'fatma_b377be09', 'name': 'Fatma', 'location': 'Ariana'},
    {'id': 'aicha_b3e1569a', 'name': 'Aicha', 'location': 'Zaghouan'},
    {'id': 'khadija_7f059615', 'name': 'Khadija', 'location': 'Tunis'},
    {'id': 'zahra_d51105c7', 'name': 'Zahra', 'location': 'Kasserine'},
    {'id': 'amina_e5bd2141', 'name': 'Amina', 'location': 'Gafsa'},
    {'id': 'salma_96dd8449', 'name': 'Salma', 'location': 'Sousse'},
    {'id': 'nadia_6eab7ce8', 'name': 'Nadia', 'location': 'Monastir'},
    {'id': 'leila_bebee866', 'name': 'Leila', 'location': 'Gabès'},
    {'id': 'samira_0e16d40d', 'name': 'Samira', 'location': 'Sfax'},
  ];

  Future<void> _selectUser(String userId, String name) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final model = Provider.of<FarmModel>(context, listen: false);
    
    try {
      // Load farm state from backend API
      await model.loadFarmStateFromApi(userId);
      
      if (mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectCustomUser() async {
    final userId = _userIdController.text.trim();
    
    if (userId.isEmpty) {
      setState(() {
        _errorMessage = 'الرجاء إدخال معرف المستخدم';
      });
      return;
    }

    await _selectUser(userId, 'Custom User');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF00BCD4),
                Color(0xFF4CAF50),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.agriculture_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'مرحباً بك في مزرعتي',
                        style: GoogleFonts.cairo(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر حسابك للمتابعة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // User List
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              // Error message
                              if (_errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red[200]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red[700],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.cairo(
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Sample Users Title
                              Text(
                                'المزارعات المتاحات',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // User Cards
                              ..._sampleUsers.map((user) => _buildUserCard(
                                    user['id']!,
                                    user['name']!,
                                    user['location']!,
                                  )),

                              const SizedBox(height: 32),

                              // Custom User ID Section
                              Text(
                                'أو أدخل معرف مخصص',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _userIdController,
                                      decoration: InputDecoration(
                                        labelText: 'معرف المستخدم',
                                        hintText: 'مثال: mabrouka_ba7847bb',
                                        prefixIcon: const Icon(Icons.person),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      style: GoogleFonts.cairo(),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _selectCustomUser,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00BCD4),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        'تسجيل الدخول',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String userId, String name, String location) {
    return GestureDetector(
      onTap: () => _selectUser(userId, name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF4CAF50)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}
