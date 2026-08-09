/// 赞助解锁状态；验证成功后写入本地，卸载重装后重新验证同一把密钥即可恢复。
class UnlockState {
  const UnlockState({
    this.unlocked = false,
    this.keyHash,
    this.unlockToken,
    this.activatedAt,
  });

  final bool unlocked;
  final String? keyHash;
  final String? unlockToken;
  final DateTime? activatedAt;

  bool get isUnlocked => unlocked;

  UnlockState copyWith({
    bool? unlocked,
    String? keyHash,
    String? unlockToken,
    DateTime? activatedAt,
    bool clearToken = false,
  }) {
    return UnlockState(
      unlocked: unlocked ?? this.unlocked,
      keyHash: keyHash ?? this.keyHash,
      unlockToken: clearToken ? null : (unlockToken ?? this.unlockToken),
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }
}
