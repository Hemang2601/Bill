import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'dashboard_page.dart';

// --- 1. BOOT GATE ---
class AuthGate extends StatelessWidget
{
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context)
{
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkAuthStatus(),
 builder: (context, snapshot)
{
if (snapshot.connectionState == ConnectionState.waiting)
{
          return const Scaffold(
            backgroundColor: Colors.white,
 body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
 children: [
                  SizedBox(
                    width: 30, height: 30,
 child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
 strokeWidth: 2,
                    ),
                  ),
 SizedBox(height: 20),
 Text(
                    "SECURE ACCESS",
 style: TextStyle(
                      color: Color(0xFF94A3B8),
 letterSpacing: 3,
 fontSize: 10,
 fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bool isLoggedIn = snapshot.data?['isLoggedIn'] ?? false;
        final String userName = snapshot.data?['userName'] ?? "";

        return isLoggedIn ? DashboardPage(userName: userName) : const LoginPage();
      },
    );
  }

  Future<Map<String, dynamic>> _checkAuthStatus() async
{
    final prefs = await SharedPreferences.getInstance();
    return
{
      'isLoggedIn': prefs.getBool('isLoggedIn') ?? false,
      'userName': prefs.getString('userName') ?? "",

};
  }
}

// --- 2. LOGIN PAGE (Fixed Non-Scroll Edition) ---
class LoginPage extends StatefulWidget
{
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin
{
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isObscured = true;
  bool _isAuthenticating = false;

  @override
  void dispose()
{
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _handleLogin() async
{
if (!_formKey.currentState!.validate()) return;
    setState(() => _isAuthenticating = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    bool isValid = await DatabaseHelper.instance.validateLogin(
      _userController.text,
 _passController.text,
    );

if (isValid)
{
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _userController.text);
      _showSuccessDialog();
    }
else
{
      setState(() => _isAuthenticating = false);
      _showErrorDialog("ACCESS DENIED", "Credentials do not match our secure records.");
    }
  }

  @override
  Widget build(BuildContext context)
{
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      // CRITICAL: This stops the screen from resizing or scrolling when the keyboard appears
      resizeToAvoidBottomInset: false,
 backgroundColor: const Color(0xFFF8FAFC),
 body: Stack(
        children: [
          // Background Decorative Orbs
          Positioned(top: -150, right: -100, child: _buildOrb(350, const Color(0xFFE0E7FF))),
 Positioned(bottom: -100, left: -50, child: _buildOrb(300, const Color(0xFFF0FDF4))),

 SafeArea(
            child: Center( // Keeps everything centered without scrolling
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
 child: Form(
                  key: _formKey,
 child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Center items vertically
 children: [
                      _buildLogo(),
 const SizedBox(height: 40),
 const Text(
                        "SHREE SHAKTI",
 style: TextStyle(
                          fontSize: 36,
 fontWeight: FontWeight.w900,
 color: Color(0xFF0F172A),
 letterSpacing: -1.2,
                        ),
                      ),
 const Text(
                        "ELECTRIC SERVICES • ADMIN",
 style: TextStyle(
                          fontSize: 11,
 color: Color(0xFF6366F1),
 letterSpacing: 2,
 fontWeight: FontWeight.w900,
                        ),
                      ),
 const SizedBox(height: 60),

 _buildWhiteInput(
                        controller: _userController,
 label: "MANAGER IDENTITY",
 icon: Icons.person_2_outlined,
                      ),
 const SizedBox(height: 20),
 _buildWhiteInput(
                        controller: _passController,
 label: "SECURITY PIN",
 icon: Icons.lock_open_rounded,
 isPassword: true,
                      ),
 const SizedBox(height: 45),
 _buildActionButton(),
 const SizedBox(height: 40),
 const Text(
                        "SECURED BY VAULT v4.0",
 style: TextStyle(
                          color: Color(0xFF94A3B8),
 fontSize: 10,
 fontWeight: FontWeight.w700,
 letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color)
{
    return Container(
      width: size,
 height: size,
 decoration: BoxDecoration(
        shape: BoxShape.circle,
 color: color,
      ),
 child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
 child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildLogo()
{
    return Container(
      padding: const EdgeInsets.all(22),
 decoration: BoxDecoration(
        color: Colors.white,
 shape: BoxShape.circle,
 boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
 blurRadius: 40,
 offset: const Offset(0, 20),
          ),
        ],
      ),
 child: const Icon(Icons.bolt_rounded, size: 55, color: Color(0xFFFBBF24)),
    );
  }

  Widget _buildWhiteInput({
    required TextEditingController controller,
 required String label,
 required IconData icon,
 bool isPassword = false,
  })
{
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
 borderRadius: BorderRadius.circular(20),
 border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
 boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
 blurRadius: 15,
 offset: const Offset(0, 8),
          ),
        ],
      ),
 child: TextFormField(
        controller: controller,
 obscureText: isPassword ? _isObscured : false,
 validator: (val) => val!.isEmpty ? "Required" : null,
 style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
 decoration: InputDecoration(
          labelText: label,
 labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800),
 prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
 suffixIcon: isPassword ? IconButton(
            icon: Icon(_isObscured ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.grey, size: 18),
 onPressed: () => setState(() => _isObscured = !_isObscured),
          ) : null,
 border: InputBorder.none,
 contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton()
{
    return Container(
      width: double.infinity,
 height: 65,
 decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
 color: const Color(0xFF0F172A),
 boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
 blurRadius: 25,
 offset: const Offset(0, 12),
          ),
        ],
      ),
 child: ElevatedButton(
        onPressed: _isAuthenticating ? null : _handleLogin,
 style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
 shadowColor: Colors.transparent,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
 child: _isAuthenticating
? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
: const Text(
          "ACCESS TERMINAL",
 style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
      ),
    );
  }

  void _showSuccessDialog()
{
    showGeneralDialog(
      context: context,
 barrierDismissible: false,
 transitionDuration: const Duration(milliseconds: 400),
 pageBuilder: (ctx, a1, a2) => const SizedBox(),
 transitionBuilder: (ctx, a1, a2, child)
{
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
 child: ScaleTransition(
            scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
 child: AlertDialog(
              backgroundColor: Colors.white,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
 content: Column(
                mainAxisSize: MainAxisSize.min,
 children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 80),
 const SizedBox(height: 20),
 const Text("WELCOME BACK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
 const SizedBox(height: 10),
 const Text("Authentication verified successfully.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
 const SizedBox(height: 30),
 const LinearProgressIndicator(color: Color(0xFF10B981), backgroundColor: Color(0xFFF1F5F9)),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1800), ()
{
if (mounted)
{
        Navigator.pop(context);
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
 pageBuilder: (c, a, sa) => DashboardPage(userName: _userController.text),
 transitionsBuilder: (c, a, sa, child) => FadeTransition(opacity: a, child: child),
          ),
        );
      }
    }
);
  }

  void _showErrorDialog(String title, String message)
{
    showDialog(
      context: context,
 builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
 title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444), fontSize: 16)),
 content: Text(message, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
 actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
 child: const Text("TRY AGAIN", style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
