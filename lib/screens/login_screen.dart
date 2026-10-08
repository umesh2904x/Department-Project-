import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/captcha_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaInputController = TextEditingController();
  String _selectedRole = 'student';
  String _expectedCaptcha = '';
  bool _captchaError = false;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    _captchaInputController.dispose();
    super.dispose();
  }

  void _login(BuildContext context) async {
    if (_emailOrUsernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar(context, 'Please fill all fields', isError: true);
      return;
    }

    // Validate CAPTCHA (case-sensitive)
    if (_captchaInputController.text.trim() != _expectedCaptcha) {
      setState(() => _captchaError = true);
      _showSnackBar(context, 'Incorrect CAPTCHA. Please try again.', isError: true);
      _captchaInputController.clear();
      return;
    }

    setState(() => _captchaError = false);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(
      emailOrUsername: _emailOrUsernameController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (result['success'] == true) {
      if (mounted) {
        final actualRole = authProvider.user?.role ?? _selectedRole;
        if (actualRole == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else if (actualRole == 'teacher') {
          Navigator.of(context).pushReplacementNamed('/teacher');
        } else {
          Navigator.of(context).pushReplacementNamed('/student');
        }
      }
    } else {
      if (mounted) {
        _showSnackBar(context, result['message'] ?? 'Login failed', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.poppins()),
      backgroundColor: isError ? Colors.redAccent : Colors.deepPurple.shade400,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade300,
              Colors.deepPurple.shade200,
              Colors.deepPurple.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header ─────────────────────────────────────────────────
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Icon(Icons.menu_book_rounded, size: 50, color: Colors.deepPurple.shade400),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Computer Science & Engineering',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '(Data Science)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade50,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Timetable & Academic Management Portal',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── Role Selector ──────────────────────────────────────────
                    Text(
                      'Choose Your Role',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _roleButton('student', 'Student', Icons.school)),
                        const SizedBox(width: 8),
                        Expanded(child: _roleButton('teacher', 'Teacher', Icons.assignment_ind)),
                        const SizedBox(width: 8),
                        Expanded(child: _roleButton('admin', 'Admin', Icons.admin_panel_settings)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Form card ──────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomInputField(
                            label: 'Username',
                            hint: 'Enter your hardcoded username',
                            controller: _emailOrUsernameController,
                            keyboardType: TextInputType.text,
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: 20),
                          CustomInputField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            isPassword: true,
                            prefixIcon: Icons.lock,
                          ),
                          const SizedBox(height: 24),

                          // ── CAPTCHA ────────────────────────────────────────
                          CaptchaWidget(
                            onRefreshed: (newText) {
                              _expectedCaptcha = newText;
                              _captchaInputController.clear();
                              if (_captchaError) setState(() => _captchaError = false);
                            },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _captchaInputController,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              letterSpacing: 2,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textCapitalization: TextCapitalization.none,
                            onChanged: (_) {
                              if (_captchaError) setState(() => _captchaError = false);
                            },
                            decoration: InputDecoration(
                              labelText: 'Enter the text above',
                              labelStyle: GoogleFonts.poppins(fontSize: 13),
                              hintText: 'Type exactly as shown',
                              hintStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                              prefixIcon: Icon(
                                Icons.security,
                                color: _captchaError ? Colors.red : Colors.deepPurple.shade400,
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _captchaError ? Colors.red : Colors.grey.shade300,
                                  width: _captchaError ? 2 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _captchaError ? Colors.red : Colors.deepPurple.shade400,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: _captchaError
                                  ? Colors.red.shade50
                                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade50),
                              errorText: _captchaError ? 'CAPTCHA mismatch — enter exactly' : null,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Login button ───────────────────────────────────
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return ElevatedButton(
                                onPressed: authProvider.isLoading ? null : () => _login(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade400,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.login, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Login',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.deepPurple.shade600 : Colors.white,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.deepPurple.shade600 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}