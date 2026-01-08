/// 事件分类枚举
enum EventCategory {
  birthday('生日', '🎂'),
  anniversary('纪念日', '💑'),
  holiday('节假日', '🎉'),
  exam('考试', '📚'),
  work('工作', '💼'),
  travel('旅行', '✈️'),
  custom('自定义', '📌');

  final String label;
  final String emoji;

  const EventCategory(this.label, this.emoji);

  /// 根据名称获取分类
  static EventCategory fromName(String name) {
    return EventCategory.values.firstWhere(
      (e) => e.name == name,
      orElse: () => EventCategory.custom,
    );
  }
}
