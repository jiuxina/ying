import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/unlock_controller.dart';
import 'glass_ui.dart';
import 'sponsor_page.dart';

bool isSponsorUnlocked(WidgetRef ref) {
  return ref.watch(unlockControllerProvider).isUnlocked;
}

Future<void> openSponsorPage(BuildContext context) {
  return Navigator.of(context).push<void>(
    GlassPageRoute(builder: (context) => const SponsorPage()),
  );
}

/// 未解锁时把子组件包在锁定态里，点击整块跳转赞助页。
class UnlockGate extends ConsumerWidget {
  const UnlockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = isSponsorUnlocked(ref);
    return Semantics(
      button: !unlocked,
      label: unlocked ? null : '赞助功能',
      hint: unlocked ? null : '点击查看赞助支持',
      child: GestureDetector(
        onTap: unlocked ? null : () => openSponsorPage(context),
        child: Stack(
          children: [
            IgnorePointer(ignoring: !unlocked, child: child),
            if (!unlocked)
              Positioned(
                right: 4,
                top: 4,
                child: Icon(
                  Icons.lock_rounded,
                  size: 15,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
