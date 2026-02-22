import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData? icon;
  final bool fullScreen;

  const ErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const Gap(16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null) ...[
              const Gap(8),
              Text(
                details!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const Gap(24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'إعادة المحاولة',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (fullScreen) {
      return Scaffold(
        body: content,
      );
    }

    return content;
  }
}

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final bool fullScreen;

  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      message: 'خطأ في الاتصال بالشبكة',
      details: 'يرجى التحقق من اتصال الإنترنت وإعادة المحاولة',
      onRetry: onRetry,
      icon: Icons.wifi_off,
      fullScreen: fullScreen,
    );
  }
}

class ServerErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final bool fullScreen;

  const ServerErrorWidget({
    super.key,
    required this.onRetry,
    this.fullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      message: 'خطأ في السيرفر',
      details: 'حدث خطأ في الخادم، يرجى المحاولة مرة أخرى لاحقاً',
      onRetry: onRetry,
      icon: Icons.cloud_off,
      fullScreen: fullScreen,
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? description;
  final IconData icon;
  final VoidCallback? action;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.description,
    this.icon = Icons.inbox,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const Gap(16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const Gap(8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const Gap(24),
              ElevatedButton(
                onPressed: action,
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final String confirmText;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onConfirm,
    this.confirmText = 'حسناً',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      content: Text(
        message,
        style: const TextStyle(fontFamily: 'Cairo'),
      ),
      actions: [
        TextButton(
          onPressed: onConfirm ?? () => Navigator.pop(context),
          child: Text(
            confirmText,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      ],
    );
  }
}
