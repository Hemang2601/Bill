import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';
import 'app_button.dart';
import 'app_dialog.dart';
import 'fade_slide_page_route.dart';
import '../../login_page.dart';
import '../../create_invoice.dart';
import '../../history_page.dart';

/// Professional Side Navigation Drawer with collapsible Manager Profile Accordion
class AppNavigationDrawer extends StatefulWidget {
  final String? currentRoute;
  final String? managerName;
  final VoidCallback? onRefreshParent;

  const AppNavigationDrawer({
    super.key,
    this.currentRoute,
    this.managerName,
    this.onRefreshParent,
  });

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  String _activeManager = "Suresh";
  bool _isProfileExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadManager();
  }

  Future<void> _loadManager() async {
    if (widget.managerName != null && widget.managerName!.isNotEmpty) {
      if (mounted) setState(() => _activeManager = widget.managerName!);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('userName') ?? "Suresh";
    if (mounted) setState(() => _activeManager = stored);
  }

  String _formatFullName(String name) {
    if (name.isEmpty) return "Suresh Lakhadiya";
    final capitalized = name
        .split(' ')
        .map((str) {
          if (str.isEmpty) return "";
          return str[0].toUpperCase() + str.substring(1).toLowerCase();
        })
        .join(' ');

    if (!capitalized.toLowerCase().contains("lakhadiya")) {
      return "$capitalized Lakhadiya".trim();
    }
    return capitalized;
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pop(); // Close drawer
    Navigator.of(context).push(FadeSlidePageRoute(page: page)).then((_) {
      widget.onRefreshParent?.call();
    });
  }

  void _handleSignOut() async {
    final bool? confirmed = await AppDialog.showLogoutConfirmation(
      context: context,
      userName: _formatFullName(_activeManager),
    );

    if (confirmed == true && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userName');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeSlidePageRoute(page: const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showAboutDialog() {
    Navigator.of(context).pop(); // Close drawer
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.electric_bolt_rounded,
                color: AppColors.amberLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text("About Software", style: AppTypography.headingSmall),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SHREE SHAKTI ELECTRIC",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Commercial Electrical Billing & Management Suite",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const Divider(height: 24),
            _aboutRow("App Version", "v3.0.0 (Premium White)"),
            _aboutRow("Database", "SQLite Local (Offline)"),
            _aboutRow("Active Manager", _formatFullName(_activeManager)),
            _aboutRow("Device Platform", "Mobile & Desktop Ready"),
          ],
        ),
        actions: [
          AppButton(
            label: "CLOSE",
            variant: AppButtonVariant.primary,
            size: AppButtonSize.small,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = _formatFullName(_activeManager);
    final String initial = fullName.isNotEmpty
        ? fullName[0].toUpperCase()
        : "M";
    final bool isHiren = _activeManager.toLowerCase().contains("hiren");
    final String sigAsset = isHiren
        ? 'assets/images/hiren.png'
        : 'assets/images/suresh.png';

    return Drawer(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      child: SafeArea(
        child: Column(
          children: [
            // 1. Drawer Header
            _buildDrawerHeader(fullName),

            const Divider(height: 1, color: AppColors.border),

            // 2. Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 6.0,
                    ),
                    child: Text(
                      "APPLICATION NAVIGATION",
                      style: AppTypography.labelCaps.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.dashboard_rounded,
                    label: "Dashboard",
                    subtitle: "Overview, metrics & quick actions",
                    isActive: widget.currentRoute == '/dashboard',
                    onTap: () {
                      Navigator.of(context).pop();
                      if (widget.currentRoute != '/dashboard') {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.post_add_rounded,
                    label: "Create New Bill",
                    subtitle: "Fast 3-step invoice wizard",
                    isActive: widget.currentRoute == '/create-bill',
                    highlightBadge: "WIZARD",
                    onTap: () => _navigateTo(const CreateInvoicePage()),
                  ),
                  _buildDrawerNavItem(
                    icon: Icons.receipt_long_rounded,
                    label: "Invoice History",
                    subtitle: "Search, filter & export PDF records",
                    isActive: widget.currentRoute == '/history',
                    onTap: () => _navigateTo(const HistoryPage()),
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),
                  _buildDrawerNavItem(
                    icon: Icons.info_outline_rounded,
                    label: "About Application",
                    subtitle: "System info & version details",
                    isActive: false,
                    onTap: _showAboutDialog,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // 3. Manager Profile Accordion (Collapsible)
            _buildProfileAccordion(fullName, initial, sigAsset),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String managerName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.primaryGlow,
            ),
            child: const Center(
              child: Icon(
                Icons.electric_bolt_rounded,
                color: AppColors.amberLight,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SHREE SHAKTI",
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "ELECTRIC SUITE",
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "ONLINE",
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 8,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerNavItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isActive,
    String? highlightBadge,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? AppColors.primary.withAlpha(50)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.labelLarge.copyWith(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (highlightBadge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(60),
                      ),
                    ),
                    child: Text(
                      highlightBadge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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

  Widget _buildProfileAccordion(
    String fullName,
    String initial,
    String sigAsset,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _isProfileExpanded ? AppColors.surfaceSubtle : AppColors.surface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isProfileExpanded = !_isProfileExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Authorized Store Manager",
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isProfileExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProfileExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "AUTHORIZED SIGNATURE ON INVOICES",
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 8.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 36,
                          alignment: Alignment.centerLeft,
                          child: Image.asset(sigAsset, fit: BoxFit.contain),
                        ),
                        const Divider(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Authenticated Manager Session",
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppButton(
                    label: "SIGN OUT",
                    icon: Icons.logout_rounded,
                    variant: AppButtonVariant.danger,
                    size: AppButtonSize.small,
                    isFullWidth: true,
                    onPressed: _handleSignOut,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
