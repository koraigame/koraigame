// Copyright 2021 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@objc enum ReviewOrder: UInt, Codable, CustomStringConvertible {
  case random = 1
  case ascendingSRSStage = 2
  case currentLevelFirst = 3
  case lowestLevelFirst = 4
  case newestAvailableFirst = 5
  case oldestAvailableFirst = 6
  case descendingSRSStage = 7
  case longestRelativeWait = 8

  var description: String {
    switch self {
    case .random: return "Random"
    case .ascendingSRSStage: return "Ascending SRS stage"
    case .descendingSRSStage: return "Descending SRS stage"
    case .currentLevelFirst: return "Current level first"
    case .lowestLevelFirst: return "Lowest level first"
    case .newestAvailableFirst: return "Newest available first"
    case .oldestAvailableFirst: return "Oldest available first"
    case .longestRelativeWait: return "Longest relative wait"
    }
  }
}

@objc enum InterfaceStyle: UInt, Codable, CustomStringConvertible {
  case system = 1
  case light = 2
  case dark = 3

  var description: String {
    switch self {
    case .system: return "System"
    case .light: return "Light"
    case .dark: return "Dark"
    }
  }
}

struct S<T: Codable> {
  static func set(_ object: T, _ key: String) {
    var data: Data!
    if #available(iOS 11.0, *) {
      data = try! NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
    } else {
      data = NSKeyedArchiver.archivedData(withRootObject: object)
    }
    UserDefaults.standard.set(data, forKey: key)
  }

  private static func halt(_ defaultValue: T, _ key: String, _ fatalCrash: Bool = false) -> T {
    print("Begin recovery attempt.")
    set(defaultValue, key)
    print("Set default value of \(defaultValue) to \(key).")
    if !fatalCrash { return get(defaultValue, key, true) }
    else { fatalError("Recovery attempt for \(key) failed.") }
  }

  private static func recoverFailedData(_ defaultValue: T, _ key: String,
                                        _ fatalCrash: Bool = false) -> T {
    if let value = UserDefaults.standard.object(forKey: key) {
      if let zero = value as? Float {
        if zero == 0 { return halt(defaultValue, key, fatalCrash) }
      }
      if let unencoded = value as? T {
        set(unencoded, key)
        return unencoded
      }
    }
    return halt(defaultValue, key, fatalCrash)
  }

  private static func get(_ defaultValue: T, _ key: String, _ fatalCrash: Bool = false) -> T {
    // Decode value if obtainable and return it
    guard let data = UserDefaults.standard.data(forKey: key) else {
      return recoverFailedData(defaultValue, key, fatalCrash)
    }
    if (data as NSData).length == 0 { print("Warning: Zero length reading of \(key)") }
    var unstableT: T?
    if #available(iOS 11.0, *) {
      unstableT = (try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)) as? T
    } else {
      unstableT = NSKeyedUnarchiver.unarchiveObject(with: data) as? T
    }
    let ret = unstableT ?? defaultValue
    if unstableT == nil { set(defaultValue, key) }
    return ret
  }

  static func get(_ defaultValue: T, _ key: String) -> T {
    return get(defaultValue, key, false)
  }
}

struct E<T: RawRepresentable> where T.RawValue: Codable {
  static func set(_ object: T, _ key: String) {
    S.set(object.rawValue, key)
  }

  static func get(_ defaultValue: T, _ key: String) -> T {
    return T(rawValue: S.get(defaultValue.rawValue, key))!
  }
}

struct A<T: Sequence, E: RawRepresentable> where T.Element == E, E.RawValue: Codable {
  private static func fromRawArray(_ values: [E.RawValue]) -> T {
    var ret = [E]()
    for value in values {
      ret.append(E(rawValue: value)!)
    }
    return ret as! T
  }

  private static func toRawArray(_ values: T) -> [E.RawValue] {
    var ret = [E.RawValue]()
    for value in values {
      ret.append(value.rawValue)
    }
    return ret
  }

  static func set(_ object: T, _ key: String) {
    S.set(toRawArray(object), key)
  }

  static func get(_ defaultValues: T, _ key: String) -> T {
    return fromRawArray(S.get(toRawArray(defaultValues), key))
  }
}

@objcMembers class Settings: NSObject {
  static var userCookie: String {
    get { return S.get("", #keyPath(userCookie)) }
    set(n) { S.set(n, #keyPath(userCookie)) }
  }

  static var userEmailAddress: String {
    get { return S.get("", #keyPath(userEmailAddress)) }
    set(n) { S.set(n, #keyPath(userEmailAddress)) }
  }

  static var userApiToken: String {
    get { return S.get("", #keyPath(userApiToken)) }
    set(n) { S.set(n, #keyPath(userApiToken)) }
  }

  static var interfaceStyle: InterfaceStyle {
    get { return E.get(InterfaceStyle.system, #keyPath(interfaceStyle)) }
    set(n) { E.set(n, #keyPath(interfaceStyle)) }
  }

  static var notificationsAllReviews: Bool {
    get { return S.get(false, #keyPath(notificationsAllReviews)) }
    set(n) { S.set(n, #keyPath(notificationsAllReviews)) }
  }

  static var notificationsBadging: Bool {
    get { return S.get(false, #keyPath(notificationsAllReviews)) }
    set(n) { S.set(n, #keyPath(notificationsBadging)) }
  }

  static var prioritizeCurrentLevel: Bool {
    get { return S.get(false, #keyPath(prioritizeCurrentLevel)) }
    set(n) { S.set(n, #keyPath(prioritizeCurrentLevel)) }
  }

  static var lessonOrder: [TKMSubject.TypeEnum] {
    get { return A.get([.radical, .kanji, .vocabulary], "lessonOrder") }
    set(n) { A.set(n, "lessonOrder") }
  }

  static var lessonBatchSize: Int {
    get { return S.get(5, #keyPath(lessonBatchSize)) }
    set(n) { S.set(n, #keyPath(lessonBatchSize)) }
  }

  static var showStatsSection: Bool {
    get { return S.get(true, #keyPath(showStatsSection)) }
    set(n) { S.set(n, #keyPath(showStatsSection)) }
  }

  static var alwaysShowArrow: Bool {
    get { return S.get(true, #keyPath(alwaysShowArrow)) }
    set(n) { S.set(n, #keyPath(alwaysShowArrow)) }
  }

  static var expandSubmitButton: Bool {
    get { return S.get(false, #keyPath(expandSubmitButton)) }
    set(n) { S.set(n, #keyPath(expandSubmitButton)) }
  }

  static var reviewOrder: ReviewOrder {
    get { return E.get(ReviewOrder.random, #keyPath(reviewOrder)) }
    set(n) { E.set(n, #keyPath(reviewOrder)) }
  }

  static var reviewBatchSize: Int {
    get { return S.get(5, #keyPath(reviewBatchSize)) }
    set(n) { S.set(n, #keyPath(reviewBatchSize)) }
  }

  static var apprenticeLessonsLimit: Int {
    get { return S.get(Int.max, #keyPath(apprenticeLessonsLimit)) }
    set(n) { S.set(n, #keyPath(apprenticeLessonsLimit)) }
  }

  static var groupMeaningReading: Bool {
    get { return S.get(false, #keyPath(groupMeaningReading)) }
    set(n) { S.set(n, #keyPath(groupMeaningReading)) }
  }

  static var meaningFirst: Bool {
    get { return S.get(true, #keyPath(meaningFirst)) }
    set(n) { S.set(n, #keyPath(meaningFirst)) }
  }

  static var showAnswerImmediately: Bool {
    get { return S.get(true, #keyPath(showAnswerImmediately)) }
    set(n) { S.set(n, #keyPath(showAnswerImmediately)) }
  }

  static var selectedFonts: Set<String> {
    get { return S.get([], #keyPath(selectedFonts)) }
    set(n) { S.set(n, #keyPath(selectedFonts)) }
  }

  static var fontSize: Float {
    get { return S.get(1.0, #keyPath(fontSize)) }
    set(n) { S.set(n, #keyPath(fontSize)) }
  }

  static var exactMatch: Bool {
    get { return S.get(false, #keyPath(exactMatch)) }
    set(n) { S.set(n, #keyPath(exactMatch)) }
  }

  static var ignoreTypos: Bool {
    get { return S.get(true, #keyPath(ignoreTypos)) }
    set(n) { S.set(n, #keyPath(ignoreTypos)) }
  }

  static var addSynonyms: Bool {
    get { return S.get(true, #keyPath(addSynonyms)) }
    set(n) { S.set(n, #keyPath(addSynonyms)) }
  }

  static var showOldMnemonic: Bool {
    get { return S.get(true, #keyPath(showOldMnemonic)) }
    set(n) { S.set(n, #keyPath(showOldMnemonic)) }
  }

  static var useKatakanaForOnyomi: Bool {
    get { return S.get(false, #keyPath(useKatakanaForOnyomi)) }
    set(n) { S.set(n, #keyPath(useKatakanaForOnyomi)) }
  }

  static var showSRSLevelIndicator: Bool {
    get { return S.get(false, #keyPath(showSRSLevelIndicator)) }
    set(n) { S.set(n, #keyPath(showSRSLevelIndicator)) }
  }

  static var showAllReadings: Bool {
    get { return S.get(false, #keyPath(showAllReadings)) }
    set(n) { S.set(n, #keyPath(showAllReadings)) }
  }

  static var autoSwitchKeyboard: Bool {
    get { return S.get(false, #keyPath(autoSwitchKeyboard)) }
    set(n) { S.set(n, #keyPath(autoSwitchKeyboard)) }
  }

  static var allowSkippingReviews: Bool {
    get { return S.get(false, #keyPath(allowSkippingReviews)) }
    set(n) { S.set(n, #keyPath(allowSkippingReviews)) }
  }

  static var minimizeReviewPenalty: Bool {
    get { return S.get(true, #keyPath(minimizeReviewPenalty)) }
    set(n) { S.set(n, #keyPath(minimizeReviewPenalty)) }
  }

  static var pausePartiallyCorrect: Bool {
    get { return S.get(false, #keyPath(pausePartiallyCorrect)) }
    set(n) { S.set(n, #keyPath(pausePartiallyCorrect)) }
  }
  
  static var ankiMode: Bool {
    get { return S.get(false, #keyPath(ankiMode)) }
    set(n) { S.set(n, #keyPath(ankiMode)) }
  }

  static var enableNoteEditing: Bool {
    get { return S.get(true, #keyPath(enableNoteEditing)) }
    set(n) { S.set(n, #keyPath(enableNoteEditing)) }
  }

  static var playAudioAutomatically: Bool {
    get { return S.get(false, #keyPath(playAudioAutomatically)) }
    set(n) { S.set(n, #keyPath(playAudioAutomatically)) }
  }

  static var installedAudioPackages: Set<String> {
    get { return S.get([], #keyPath(installedAudioPackages)) }
    set(n) { S.set(n, #keyPath(installedAudioPackages)) }
  }

  static var animateParticleExplosion: Bool {
    get { return S.get(true, #keyPath(animateParticleExplosion)) }
    set(n) { S.set(n, #keyPath(animateParticleExplosion)) }
  }

  static var animateLevelUpPopup: Bool {
    get { return S.get(true, #keyPath(animateLevelUpPopup)) }
    set(n) { S.set(n, #keyPath(animateLevelUpPopup)) }
  }

  static var animatePlusOne: Bool {
    get { return S.get(true, #keyPath(animatePlusOne)) }
    set(n) { S.set(n, #keyPath(animatePlusOne)) }
  }

  static var subjectCatalogueViewShowAnswers: Bool {
    get { return S.get(true, #keyPath(subjectCatalogueViewShowAnswers)) }
    set(n) { S.set(n, #keyPath(subjectCatalogueViewShowAnswers)) }
  }
}
