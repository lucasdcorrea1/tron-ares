import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/google_calendar_service.dart';

/// Card widget for Google Calendar sync status and actions
class GoogleCalendarSyncCard extends StatefulWidget {
  final VoidCallback? onSyncComplete;

  const GoogleCalendarSyncCard({
    super.key,
    this.onSyncComplete,
  });

  @override
  State<GoogleCalendarSyncCard> createState() => _GoogleCalendarSyncCardState();
}

class _GoogleCalendarSyncCardState extends State<GoogleCalendarSyncCard> {
  final GoogleCalendarService _calendarService = GoogleCalendarService();
  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);
    await _calendarService.init();
    setState(() => _isLoading = false);
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    final success = await _calendarService.signIn();
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conectado como ${_calendarService.userEmail}'),
          backgroundColor: AppColors.income,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _calendarService.signOut();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Desconectado do Google Calendar'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
    }
  }

  Future<void> _sync() async {
    setState(() => _isSyncing = true);

    try {
      // For now, just fetch events to test connection
      final events = await _calendarService.getEvents();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${events.length} eventos sincronizados'),
            backgroundColor: AppColors.income,
          ),
        );
        widget.onSyncComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao sincronizar: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }

    setState(() => _isSyncing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Verificando conexão...',
              style: AppTypography.bodySmall(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _calendarService.isSignedIn
              ? AppColors.income.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Google icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _calendarService.isSignedIn
                      ? AppColors.income.withValues(alpha: 0.1)
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: _calendarService.isSignedIn
                      ? AppColors.income
                      : AppColors.textMuted,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Calendar',
                      style: AppTypography.titleSmall(),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _calendarService.isSignedIn
                          ? _calendarService.userEmail ?? 'Conectado'
                          : 'Não conectado',
                      style: AppTypography.bodySmall(
                        color: _calendarService.isSignedIn
                            ? AppColors.income
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (_calendarService.isSignedIn) ...[
                // Sync button
                IconButton(
                  onPressed: _isSyncing ? null : _sync,
                  icon: _isSyncing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Icon(
                          Icons.sync_rounded,
                          color: AppColors.primary,
                        ),
                  tooltip: 'Sincronizar',
                ),
                // Disconnect button
                IconButton(
                  onPressed: _signOut,
                  icon: Icon(
                    Icons.link_off_rounded,
                    color: AppColors.expense,
                  ),
                  tooltip: 'Desconectar',
                ),
              ] else ...[
                // Connect button
                ElevatedButton.icon(
                  onPressed: _signIn,
                  icon: const Icon(Icons.link_rounded, size: 18),
                  label: const Text('Conectar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Info text when connected
          if (_calendarService.isSignedIn) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Eventos serão sincronizados automaticamente',
                      style: AppTypography.labelSmall(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
