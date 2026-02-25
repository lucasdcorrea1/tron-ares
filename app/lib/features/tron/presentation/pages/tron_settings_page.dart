import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

class TronSettingsPage extends StatefulWidget {
  const TronSettingsPage({super.key});

  @override
  State<TronSettingsPage> createState() => _TronSettingsPageState();
}

class _TronSettingsPageState extends State<TronSettingsPage> {
  // Connection settings
  late final TextEditingController _apiUrlController;
  late final TextEditingController _wsUrlController;
  bool _isTestingConnection = false;
  bool? _connectionTestResult;

  // Project settings
  late final TextEditingController _projectNameController;
  late final TextEditingController _projectDescController;
  bool _autoAssign = true;
  bool _autoMerge = false;
  bool _requireCioApproval = true;
  double _maxConcurrentTasks = 3;

  // Agent settings
  bool _pmEnabled = true;
  bool _devEnabled = true;
  bool _qaEnabled = true;

  @override
  void initState() {
    super.initState();
    _apiUrlController =
        TextEditingController(text: 'http://localhost:8080/api');
    _wsUrlController =
        TextEditingController(text: 'ws://localhost:8080/ws');
    _projectNameController = TextEditingController();
    _projectDescController = TextEditingController();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _wsUrlController.dispose();
    _projectNameController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
    });

    // Simulate connection test
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _connectionTestResult = true;
      });
    }
  }

  void _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text(title, style: AppTypography.titleMedium()),
        content: Text(message,
            style: AppTypography.bodyMedium(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style:
                    AppTypography.labelLarge(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: Text('Confirm',
                style: AppTypography.labelLarge(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.titleLarge()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildConnectionSection(),
          const SizedBox(height: AppSpacing.md),
          _buildProjectSection(),
          const SizedBox(height: AppSpacing.md),
          _buildAgentsSection(),
          const SizedBox(height: AppSpacing.md),
          _buildSystemSection(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ==================== Connection Section ====================

  Widget _buildConnectionSection() {
    return _buildSection(
      title: 'Connection',
      icon: Icons.link,
      children: [
        _buildTextField(
          label: 'API URL',
          controller: _apiUrlController,
          hint: 'http://localhost:8080/api',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          label: 'WebSocket URL',
          controller: _wsUrlController,
          hint: 'ws://localhost:8080/ws',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isTestingConnection ? null : _testConnection,
                icon: _isTestingConnection
                    ? SizedBox(
                        width: AppSpacing.iconSm,
                        height: AppSpacing.iconSm,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Icon(Icons.wifi_tethering,
                        size: AppSpacing.iconSm,
                        color: AppColors.textPrimary),
                label: Text(
                  _isTestingConnection ? 'Testing...' : 'Test Connection',
                  style: AppTypography.labelLarge(color: AppColors.textPrimary),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
            ),
            if (_connectionTestResult != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                _connectionTestResult! ? Icons.check_circle : Icons.error,
                color: _connectionTestResult!
                    ? AppColors.income
                    : AppColors.expense,
                size: AppSpacing.iconMd,
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ==================== Project Section ====================

  Widget _buildProjectSection() {
    return _buildSection(
      title: 'Project',
      icon: Icons.folder_outlined,
      children: [
        _buildTextField(
          label: 'Project Name',
          controller: _projectNameController,
          hint: 'My Project',
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          label: 'Description',
          controller: _projectDescController,
          hint: 'Project description...',
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildSwitchTile(
          title: 'Auto-assign tasks',
          subtitle: 'Automatically assign tasks to available agents',
          value: _autoAssign,
          onChanged: (val) => setState(() => _autoAssign = val),
        ),
        Divider(color: AppColors.divider, height: 1),
        _buildSwitchTile(
          title: 'Auto-merge',
          subtitle: 'Automatically merge approved pull requests',
          value: _autoMerge,
          onChanged: (val) => setState(() => _autoMerge = val),
        ),
        Divider(color: AppColors.divider, height: 1),
        _buildSwitchTile(
          title: 'Require CIO approval',
          subtitle: 'All critical decisions require manual approval',
          value: _requireCioApproval,
          onChanged: (val) => setState(() => _requireCioApproval = val),
        ),
        Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: AppSpacing.sm),
        _buildSlider(
          label: 'Max Concurrent Tasks',
          value: _maxConcurrentTasks,
          min: 1,
          max: 10,
          divisions: 9,
          onChanged: (val) => setState(() => _maxConcurrentTasks = val),
        ),
      ],
    );
  }

  // ==================== Agents Section ====================

  Widget _buildAgentsSection() {
    return _buildSection(
      title: 'Agents',
      icon: Icons.smart_toy_outlined,
      children: [
        _buildSwitchTile(
          title: 'Project Manager (PM)',
          subtitle: 'Manages tasks, priorities, and sprint planning',
          value: _pmEnabled,
          onChanged: (val) => setState(() => _pmEnabled = val),
          iconData: Icons.assignment_ind,
        ),
        Divider(color: AppColors.divider, height: 1),
        _buildSwitchTile(
          title: 'Developer (Dev)',
          subtitle: 'Writes code, creates branches, and submits PRs',
          value: _devEnabled,
          onChanged: (val) => setState(() => _devEnabled = val),
          iconData: Icons.code,
        ),
        Divider(color: AppColors.divider, height: 1),
        _buildSwitchTile(
          title: 'QA Engineer (QA)',
          subtitle: 'Reviews code, runs tests, and validates quality',
          value: _qaEnabled,
          onChanged: (val) => setState(() => _qaEnabled = val),
          iconData: Icons.bug_report_outlined,
        ),
      ],
    );
  }

  // ==================== System Section ====================

  Widget _buildSystemSection() {
    return _buildSection(
      title: 'System',
      icon: Icons.settings_outlined,
      children: [
        _buildActionButton(
          label: 'Clear Cache',
          icon: Icons.cleaning_services_outlined,
          color: AppColors.textSecondary,
          onPressed: () {
            _showConfirmDialog(
              title: 'Clear Cache',
              message:
                  'This will clear all cached data. You may need to reload.',
              onConfirm: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cache cleared',
                        style: AppTypography.bodyMedium()),
                    backgroundColor: AppColors.cardDark,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActionButton(
          label: 'Export Data',
          icon: Icons.download_outlined,
          color: AppColors.primary,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Export started...',
                    style: AppTypography.bodyMedium()),
                backgroundColor: AppColors.cardDark,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActionButton(
          label: 'Reset Project',
          icon: Icons.restart_alt,
          color: AppColors.expense,
          onPressed: () {
            _showConfirmDialog(
              title: 'Reset Project',
              message:
                  'This will permanently reset the project. All tasks, decisions, and logs will be deleted. This cannot be undone.',
              onConfirm: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Project reset',
                        style: AppTypography.bodyMedium()),
                    backgroundColor: AppColors.expense,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // ==================== Shared Builders ====================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: AppSpacing.iconSm, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTypography.titleSmall()),
              ],
            ),
          ),
          Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium()),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          style: AppTypography.bodyMedium(),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundDark,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.divider),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? iconData,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          if (iconData != null) ...[
            Icon(iconData,
                size: AppSpacing.iconSm, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(title,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary)),
          ),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsets.only(
            left: iconData != null ? AppSpacing.lg : 0),
        child: Text(subtitle,
            style: AppTypography.bodySmall(color: AppColors.textMuted)),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      inactiveTrackColor: AppColors.divider,
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.bodyMedium(color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Text(
                value.toInt().toString(),
                style: AppTypography.labelMedium(color: AppColors.primary),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.divider,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            valueIndicatorColor: AppColors.primary,
            valueIndicatorTextStyle:
                AppTypography.labelSmall(color: AppColors.textPrimary),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: AppSpacing.iconSm, color: color),
        label: Text(label, style: AppTypography.labelLarge(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }
}
