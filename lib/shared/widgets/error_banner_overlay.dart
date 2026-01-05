import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/error_provider.dart';
import 'error_banner.dart';

/// Overlay widget that displays error banners at the top of the screen
/// 
/// This widget should be placed at the root of the app to show global errors
class ErrorBannerOverlay extends ConsumerWidget {
  final Widget child;

  const ErrorBannerOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorState = ref.watch(errorProvider);

    return Stack(
      children: [
        child,
        if (errorState.errors.isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: errorState.errors.map((error) {
                  return ErrorBanner(
                    key: ValueKey(error.id),
                    message: error.message,
                    errorType: error.errorType,
                    onDismiss: () {
                      ref.read(errorProvider.notifier).removeError(error.id!);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

