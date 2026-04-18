import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'login_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;
    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }
    if (pass != confirm) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    // For now, just return to login page after a successful sign-up flow
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        gradientColors: const [
          Color.fromARGB(255, 15, 47, 30),
          Color.fromARGB(255, 16, 44, 18),
          Color.fromARGB(255, 27, 94, 58),
        ],
        particleCount: 30,
        particleColor: Colors.greenAccent,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xB31B3F2B),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: GlassNavBar(
                  title: 'Create Account',
                  titleSize: 26,
                  showNotification: false,
                  padding: EdgeInsets.zero,
                  onBack: () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  children: [
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 20,
                      ),
                      borderRadius: 28,
                      color: Colors.white.withValues(alpha: 0.08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Full Name'),
                          const SizedBox(height: 8),
                          _simpleField(
                            controller: _nameController,
                            hint: 'Your full name',
                          ),
                          const SizedBox(height: 12),
                          _label('Email'),
                          const SizedBox(height: 8),
                          _simpleField(
                            controller: _emailController,
                            hint: 'example@example.com',
                          ),
                          const SizedBox(height: 12),
                          _label('Mobile Number'),
                          const SizedBox(height: 8),
                          _simpleField(
                            controller: _phoneController,
                            hint: '+ 123 456 789',
                          ),
                          const SizedBox(height: 12),
                          _label('Date Of Birth'),
                          const SizedBox(height: 8),
                          _simpleField(
                            controller: _dobController,
                            hint: 'DD / MM / YYYY',
                          ),
                          const SizedBox(height: 12),
                          _label('Password'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _passwordController,
                            hint: '••••••••',
                            obscure: _obscure,
                            suffix: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _label('Confirm Password'),
                          const SizedBox(height: 8),
                          _buildInput(
                            controller: _confirmController,
                            hint: '••••••••',
                            obscure: _obscure,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGreen,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(color: Colors.white54),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Log In',
                              style: TextStyle(
                                color: Color(0xFF6BCB5B),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
  );

  Widget _simpleField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
