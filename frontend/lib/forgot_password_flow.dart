import 'package:flutter/material.dart';
import 'core (Shared logic, themes, constants)/animated/animated_background.dart';
import 'core (Shared logic, themes, constants)/app_colors.dart';
import 'shared (Global components like buttons, cards)/glass.dart';
import 'shared (Global components like buttons, cards)/nav_bar.dart';
import 'login_page.dart';
import 'create_account_page.dart';

class ForgotPasswordFlow extends StatefulWidget {
  const ForgotPasswordFlow({super.key});

  @override
  State<ForgotPasswordFlow> createState() => _ForgotPasswordFlowState();
}

class _ForgotPasswordFlowState extends State<ForgotPasswordFlow> {
  int step = 0; // 0: request reset, 1: security pin, 2: new password, 3: done

  final _emailController = TextEditingController();
  final _pinControllers = List.generate(6, (_) => TextEditingController());
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _next() => setState(() => step = (step + 1).clamp(0, 3));
  void _prev() => setState(() => step = (step - 1).clamp(0, 3));

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
              // header (glass nav with back button)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xB31B3F2B),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: GlassNavBar(
                  title: _titleForStep(),
                  titleSize: 22,
                  showNotification: false,
                  padding: EdgeInsets.zero,
                  onBack: () {
                    if (step > 0) {
                      _prev();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                ),
              ),
              const SizedBox(height: 18),

              Expanded(child: _buildStep(context)),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForStep() {
    switch (step) {
      case 0:
        return 'Forgot Password';
      case 1:
        return 'Security Pin';
      case 2:
        return 'New Password';
      default:
        return 'Password Changed';
    }
  }

  Widget _buildStep(BuildContext context) {
    switch (step) {
      case 0:
        return _buildRequestReset(context);
      case 1:
        return _buildSecurityPin(context);
      case 2:
        return _buildNewPassword(context);
      default:
        return _buildSuccess(context);
    }
  }

  Widget _card(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      color: Colors.white.withValues(alpha: 0.08),
      child: child,
    ),
  );

  Widget _buildRequestReset(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Reset Password?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email or username.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'example@example.com',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _next(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Next Step',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateAccountPage(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'or sign up with',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'lib/assets/facebook logo.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => const Icon(
                        Icons.facebook,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'lib/assets/google_logo.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        child: const Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
                'Don\'t have an account? ',
                style: TextStyle(color: Colors.white54),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateAccountPage()),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF6BCB5B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityPin(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        const SizedBox(height: 12),
        _card(
          Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Enter Security Pin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => _pinBox(i)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _next(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Send Again',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pinBox(int index) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 6),
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      color: Colors.transparent,
    ),
    alignment: Alignment.center,
    child: TextField(
      controller: _pinControllers[index],
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
      ),
    ),
  );

  Widget _buildNewPassword(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        const SizedBox(height: 12),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'New Password',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Confirm New Password',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '',
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => _next(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Change Password',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      children: [
        const SizedBox(height: 12),
        _card(
          Column(
            children: [
              const SizedBox(height: 12),
              const Icon(
                Icons.check_circle_outline,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'Password Changed!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Password Has Been Changed Successfully.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Back To Login Page',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
