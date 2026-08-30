import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/bindings/AuthBinding.dart';

import '../core/constants/Colors.dart';
import '../core/constants/Keys.dart';
import '../core/network/client.dart';
import '../core/routes/routes.dart';
import '../core/routes/names.dart';
import '../core/services/SecureStorageService.dart';
import '../core/services/StorageService.dart';
import '../core/repository/AppUpdateRepository.dart';
import '../shared/widgets/app_update_dialog.dart';
import '../core/theme/theme.dart';

import '../modules/splash/SplashScreen.dart';
import '../shared/widgets/loader.dart';

class IndicabApp extends StatelessWidget {
  const IndicabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Indicab',
      debugShowCheckedModeBanner: false,
      initialBinding: AuthBinding(),
      home: const SplashScreen(),
      getPages: AppRoutes.pages,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}


class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final SecureStorageService _secureStorage = SecureStorageService();
  final StorageService _storage = StorageService();
  final ApiClient _client = ApiClient();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveInitialScreen();
    });
  }

  Future<void> _resolveInitialScreen() async {
    // 1. Check for app updates initially on app launch
    try {
      final updateRepo = AppUpdateRepository(_client);
      final updateInfo = await updateRepo.checkUpdate(appVersion: '1.0.0');

      if (updateInfo.updateAvailable && mounted) {
        await AppUpdateDialog.show(
          context: context,
          updateModel: updateInfo,
          onDismiss: _proceedToScreen,
        );
        // If force update is required, dialog remains open & blocks app navigation
        if (updateInfo.forceUpdate) {
          return;
        }
      }
    } catch (e) {
      debugPrint('App update check failed or offline: $e');
    }

    if (!mounted) return;
    await _proceedToScreen();
  }

  Future<void> _proceedToScreen() async {
    final token = await _readStoredToken();

    if (!mounted) {
      return;
    }

    if (token != null && token.isNotEmpty) {
      _client.setTokens(token);
      Get.offAllNamed(RouteNames.home);
      return;
    }

    Get.offAllNamed(RouteNames.login);
  }

  Future<String?> _readStoredToken() async {
    final secureToken = await _secureStorage.read(StorageKeys.token);
    if (secureToken != null && secureToken.isNotEmpty) {
      final cachedToken = _storage.read(StorageKeys.token);
      if (cachedToken != secureToken) {
        _storage.write(StorageKeys.token, secureToken);
      }
      return secureToken;
    }

    final cachedToken = _storage.read(StorageKeys.token);
    if (cachedToken is String && cachedToken.isNotEmpty) {
      await _secureStorage.write(StorageKeys.token, cachedToken);
      return cachedToken;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Center(
        child: AppPulsingLogoLoader(
          size: 72,
          message: 'Loading Indicab...',
          primaryColor: AppColors.primary,
        ),
      ),
    );
  }

}

class AppScreen extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool safeAreaBottom;
  final ScrollPhysics? physics;
  final bool resizeToAvoidBottomInset;

  const AppScreen({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.white,
    this.appBar,
    this.padding,
    this.scrollable = false,
    this.safeAreaBottom = true,
    this.physics,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (scrollable) {
      content = SingleChildScrollView(
        physics: physics ?? const BouncingScrollPhysics(),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(bottom: safeAreaBottom, child: content),
    );
  }
}
