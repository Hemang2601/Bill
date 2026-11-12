import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/core.dart';
import 'database_helper.dart';
import 'dashboard_page.dart';

/// Premium Option D — Mobile Pro Manager Authentication Screen
/// Strictly preserves SQLite credentials (suresh / 1975, hiren / 3112)
/// and SharedPreferences session persistence.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passFocusNode = FocusNode();

  bool _isAuthenticating = false;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _userFocusNode.dispose();
    _passFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _selectManager(String username) {
    HapticFeedback.selectionClick();
    setState(() {
      _usernameController.text = username;
      _errorMessage = null;
    });
    _passFocusNode.requestFocus();
  }

  Future<void> _handleLogin() async {
    // Clear any previous error
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    setState(() => _isAuthenticating = true);

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Validate against SQLite database
      final bool isValid = await DatabaseHelper.instance.validateLogin(
        username,
        password,
      );

      if (!mounted) return;

      if (isValid) {
        // Save session to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', username);

        HapticFeedback.mediumImpact();

        if (!mounted) return;

        // Smooth fade-and-slide navigation into Dashboard
        Navigator.of(context).pushReplacement(
          FadeSlidePageRoute(page: DashboardPage(userName: username)),
        );
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _isAuthenticating = false;
          _errorMessage =
              "Invalid credentials. Please verify your username and PIN.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _errorMessage = "Authentication error. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildBrandingHeader(),
                        AppSpacing.gapVxxl,
                        _buildLoginCard(),
                        AppSpacing.gapVxxl,
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingHeader() {
    return Column(
      children: [
        // Company Emblem with Electric Glow Halo
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [...AppShadows.card, ...AppShadows.primaryGlow],
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.electric_bolt_rounded,
                  color: AppColors.amberLight,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        AppSpacing.gapVm,
        Text(
          "SHREE SHAKTI",
          textAlign: TextAlign.center,
          style: AppTypography.displayMedium.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),
        AppSpacing.gapVxxs,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Text(
            "ELECTRIC SERVICE • BILLING SYSTEM",
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.primaryLight,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    final currentUsername = _usernameController.text.trim().toLowerCase();

    return AppCard(
      padding: const EdgeInsets.all(26.0),
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Manager Sign In",
                        style: AppTypography.headingLarge.copyWith(
                          fontSize: 19,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Select account or enter terminal credentials",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.primaryLight,
                    size: 20,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVl,

            // Quick Manager Select Chips
            Row(
              children: [
                Expanded(
                  child: _buildManagerChip(
                    name: "Suresh",
                    role: "Partner",
                    isSelected: currentUsername == "suresh",
                    onTap: () => _selectManager("suresh"),
                  ),
                ),
                AppSpacing.gapHm,
                Expanded(
                  child: _buildManagerChip(
                    name: "Hiren",
                    role: "Partner",
                    isSelected: currentUsername == "hiren",
                    onTap: () => _selectManager("hiren"),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVl,

            // Error Message Banner (if any)
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: AppRadius.m,
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    AppSpacing.gapHs,
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapVl,
            ],

            // Username Field
            AppTextField(
              controller: _usernameController,
              focusNode: _userFocusNode,
              label: "MANAGER USERNAME",
              hint: "e.g. suresh or hiren",
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.none,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your manager username";
                }
                return null;
              },
            ),
            AppSpacing.gapVl,

            // Password Field
            AppTextField(
              controller: _passwordController,
              focusNode: _passFocusNode,
              label: "SECURITY PIN / PASSWORD",
              hint: "Enter security PIN",
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Please enter your PIN or password";
                }
                return null;
              },
            ),
            AppSpacing.gapVxxl,

            // Submit Button
            AppButton(
              label: "SIGN IN TO TERMINAL",
              icon: Icons.login_rounded,
              isFullWidth: true,
              size: AppButtonSize.large,
              isLoading: _isAuthenticating,
              onPressed: _isAuthenticating ? null : _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerChip({
    required String name,
    required String role,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final String imagePath = name.toLowerCase() == "hiren"
        ? 'assets/images/hiren.png'
        : 'assets/images/suresh.png';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.sm : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2.0 : 1.0,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isSelected
                        ? AppColors.primarySoft
                        : AppColors.surfaceMuted,
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: AppTypography.labelLarge.copyWith(
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    role,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "SECURE OFFLINE VAULT • SQLITE ENFORCED",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelCaps.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.gapVxs,
        Text(
          "Authorized Accounts: Suresh Lakhadiya • Hiren Lakhadiya",
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
