import AppIntents
import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.jiuxina.ying"
private let widgetKind = "DaymarkWidget"
private let detailWidgetKind = "DaymarkDetailWidget"

private struct EventValue: Codable, Identifiable {
  let id: String
  let title: String
  let targetDate: Int64
  let category: String
  let note: String
  let isCountUp: Bool

  var target: Date { Date(timeIntervalSince1970: TimeInterval(targetDate) / 1000) }
  var dayDelta: Int {
    Calendar.current.dateComponents(
      [.day],
      from: Calendar.current.startOfDay(for: Date()),
      to: Calendar.current.startOfDay(for: target)
    ).day ?? 0
  }
}

private func loadDaymarkEvents(from data: UserDefaults?) -> [EventValue] {
  let raw = data?.string(forKey: "widget_events") ?? "[]"
  return (try? JSONDecoder().decode([EventValue].self, from: Data(raw.utf8))) ?? []
}

private func urgentLevel(days: Int) -> Int {
  if days < 0 { return 0 }
  if days <= 1 { return 1 }
  if days <= 3 { return 3 }
  if days <= 7 { return 7 }
  return 0
}

private func urgentColor(level: Int) -> Color? {
  switch level {
  case 7: return Color(red: 0.71, green: 0.33, blue: 0.04)
  case 3: return Color(red: 0.76, green: 0.25, blue: 0.05)
  case 1: return Color(red: 0.73, green: 0.11, blue: 0.11)
  default: return nil
  }
}

private func urgentLabel(level: Int, days: Int) -> String {
  switch level {
  case 7: return "天 · 快到了"
  case 3: return "只剩\(days)天"
  case 1: return days == 0 ? "就是今天" : "只剩\(days)天"
  default: return ""
  }
}

private struct DaymarkEntry: TimelineEntry {
  let date: Date
  let events: [EventValue]
  let index: Int
  let color: Color
  let fontScale: Double
  let showNote: Bool
  let showCategory: Bool
  let urgentHighlight: Bool

  var event: EventValue? {
    guard !events.isEmpty else { return nil }
    return events[max(0, min(index, events.count - 1))]
  }
}

private struct Provider: AppIntentTimelineProvider {
  typealias Intent = DaymarkConfigurationIntent

  func placeholder(in context: Context) -> DaymarkEntry {
    DaymarkEntry(
      date: Date(),
      events: [EventValue(id: "preview", title: "下一场旅行", targetDate: Int64(Date().addingTimeInterval(86400 * 18).timeIntervalSince1970 * 1000), category: "旅行", note: "去看看海", isCountUp: false)],
      index: 0,
      color: Color(red: 0.40, green: 0.31, blue: 0.64),
      fontScale: 1,
      showNote: true,
      showCategory: true,
      urgentHighlight: false
    )
  }

  func snapshot(for configuration: DaymarkConfigurationIntent, in context: Context) async -> DaymarkEntry {
    loadEntry()
  }

  func timeline(for configuration: DaymarkConfigurationIntent, in context: Context) async -> Timeline<DaymarkEntry> {
    let entry = loadEntry()
    let calendar = Calendar.current
    let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date().addingTimeInterval(3600)
    return Timeline(entries: [entry], policy: .after(nextMidnight))
  }

  private func loadEntry() -> DaymarkEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let index = data?.integer(forKey: "widget_ios_index") ?? 0
    let events = loadDaymarkEvents(from: data)
    let colorHex = data?.string(forKey: "widget_color") ?? "ff6750a4"
    let colorValue = UInt32(colorHex, radix: 16) ?? 0xFF6750A4
    let red = Double((colorValue >> 16) & 0xFF) / 255
    let green = Double((colorValue >> 8) & 0xFF) / 255
    let blue = Double(colorValue & 0xFF) / 255
    let fontScale = data?.double(forKey: "widget_font_scale") ?? 1
    return DaymarkEntry(
      date: Date(),
      events: events,
      index: events.isEmpty ? 0 : (index % events.count + events.count) % events.count,
      color: Color(red: red, green: green, blue: blue),
      fontScale: fontScale,
      showNote: data?.object(forKey: "widget_show_note") == nil ? true : data?.bool(forKey: "widget_show_note") ?? true,
      showCategory: data?.object(forKey: "widget_show_category") == nil ? true : data?.bool(forKey: "widget_show_category") ?? true,
      urgentHighlight: data?.bool(forKey: "widget_urgent_highlight") ?? false
    )
  }
}

@available(iOS 17.0, *)
struct DaymarkConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "萤设置"
  static var description = IntentDescription("在小部件中切换查看事件。")
}

private struct DaymarkEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DaymarkEntry

  var body: some View {
    if let event = entry.event {
      let days = event.dayDelta
      let level = entry.urgentHighlight ? urgentLevel(days: days) : 0
      let urgent = level > 0
      let digitColor = urgentColor(level: level) ?? Color.white
      let unitText = urgent
        ? urgentLabel(level: level, days: days)
        : (event.dayDelta == 0
            ? "就是今天"
            : (event.isCountUp || event.dayDelta < 0 ? "天 · 已经" : "天 · 还有"))
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          if entry.showCategory {
            Text(event.category.uppercased())
              .font(.caption2.weight(.bold))
              .foregroundStyle(.white.opacity(0.8))
          }
          Spacer()
          if family == .systemMedium, #available(iOSApplicationExtension 17.0, *) {
            Button(intent: ChangeEventIntent(step: -1, currentIndex: entry.index, eventCount: entry.events.count)) {
              Image(systemName: "chevron.left")
            }.buttonStyle(.plain)
            Button(intent: ChangeEventIntent(step: 1, currentIndex: entry.index, eventCount: entry.events.count)) {
              Image(systemName: "chevron.right")
            }.buttonStyle(.plain)
          }
        }
        Text(event.title)
          .font(.system(size: 19 * entry.fontScale, weight: .bold))
          .lineLimit(1)
        Spacer(minLength: 2)
        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text("\(abs(event.dayDelta))")
            .font(.system(size: 44 * entry.fontScale, weight: .heavy, design: .rounded))
            .foregroundStyle(digitColor)
          Text(unitText)
            .font(.caption)
            .foregroundStyle(urgent ? digitColor.opacity(0.92) : .white.opacity(0.8))
          Spacer()
          if #available(iOSApplicationExtension 17.0, *) {
            Button(intent: BackgroundIntent(url: URL(string: "ying://complete?id=\(event.id)"), appGroup: widgetGroupId)) {
              Image(systemName: "checkmark.circle")
                .font(.title2)
            }.buttonStyle(.plain)
          }
        }
        if family == .systemMedium && entry.showNote && !event.note.isEmpty {
          Text(event.note)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
        }
      }
      .foregroundStyle(.white)
      .containerBackground(entry.color, for: .widget)
      .widgetURL(URL(string: "ying://event?id=\(event.id)"))
    } else {
      VStack(alignment: .leading) {
        Text("萤").font(.caption.bold())
        Spacer()
        Text("添加一个倒数日").font(.headline)
        Text("打开应用开始记录").font(.caption)
      }
      .foregroundStyle(.white)
      .containerBackground(entry.color, for: .widget)
      .widgetURL(URL(string: "ying://new"))
    }
  }
}

@available(iOS 17.0, *)
struct ChangeEventIntent: AppIntent {
  static var title: LocalizedStringResource = "切换事件"

  @Parameter var step: Int
  @Parameter var currentIndex: Int
  @Parameter var eventCount: Int

  init() {}
  init(step: Int, currentIndex: Int, eventCount: Int) {
    self.step = step
    self.currentIndex = currentIndex
    self.eventCount = eventCount
  }

  func perform() async throws -> some IntentResult {
    let next = eventCount == 0 ? 0 : (currentIndex + step + eventCount) % eventCount
    UserDefaults(suiteName: widgetGroupId)?.set(next, forKey: "widget_ios_index")
    WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    return .result()
  }
}

private struct DaymarkEventEntity: AppEntity, Identifiable {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "事件"
  static var defaultQuery = DaymarkEventQuery()

  let id: String
  let title: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(stringLiteral: title)
  }
}

private struct DaymarkEventQuery: EntityQuery {
  func entities(for identifiers: [DaymarkEventEntity.ID]) async throws -> [DaymarkEventEntity] {
    loadEvents().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [DaymarkEventEntity] {
    loadEvents()
  }

  private func loadEvents() -> [DaymarkEventEntity] {
    let data = UserDefaults(suiteName: widgetGroupId)
    return loadDaymarkEvents(from: data).map {
      DaymarkEventEntity(id: $0.id, title: $0.title)
    }
  }
}

@available(iOS 17.0, *)
struct DaymarkDetailConfigurationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "聚焦事件"
  static var description = IntentDescription("选择一个事件固定显示。")

  @Parameter(title: "事件")
  var event: DaymarkEventEntity?

  init() {}
}

private struct DaymarkDetailEntry: TimelineEntry {
  let date: Date
  let event: EventValue?
  let color: Color
  let fontScale: Double
  let showNote: Bool
  let showCategory: Bool
  let urgentHighlight: Bool
}

private struct DaymarkDetailProvider: AppIntentTimelineProvider {
  typealias Intent = DaymarkDetailConfigurationIntent

  func placeholder(in context: Context) -> DaymarkDetailEntry {
    DaymarkDetailEntry(
      date: Date(),
      event: EventValue(id: "preview", title: "毕业典礼", targetDate: Int64(Date().addingTimeInterval(86400 * 3).timeIntervalSince1970 * 1000), category: "重要", note: "别忘了合影", isCountUp: false),
      color: Color(red: 0.40, green: 0.31, blue: 0.64),
      fontScale: 1,
      showNote: true,
      showCategory: true,
      urgentHighlight: true
    )
  }

  func snapshot(for configuration: DaymarkDetailConfigurationIntent, in context: Context) async -> DaymarkDetailEntry {
    loadEntry(configuration: configuration)
  }

  func timeline(for configuration: DaymarkDetailConfigurationIntent, in context: Context) async -> Timeline<DaymarkDetailEntry> {
    let entry = loadEntry(configuration: configuration)
    let calendar = Calendar.current
    let nextMidnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())) ?? Date().addingTimeInterval(3600)
    return Timeline(entries: [entry], policy: .after(nextMidnight))
  }

  private func loadEntry(configuration: DaymarkDetailConfigurationIntent) -> DaymarkDetailEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    let events = loadDaymarkEvents(from: data)
    let selected = events.first { $0.id == configuration.event?.id } ?? events.first
    let colorHex = data?.string(forKey: "widget_color") ?? "ff6750a4"
    let colorValue = UInt32(colorHex, radix: 16) ?? 0xFF6750A4
    let red = Double((colorValue >> 16) & 0xFF) / 255
    let green = Double((colorValue >> 8) & 0xFF) / 255
    let blue = Double(colorValue & 0xFF) / 255
    return DaymarkDetailEntry(
      date: Date(),
      event: selected,
      color: Color(red: red, green: green, blue: blue),
      fontScale: data?.double(forKey: "widget_font_scale") ?? 1,
      showNote: data?.object(forKey: "widget_show_note") == nil ? true : data?.bool(forKey: "widget_show_note") ?? true,
      showCategory: data?.object(forKey: "widget_show_category") == nil ? true : data?.bool(forKey: "widget_show_category") ?? true,
      urgentHighlight: data?.bool(forKey: "widget_urgent_highlight") ?? false
    )
  }
}

private struct DaymarkDetailEntryView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DaymarkDetailEntry

  var body: some View {
    if let event = entry.event {
      let days = event.dayDelta
      let level = entry.urgentHighlight ? urgentLevel(days: days) : 0
      let urgent = level > 0
      let digitColor = urgentColor(level: level) ?? Color.white
      let unitText = urgent
        ? urgentLabel(level: level, days: days)
        : (event.dayDelta == 0
            ? "就是今天"
            : (event.isCountUp || event.dayDelta < 0 ? "天 · 已经" : "天 · 还有"))
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          if entry.showCategory {
            Text(event.category.uppercased())
              .font(.caption2.weight(.bold))
              .foregroundStyle(.white.opacity(0.8))
          }
          Spacer()
          if #available(iOSApplicationExtension 17.0, *) {
            Button(intent: BackgroundIntent(url: URL(string: "ying://complete?id=\(event.id)"), appGroup: widgetGroupId)) {
              Image(systemName: "checkmark.circle")
                .font(.title2)
            }.buttonStyle(.plain)
          }
        }
        Text(event.title)
          .font(.system(size: 21 * entry.fontScale, weight: .bold))
          .lineLimit(1)
        Spacer(minLength: 2)
        HStack(alignment: .lastTextBaseline, spacing: 6) {
          Text("\(abs(event.dayDelta))")
            .font(.system(size: 52 * entry.fontScale, weight: .heavy, design: .rounded))
            .foregroundStyle(digitColor)
          Text(unitText)
            .font(.caption)
            .foregroundStyle(urgent ? digitColor.opacity(0.92) : .white.opacity(0.8))
          Spacer()
        }
        if family == .systemMedium && entry.showNote && !event.note.isEmpty {
          Text(event.note)
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
            .lineLimit(1)
        }
      }
      .foregroundStyle(.white)
      .containerBackground(entry.color, for: .widget)
      .widgetURL(URL(string: "ying://event?id=\(event.id)"))
    } else {
      VStack(alignment: .leading) {
        Text("萤").font(.caption.bold())
        Spacer()
        Text("添加一个倒数日").font(.headline)
        Text("打开应用开始记录").font(.caption)
      }
      .foregroundStyle(.white)
      .containerBackground(entry.color, for: .widget)
      .widgetURL(URL(string: "ying://new"))
    }
  }
}

struct DaymarkWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: widgetKind, intent: DaymarkConfigurationIntent.self, provider: Provider()) { entry in
      DaymarkEntryView(entry: entry)
    }
    .configurationDisplayName("萤倒数日")
    .description("切换事件并快速标记完成。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@available(iOS 17.0, *)
private struct DaymarkDetailWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: detailWidgetKind, intent: DaymarkDetailConfigurationIntent.self, provider: DaymarkDetailProvider()) { entry in
      DaymarkDetailEntryView(entry: entry)
    }
    .configurationDisplayName("萤单事件")
    .description("固定显示一个事件并快速完成。")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@available(iOS 17.0, *)
@main
struct DaymarkWidgets: WidgetBundle {
  var body: some Widget {
    DaymarkWidget()
    DaymarkDetailWidget()
  }
}
