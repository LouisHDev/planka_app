import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:planka_app/providers/attachment_provider.dart';
import 'package:planka_app/providers/card_actions_provider.dart';
import 'package:planka_app/providers/card_provider.dart';
import 'package:planka_app/providers/list_provider.dart';
import 'package:planka_app/providers/project_provider.dart';
import 'package:planka_app/providers/user_provider.dart';
import 'package:planka_app/screens/ui/fullscreen_card.dart';
import 'package:planka_app/screens/list_screen.dart';
import 'package:planka_app/screens/project_screen.dart';
import 'package:planka_app/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import './providers/auth_provider.dart';
import './providers/board_provider.dart';
import './screens/login_screen.dart';
import './screens/board_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Init localizations
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
        supportedLocales: const [
          Locale('de', 'DE'),
          Locale('en', 'US'),
          Locale('es', 'ES'),
          Locale('fr', 'FR'),
          Locale('tr', 'TR'),
          Locale('it', 'IT'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('de', 'DE'),
        saveLocale: true,
        startLocale:  const Locale('de', 'DE'),
        child: const MyApp()
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
          create: (_) => ProjectProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, auth, previous) => ProjectProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BoardProvider>(
          create: (_) => BoardProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, auth, previous) => BoardProvider(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ListProvider>(
          create: (_) => ListProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, authProvider, listProvider) => ListProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CardProvider>(
          create: (_) => CardProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, authProvider, cardProvider) => CardProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, authProvider, userProvider) => UserProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttachmentProvider>(
          create: (_) => AttachmentProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, authProvider, attachmentProvider) => AttachmentProvider(authProvider),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CardActionsProvider>(
          create: (_) => CardActionsProvider(Provider.of<AuthProvider>(_, listen: false)),
          update: (_, authProvider, cardActionsProvider) => CardActionsProvider(authProvider),
        ),
      ],
      child: MaterialApp(
        title: "Planka App",
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          textTheme: Theme.of(context).textTheme.apply(
            fontSizeFactor: 0.8,
            fontSizeDelta: 2.0,
          ),
        ),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: const LoginScreen(),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/projects': (ctx) => const ProjectScreen(),
          '/boards': (ctx) => BoardScreen(),
          '/lists': (ctx) => ListScreen(),
          '/card': (ctx) =>  FCardScreen(),
          '/settings': (ctx) => const SettingsScreen()
        },
      ),
    );
  }
}
