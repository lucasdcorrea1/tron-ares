import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/dynamic_theme.dart';
import 'core/theme/theme_colors.dart';
import 'features/settings/presentation/bloc/theme_cubit.dart';
import 'features/settings/presentation/bloc/theme_state.dart';

/// Main application widget
class ImperiumApp extends StatelessWidget {
  const ImperiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          final dynamicTheme = DynamicTheme(state.activeTheme);

          // Update static AppColors for legacy compatibility
          AppColors.update(state.activeTheme);

          return MaterialApp.router(
            title: 'Imperium',
            debugShowCheckedModeBanner: false,

            // Dynamic Theme based on custom colors
            theme: dynamicTheme.lightTheme,
            darkTheme: dynamicTheme.darkTheme,
            themeMode: state.themeMode,

            // Localization
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('pt', 'BR'), // Portuguese (Brazil) - default
              Locale('en'), // English
            ],
            locale: const Locale('pt', 'BR'),

            // Router
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
