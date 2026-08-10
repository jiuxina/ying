import 'package:flutter/material.dart';

import 'glass_ui.dart';
import 'permission_manage_section.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      body: LiquidBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 34 : 20,
                34,
                wide ? 34 : 20,
                34,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        '欢迎使用',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    PermissionManageSection(compact: true),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('onboarding-finish'),
                        onPressed: onFinished,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('开始使用'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        key: const ValueKey('onboarding-skip'),
                        onPressed: onFinished,
                        child: const Text('跳过，稍后再设置'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
