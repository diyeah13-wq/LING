import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/theme_provider.dart';

class LingoApp extends ConsumerWidget {
  const LingoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'LINGO',
      debugShowCheckedModeBanner: false,
      theme: LingoAppTheme.light(),
      darkTheme: LingoAppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}