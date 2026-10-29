import SwiftUI
import WidgetKit

// Shared with the app through the App Group, written by `WidgetBridge` in
// Runner/AppDelegate.swift from `WidgetSnapshot` in
// lib/features/widgets/widget_snapshot.dart. Keep the fields in sync.
private let appGroup = "group.com.lucas-goldner.pushup-bro"
private let snapshotKey = "widget_snapshot"

// MARK: - Data

struct WidgetDay: Decodable {
  let date: String
  let pushups: Int
}

struct WidgetTrek: Decodable {
  let stageNumber: Int
  let stageCount: Int
  let title: String
  let waves: Int
  let boss: Bool
  let allCleared: Bool
}

/// What the app last told the widgets.
struct WidgetSnapshot: Decodable {
  var hasAccess = false
  var isPro = false
  /// When the free days end (milliseconds since 1970), while they are the
  /// only thing keeping everything open.
  var accessUntilMs: Double?
  var streak = 0
  var longestStreak = 0
  var todayPushups = 0
  var dailyGoal = 50
  var lastWorkoutDate: String?
  var days: [WidgetDay] = []
  var trek: WidgetTrek?
  var bananas = 0
  var language = "en"
  var appearance = "system"

  enum CodingKeys: String, CodingKey {
    case hasAccess, isPro, accessUntilMs, streak, longestStreak, todayPushups, dailyGoal
    case lastWorkoutDate, days, trek, bananas, language, appearance
  }

  init() {}

  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    hasAccess = try values.decodeIfPresent(Bool.self, forKey: .hasAccess) ?? false
    isPro = try values.decodeIfPresent(Bool.self, forKey: .isPro) ?? false
    accessUntilMs = try values.decodeIfPresent(Double.self, forKey: .accessUntilMs)
    streak = try values.decodeIfPresent(Int.self, forKey: .streak) ?? 0
    longestStreak = try values.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
    todayPushups = try values.decodeIfPresent(Int.self, forKey: .todayPushups) ?? 0
    dailyGoal = try values.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 50
    lastWorkoutDate = try values.decodeIfPresent(String.self, forKey: .lastWorkoutDate)
    days = try values.decodeIfPresent([WidgetDay].self, forKey: .days) ?? []
    trek = try values.decodeIfPresent(WidgetTrek.self, forKey: .trek)
    bananas = try values.decodeIfPresent(Int.self, forKey: .bananas) ?? 0
    language = try values.decodeIfPresent(String.self, forKey: .language) ?? "en"
    appearance = try values.decodeIfPresent(String.self, forKey: .appearance) ?? "system"
  }

  /// Nothing synced yet: the widgets stay locked until the app opens.
  static var empty: WidgetSnapshot { WidgetSnapshot() }

  /// Shown in the widget gallery.
  static var preview: WidgetSnapshot {
    let today = Date()
    let counts = [40, 25, 52, 0, 38, 27, 32]
    var snapshot = WidgetSnapshot()
    snapshot.hasAccess = true
    snapshot.isPro = true
    snapshot.streak = 14
    snapshot.longestStreak = 21
    snapshot.todayPushups = counts.last ?? 0
    snapshot.lastWorkoutDate = dayKey(today)
    snapshot.days = counts.enumerated().map { index, pushups in
      let day = Calendar.current.date(byAdding: .day, value: index - (counts.count - 1), to: today) ?? today
      return WidgetDay(date: dayKey(day), pushups: pushups)
    }
    snapshot.trek = WidgetTrek(
      stageNumber: 5, stageCount: 8, title: "Temple of Scales", waves: 3, boss: false,
      allCleared: false)
    snapshot.bananas = 640
    snapshot.language = Locale.preferredLanguages.first ?? "en"
    return snapshot
  }

  static func load() -> WidgetSnapshot {
    guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: snapshotKey),
      let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: Data(json.utf8))
    else { return .empty }
    return snapshot
  }

  var accessUntil: Date? {
    guard let ms = accessUntilMs else { return nil }
    return Date(timeIntervalSince1970: ms / 1000)
  }

  /// Whether the widgets show their content at [date]: with Pro, or while
  /// the free days (or a store that sells nothing) keep everything open.
  func unlocked(at date: Date) -> Bool {
    if isPro { return true }
    if let until = accessUntil { return date < until }
    return hasAccess
  }

  /// The streak as of [date]: it ends once a whole day passed without
  /// pushups.
  func currentStreak(on date: Date) -> Int {
    guard let last = lastWorkoutDate else { return 0 }
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
    return last == dayKey(date) || last == dayKey(yesterday) ? streak : 0
  }

  func pushups(on date: Date) -> Int {
    let key = dayKey(date)
    return days.first { $0.date == key }?.pushups ?? 0
  }

  /// The seven days ending on [date], oldest first.
  func week(endingOn date: Date) -> [DayCount] {
    (0..<7).reversed().map { back in
      let day = Calendar.current.date(byAdding: .day, value: -back, to: date) ?? date
      return DayCount(date: day, pushups: pushups(on: day), isToday: back == 0)
    }
  }

  /// The colour scheme to draw in: the app's appearance setting, or the
  /// phone's.
  func scheme(_ system: ColorScheme) -> ColorScheme {
    switch appearance {
    case "light": return .light
    case "dark": return .dark
    default: return system
    }
  }
}

struct DayCount {
  let date: Date
  let pushups: Int
  let isToday: Bool
}

/// The local calendar day of [date], as the app writes it (yyyy-MM-dd).
func dayKey(_ date: Date) -> String {
  let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
  return String(format: "%04ld-%02ld-%02ld", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
}

// MARK: - Strings

/// The widget strings in the app's language (Localizable.strings), which
/// can differ from the phone's.
struct L10n {
  let bundle: Bundle
  let locale: Locale

  init(language: String) {
    let code = L10n.lproj(for: language)
    bundle = L10n.bundle(for: code)
    locale = Locale(identifier: code)
  }

  private static func lproj(for language: String) -> String {
    let base =
      language.components(separatedBy: CharacterSet(charactersIn: "-_")).first?.lowercased()
      ?? "en"
    switch base {
    case "pt": return "pt-BR"
    case "de", "es", "ja": return base
    default: return "en"
    }
  }

  private static func bundle(for code: String) -> Bundle {
    if let path = Bundle.main.path(forResource: code, ofType: "lproj"),
      let bundle = Bundle(path: path)
    {
      return bundle
    }
    return Bundle.main
  }

  func callAsFunction(_ key: String) -> String {
    bundle.localizedString(forKey: key, value: nil, table: nil)
  }

  func format(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: callAsFunction(key), locale: locale, arguments: arguments)
  }

  /// One-letter weekday names, like M T W.
  func weekdayLetter(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.setLocalizedDateFormatFromTemplate("EEEEE")
    return formatter.string(from: date)
  }
}

// MARK: - Timeline

struct SnapshotEntry: TimelineEntry {
  let date: Date
  let snapshot: WidgetSnapshot
}

struct SnapshotProvider: TimelineProvider {
  func placeholder(in context: Context) -> SnapshotEntry {
    SnapshotEntry(date: Date(), snapshot: .preview)
  }

  func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
    let snapshot = context.isPreview ? WidgetSnapshot.preview : WidgetSnapshot.load()
    completion(SnapshotEntry(date: Date(), snapshot: snapshot))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
    let now = Date()
    let snapshot = WidgetSnapshot.load()
    let calendar = Calendar.current
    // At midnight today's pushups start over and a missed day ends the
    // streak, without the app having to run.
    let midnight = calendar.startOfDay(
      for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
    var dates = [now]
    if let until = snapshot.accessUntil, until > now, until < midnight {
      dates.append(until)
    }
    dates.append(midnight)
    let entries = dates.map { SnapshotEntry(date: $0, snapshot: snapshot) }
    completion(Timeline(entries: entries, policy: .after(midnight)))
  }
}

// MARK: - Style

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255)
  }
}

/// The app's colours (lib/core/style/pb_colors.dart) in light and dark mode.
struct Palette {
  let background: Color
  let surface: Color
  let track: Color
  let text: Color
  let muted: Color
  let orange: Color
  let jungle: Color
  let red: Color
  let banana: Color
  let accent: Color

  static func of(_ scheme: ColorScheme) -> Palette {
    if scheme == .dark {
      return Palette(
        background: Color(hex: 0x111729), surface: Color(hex: 0x1D2640),
        track: Color(hex: 0x2E3856), text: Color(hex: 0xF2F6FF), muted: Color(hex: 0xA9AFC0),
        orange: Color(hex: 0xF5A623), jungle: Color(hex: 0x3CC08F), red: Color(hex: 0xFF6E66),
        banana: Color(hex: 0xF5C343), accent: Color(hex: 0x7FB2FF))
    }
    return Palette(
      background: Color(hex: 0xF2F6FF), surface: Color(hex: 0xFFFFFF),
      track: Color(hex: 0xE4E9F4), text: Color(hex: 0x17203A), muted: Color(hex: 0x6B7489),
      orange: Color(hex: 0xF5A623), jungle: Color(hex: 0x2FA37A), red: Color(hex: 0xE5534B),
      banana: Color(hex: 0xF5C343), accent: Color(hex: 0x5E9EFF))
  }
}

extension Font {
  /// Cabinet Grotesk for the big numbers, bundled with the extension
  /// (UIAppFonts). Falls back to the system font if it can't be loaded.
  static func grotesk(_ size: CGFloat, extraBold: Bool = true) -> Font {
    .custom(extraBold ? "CabinetGrotesk-Extrabold" : "CabinetGrotesk-Bold", size: size)
  }
}

/// Everything a widget view needs for one entry.
struct EntryContext {
  let entry: SnapshotEntry
  let palette: Palette
  let l10n: L10n

  init(entry: SnapshotEntry, scheme: ColorScheme) {
    self.entry = entry
    palette = Palette.of(entry.snapshot.scheme(scheme))
    l10n = L10n(language: entry.snapshot.language)
  }

  var snapshot: WidgetSnapshot { entry.snapshot }
  var date: Date { entry.date }
  var unlocked: Bool { snapshot.unlocked(at: date) }
}

// MARK: - Shared views

/// The small uppercase heading of a widget.
struct Caption: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text.uppercased())
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(color)
      .lineLimit(1)
      .minimumScaleFactor(0.8)
  }
}

struct ProgressBar: View {
  let value: Double
  let fill: Color
  let track: Color

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule().fill(track)
        Capsule()
          .fill(fill)
          .frame(width: geometry.size.width * CGFloat(min(max(value, 0), 1)))
      }
    }
  }
}

/// Shown instead of the content without Pro: a grayed Carlos and a lock.
struct LockedView: View {
  let context: EntryContext

  var body: some View {
    let palette = context.palette
    VStack(spacing: 2) {
      ZStack {
        Image("CarlosWave")
          .resizable()
          .scaledToFit()
          .frame(height: 94)
          .grayscale(1)
          .opacity(0.35)
        Image(systemName: "lock.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(palette.surface)
          .frame(width: 36, height: 36)
          .background(Circle().fill(palette.text))
      }
      Spacer(minLength: 4)
      Text(context.l10n("locked.title"))
        .font(.system(size: 13, weight: .bold))
        .foregroundStyle(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
      Text(context.l10n("locked.hint"))
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(palette.muted)
        .lineLimit(1)
    }
    .padding(.top, 10)
    .padding(.bottom, 14)
    .padding(.horizontal, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

/// A lock for the lock screen widgets without Pro.
struct LockedAccessory: View {
  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      Image(systemName: "lock.fill").font(.system(size: 18, weight: .bold))
    }
  }
}

extension View {
  func surfaceBackground(_ palette: Palette) -> some View {
    containerBackground(for: .widget) { palette.surface }
  }

  func clearBackground() -> some View {
    containerBackground(for: .widget) { Color.clear }
  }
}

// MARK: - Streak

struct StreakView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme
  let entry: SnapshotEntry

  var body: some View {
    let context = EntryContext(entry: entry, scheme: scheme)
    let streak = context.snapshot.currentStreak(on: context.date)
    switch family {
    case .accessoryCircular:
      Group {
        if context.unlocked {
          ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
              Image(systemName: "flame.fill").font(.system(size: 14, weight: .bold))
              Text(String(streak))
                .font(.grotesk(20))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }
          }
        } else {
          LockedAccessory()
        }
      }
      .clearBackground()
    default:
      Group {
        if context.unlocked {
          small(context: context, streak: streak)
        } else {
          LockedView(context: context)
        }
      }
      .surfaceBackground(context.palette)
    }
  }

  private func small(context: EntryContext, streak: Int) -> some View {
    let palette = context.palette
    let week = context.snapshot.week(endingOn: context.date)
    return VStack(alignment: .leading, spacing: 0) {
      HStack {
        Image(systemName: "flame.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(palette.orange)
          .frame(width: 30, height: 30)
          .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
              .fill(palette.orange.opacity(0.18)))
        Spacer(minLength: 4)
        Caption(text: context.l10n("streak.label"), color: palette.muted)
      }
      Spacer(minLength: 4)
      Text(String(streak))
        .font(.grotesk(46))
        .foregroundStyle(palette.text)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
      Text(context.l10n(streak == 1 ? "streak.dayInARow" : "streak.daysInARow"))
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(palette.muted)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Spacer(minLength: 6)
      HStack(spacing: 4) {
        ForEach(0..<week.count, id: \.self) { index in
          Capsule()
            .fill(week[index].pushups > 0 ? palette.orange : palette.track)
            .frame(height: 6)
        }
      }
    }
    .padding(14)
  }
}

struct StreakWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PushupBroStreak", provider: SnapshotProvider()) { entry in
      StreakView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("gallery.streak.name"))
    .description(LocalizedStringKey("gallery.streak.description"))
    .supportedFamilies([.systemSmall, .accessoryCircular])
    .contentMarginsDisabled()
  }
}

// MARK: - Today

struct TodayView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme
  let entry: SnapshotEntry

  var body: some View {
    let context = EntryContext(entry: entry, scheme: scheme)
    let goal = max(context.snapshot.dailyGoal, 1)
    let count = context.snapshot.pushups(on: context.date)
    switch family {
    case .accessoryCircular:
      Group {
        if context.unlocked {
          Gauge(value: Double(min(count, goal)), in: 0...Double(goal)) {
            Image(systemName: "figure.strengthtraining.traditional")
          } currentValueLabel: {
            Text(String(count)).font(.grotesk(18))
          }
          .gaugeStyle(.accessoryCircularCapacity)
        } else {
          LockedAccessory()
        }
      }
      .clearBackground()
    case .accessoryRectangular:
      HStack(spacing: 6) {
        if !context.unlocked {
          Image(systemName: "lock.fill").font(.system(size: 16, weight: .bold))
        }
        VStack(alignment: .leading, spacing: 1) {
          Text(verbatim: "PUSHUP BRO")
            .font(.system(size: 11, weight: .bold))
            .opacity(0.8)
          Text(rectangularMessage(context: context, count: count, goal: goal))
            .font(.system(size: 15, weight: .bold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
        }
        Spacer(minLength: 0)
      }
      .clearBackground()
    default:
      Group {
        if context.unlocked {
          small(context: context, count: count, goal: goal)
        } else {
          LockedView(context: context)
        }
      }
      .surfaceBackground(context.palette)
    }
  }

  private func rectangularMessage(context: EntryContext, count: Int, goal: Int) -> String {
    if !context.unlocked { return context.l10n("locked.title") }
    if count >= goal { return context.l10n("today.goalDone") }
    return context.l10n.format("today.toGo", goal - count)
  }

  private func small(context: EntryContext, count: Int, goal: Int) -> some View {
    let palette = context.palette
    return ZStack(alignment: .topLeading) {
      // His face is at the art's right edge, so he stays fully inside the
      // widget, tucked into the corner past the rounded edge.
      Image("CarlosPushup")
        .resizable()
        .scaledToFit()
        .frame(width: 100)
        .padding(.trailing, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
      VStack(alignment: .leading, spacing: 0) {
        Caption(text: context.l10n("today.label"), color: palette.muted)
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          Text(String(count))
            .font(.grotesk(34))
            .foregroundStyle(palette.text)
          Text(" / " + String(goal))
            .font(.grotesk(16))
            .foregroundStyle(palette.muted)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .padding(.top, 4)
        ProgressBar(
          value: Double(count) / Double(goal), fill: palette.jungle, track: palette.track
        )
        .frame(width: 72, height: 6)
        .padding(.top, 8)
      }
      .padding(14)
    }
  }
}

struct TodayWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PushupBroToday", provider: SnapshotProvider()) { entry in
      TodayView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("gallery.today.name"))
    .description(LocalizedStringKey("gallery.today.description"))
    .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    .contentMarginsDisabled()
  }
}

// MARK: - Jungle Trek

struct TrekView: View {
  @Environment(\.colorScheme) private var scheme
  let entry: SnapshotEntry

  var body: some View {
    let context = EntryContext(entry: entry, scheme: scheme)
    Group {
      if context.unlocked {
        content(context: context)
      } else {
        LockedView(context: context)
      }
    }
    .surfaceBackground(context.palette)
  }

  private func content(context: EntryContext) -> some View {
    let palette = context.palette
    let l10n = context.l10n
    let trek = context.snapshot.trek
    let done = trek?.allCleared ?? false
    let stageTitle: String? = trek.flatMap { stage -> String? in stage.title.isEmpty ? nil : stage.title }
    return HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Caption(text: l10n(done ? "trek.labelDone" : "trek.label"), color: palette.jungle)
        Text(done ? l10n("trek.allClearedTitle") : stageTitle ?? l10n("trek.labelDone"))
          .font(.grotesk(22))
          .foregroundStyle(palette.text)
          .lineLimit(2)
          .minimumScaleFactor(0.7)
        Text(subtitle(trek: trek, l10n: l10n))
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(palette.muted)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 4)
        HStack(spacing: 6) {
          Image(systemName: done ? "arrow.counterclockwise" : "play.fill")
            .font(.system(size: 10, weight: .bold))
          Text(l10n(done ? "trek.replay" : "trek.fight"))
            .font(.system(size: 13, weight: .bold))
            .lineLimit(1)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(Capsule().fill(palette.red))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      ZStack(alignment: .bottom) {
        LinearGradient(
          colors: [Color(hex: 0x63C96E), Color(hex: 0x2F8B57)], startPoint: .top,
          endPoint: .bottom)
        Image("Komo")
          .resizable()
          .scaledToFit()
          .frame(height: 118)
      }
      .frame(width: 126)
      .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
    .padding(16)
  }

  private func subtitle(trek: WidgetTrek?, l10n: L10n) -> String {
    guard let trek = trek else { return "" }
    if trek.allCleared { return l10n("trek.allClearedHint") }
    if trek.boss { return l10n.format("trek.stageBoss", trek.stageNumber) }
    if trek.waves == 1 { return l10n.format("trek.stageWave", trek.stageNumber) }
    return l10n.format("trek.stageWaves", trek.stageNumber, trek.waves)
  }
}

struct TrekWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PushupBroTrek", provider: SnapshotProvider()) { entry in
      TrekView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("gallery.trek.name"))
    .description(LocalizedStringKey("gallery.trek.description"))
    .supportedFamilies([.systemMedium])
    .contentMarginsDisabled()
  }
}

// MARK: - This week

struct WeekView: View {
  @Environment(\.colorScheme) private var scheme
  let entry: SnapshotEntry

  var body: some View {
    let context = EntryContext(entry: entry, scheme: scheme)
    Group {
      if context.unlocked {
        content(context: context)
      } else {
        LockedView(context: context)
      }
    }
    .surfaceBackground(context.palette)
  }

  private func content(context: EntryContext) -> some View {
    let palette = context.palette
    let l10n = context.l10n
    let week = context.snapshot.week(endingOn: context.date)
    let total = week.reduce(0) { $0 + $1.pushups }
    let activeDays = week.filter { $0.pushups > 0 }.count
    let most = max(week.map { $0.pushups }.max() ?? 0, 1)
    return VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 0) {
          Caption(text: l10n("week.label"), color: palette.muted)
          Text(total == 1 ? l10n("week.totalOne") : l10n.format("week.total", total))
            .font(.grotesk(30))
            .foregroundStyle(palette.text)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        Spacer(minLength: 8)
        HStack(spacing: 3) {
          Image("Banana")
            .resizable()
            .scaledToFit()
            .frame(width: 22, height: 22)
          Text(String(context.snapshot.bananas))
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(palette.text)
            .lineLimit(1)
        }
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .frame(height: 30)
        .background(Capsule().fill(palette.banana.opacity(0.22)))
      }
      GeometryReader { geometry in
        let tallest = max(geometry.size.height - 44, 8)
        HStack(alignment: .bottom, spacing: 10) {
          ForEach(0..<week.count, id: \.self) { index in
            let day = week[index]
            VStack(spacing: 6) {
              Text(day.pushups == 0 ? "·" : String(day.pushups))
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(barColor(day, palette: palette))
                .frame(height: max(8, tallest * CGFloat(day.pushups) / CGFloat(most)))
              Text(l10n.weekdayLetter(day.date))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(day.isToday ? palette.text : palette.muted)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
      }
      HStack(spacing: 10) {
        Image(systemName: "checkmark")
          .font(.system(size: 11, weight: .heavy))
          .foregroundStyle(palette.jungle)
          .frame(width: 24, height: 24)
          .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .fill(palette.jungle.opacity(0.18)))
        Text(l10n.format("week.activeDays", activeDays))
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(palette.text)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous).fill(palette.background))
    }
    .padding(16)
  }

  private func barColor(_ day: DayCount, palette: Palette) -> Color {
    if day.isToday { return palette.orange }
    return day.pushups == 0 ? palette.track : palette.accent
  }
}

struct WeekWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "PushupBroWeek", provider: SnapshotProvider()) { entry in
      WeekView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("gallery.week.name"))
    .description(LocalizedStringKey("gallery.week.description"))
    .supportedFamilies([.systemLarge])
    .contentMarginsDisabled()
  }
}

// MARK: - Bundle

@main
struct PushupBroWidgets: WidgetBundle {
  var body: some Widget {
    StreakWidget()
    TodayWidget()
    TrekWidget()
    WeekWidget()
  }
}
