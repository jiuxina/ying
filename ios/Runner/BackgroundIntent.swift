import AppIntents
import Foundation
import home_widget

@available(iOS 17, *)
public struct BackgroundIntent: AppIntent {
  static public var title: LocalizedStringResource = "更新萤"

  @Parameter(title: "Widget URI")
  var url: URL?

  @Parameter(title: "App Group")
  var appGroup: String?

  public init() {}

  public init(url: URL?, appGroup: String?) {
    self.url = url
    self.appGroup = appGroup
  }

  public func perform() async throws -> some IntentResult {
    guard let appGroup else { return .result() }
    await HomeWidgetBackgroundWorker.run(url: url, appGroup: appGroup)
    return .result()
  }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension BackgroundIntent: ForegroundContinuableIntent {}
