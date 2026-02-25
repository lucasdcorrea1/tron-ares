import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/imperium_app_bar.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/theme_cubit.dart';
import '../bloc/theme_state.dart';

/// Settings page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckStatusEvent()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            context.go('/login');
          } else if (state.status == AuthStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Erro'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: ImperiumAppBar(
              title: l10n.settingsTitle,
            ),
            body: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Profile section
                const _SectionHeader(title: 'PERFIL'),
                const SizedBox(height: AppSpacing.sm),
                _buildProfileCard(context, state),
                const SizedBox(height: AppSpacing.lg),

                // Appearance section
                _SectionHeader(title: l10n.appearance),
                const SizedBox(height: AppSpacing.sm),
                _buildThemeToggle(context, l10n),
                const SizedBox(height: AppSpacing.sm),
                _buildColorCustomization(context),
                const SizedBox(height: AppSpacing.lg),

                // About section
                _SectionHeader(title: l10n.about),
                const SizedBox(height: AppSpacing.sm),
                _buildAboutCard(context, l10n),
                const SizedBox(height: AppSpacing.lg),

                // Logout
                const _SectionHeader(title: 'CONTA'),
                const SizedBox(height: AppSpacing.sm),
                _buildLogoutCard(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AuthState state) {
    final profile = state.profile;
    final user = state.user;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          // Avatar
          ProfileAvatar(
            avatarUrl: profile?.avatar,
            size: 100,
            showEditIcon: true,
            onTap: state.isLoading
                ? null
                : () async {
                    final file = await pickImage(context);
                    if (file != null && context.mounted) {
                      context.read<AuthBloc>().add(
                            AuthUploadAvatarEvent(imageFile: file),
                          );
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.md),

          // Name
          Text(
            profile?.name ?? 'Usuário',
            style: AppTypography.titleLarge(),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Email
          Text(
            user?.email ?? '',
            style: AppTypography.bodyMedium(color: AppColors.textMuted),
          ),

          if (state.isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.imperiumGold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, AuthState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ListTile(
        leading: Icon(
          Icons.logout_rounded,
          color: AppColors.error,
        ),
        title: Text(
          'Sair da conta',
          style: AppTypography.titleSmall(color: AppColors.error),
        ),
        onTap: state.isLoading
            ? null
            : () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    backgroundColor: AppColors.cardDark,
                    title: Text(
                      'Sair da conta',
                      style: AppTypography.titleMedium(),
                    ),
                    content: Text(
                      'Tem certeza que deseja sair?',
                      style: AppTypography.bodyMedium(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancelar',
                          style: AppTypography.labelMedium(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<AuthBloc>().add(const AuthLogoutEvent());
                        },
                        child: Text(
                          'Sair',
                          style: AppTypography.labelMedium(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state.themeMode == ThemeMode.dark;
        final activeTheme = state.activeTheme;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: activeTheme.primary,
            ),
            title: Text(
              isDark ? l10n.darkMode : l10n.lightMode,
              style: AppTypography.titleSmall(),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
              activeColor: activeTheme.primary,
              activeTrackColor: activeTheme.primary.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorCustomization(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final activeTheme = state.activeTheme;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: ListTile(
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [activeTheme.primary, activeTheme.secondary],
                ),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              'Personalizar Cores',
              style: AppTypography.titleSmall(),
            ),
            subtitle: Text(
              state.customTheme != null ? 'Tema customizado' : activeTheme.name,
              style: AppTypography.bodySmall(color: AppColors.textMuted),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () => context.push('/settings/theme'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
            ),
            title: Text(
              l10n.aboutApp,
              style: AppTypography.titleSmall(),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                l10n.aboutDescription,
                style: AppTypography.bodySmall(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
          const Divider(
            height: 1,
            color: AppColors.divider,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
          ),
          ListTile(
            leading: const Icon(
              Icons.code_rounded,
              color: AppColors.textSecondary,
            ),
            title: Text(
              l10n.version,
              style: AppTypography.titleSmall(),
            ),
            trailing: Text(
              '1.0.0',
              style: AppTypography.bodyMedium(
                color: AppColors.textMuted,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall(
          color: AppColors.imperiumGold,
        ).copyWith(letterSpacing: 1.5),
      ),
    );
  }
}
