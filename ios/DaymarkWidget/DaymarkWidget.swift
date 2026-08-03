import AppIntents
import SwiftUI
import WidgetKit

private let widgetGroupId = "group.com.jiuxina.ying"
private let widgetKind = "DaymarkWidget"

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

private struct DaymarkEntry: TimelineEntry {
  let date: Date
  let events: [EventValue]
  let index: Int
  let color: Color
  let fontScale: Double
  let showNote: Bool
  let showCategory: Bool

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
      showCategory: true
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
    let raw = data?.string(forKey: "widget_events") ?? "[]"
    let events = (try? JSONDecoder().decode([EventValue].self, from: Data(raw.utf8))) ?? []
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
      showCategory: data?.object(forKey: "widget_show_category") == nil ? true : data?.bool(forKey: "widget_show_category") ?? true
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
          Text(event.dayDelta == 0 ? "就是今天" : event.isCountUp || event.dayDelta < 0 ? "天 · 已经" : "天 · 还有")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
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

@main
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
