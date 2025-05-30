import Foundation
import SwiftUI

struct TrophyInfo {
  let name: BoatName
  let speed: Speed
  let dateTime: String
  let outsideTemp: Temperature?
  let altitude: Distance?
  let isBoat: Bool

  static func fromPoint(trophyPoint: TrophyPoint) -> TrophyInfo {
    return TrophyInfo(
      name: trophyPoint.from.boatName,
      speed: trophyPoint.top.speed, dateTime: trophyPoint.top.time.dateTime,
      outsideTemp: trophyPoint.top.outsideTemp, altitude: trophyPoint.top.altitude,
      isBoat: trophyPoint.isBoat)
  }
}

struct TrophyView: View {
  let info: TrophyInfo
  let lang: Lang

  func tempItem() -> InfoItem? {
    guard let temp = info.outsideTemp else { return nil }
    return InfoItem(lang.track.temperature, temp.description)
  }

  func altitudeItem() -> InfoItem? {
    guard let altitude = info.altitude else { return nil }
    return InfoItem(lang.track.env.altitude, altitude.formatMeters)
  }

  func boatNameItem() -> InfoItem {
    return InfoItem(lang.settings.boat, info.name.name)
  }

  var body: some View {
    InfoView(
      title: info.speed.formatted(isBoat: info.isBoat),
      items: [boatNameItem()] + tempItem().toList + altitudeItem().toList, footer: info.dateTime,
      leftColumnSize: .fixed(120))
  }
}

struct MinimalMarkView: View {
  let info: MinimalMarineSymbol
  let lang: Lang
  let finnishWords: SpecialWords
  var markLang: MarkLang { lang.mark }
  var language: Language { lang.language }

  func markItem() -> InfoItem? {
    guard let mark = info.trafficMarkType else { return nil }
    return InfoItem(markLang.markType, mark.translate(lang: lang.limits.types))
  }
  func speedItem() -> InfoItem? {
    guard let speed = info.speedLimit else { return nil }
    return InfoItem(lang.limits.magnitude, speed.formattedKph)
  }
  func locationView() -> InfoItem? {
    guard let location = info.location(lang: language), info.hasLocation else { return nil }
    return InfoItem(markLang.location, location.value)
  }
  func items() -> [InfoItem] {
    markItem().toList + speedItem().toList + locationView().toList + [
      InfoItem(
        markLang.owner, info.translatedOwner(finnish: finnishWords, translated: lang.specialWords))
    ]
  }
  var body: some View {
    InfoView(title: info.name(lang: language)?.value, items: items(), leftColumnSize: .fixed(80))
  }
}

struct MarkView: View {
  let info: MarineSymbol
  let lang: Lang
  var language: Language { lang.language }
  var markLang: MarkLang { lang.mark }
  let finnishWords: SpecialWords
  var hasConstruction: Bool { info.construction != nil }
  var hasLocation: Bool { info.hasLocation }
  var hasNav: Bool { info.navMark != .notApplicable }

  func items() -> [InfoItem] {
    [InfoItem(markLang.aidType, info.aidType.translate(lang: markLang.aidTypes))]
      + constructionItem().toList + navItem().toList + locationItem().toList + [
        InfoItem(
          markLang.owner, info.translatedOwner(finnish: finnishWords, translated: lang.specialWords)
        )
      ]
  }
  func constructionItem() -> InfoItem? {
    guard let construction = info.construction else { return nil }
    return InfoItem(markLang.construction, construction.translate(lang: markLang.structures))
  }
  func navItem() -> InfoItem? {
    guard hasNav else { return nil }
    return InfoItem(markLang.navigation, info.navMark.translate(lang: markLang.navTypes))
  }
  func locationItem() -> InfoItem? {
    guard let location = info.location(lang: language), info.hasLocation else { return nil }
    return InfoItem(markLang.location, location.value)
  }

  var body: some View {
    InfoView(title: info.name(lang: language)?.value, items: items(), leftColumnSize: .fixed(80))
  }
}

struct LimitView: View {
  let limit: LimitArea
  let lang: Lang

  let columns = [GridItem(.fixed(120)), GridItem(.flexible())]

  func items() -> [InfoItem] {
    [
      InfoItem(
        lang.limits.limit,
        limit.types.map { $0.translate(lang: lang.limits.types) }.joined(separator: ", "))
    ] + speedItem().toList + fairwayItem().toList
  }

  func speedItem() -> InfoItem? {
    guard let speed = limit.limit else { return nil }
    return InfoItem(lang.limits.magnitude, speed.formattedKph)
  }
  func fairwayItem() -> InfoItem? {
    guard let fairway = limit.fairwayName else { return nil }
    return InfoItem(lang.limits.fairwayName, fairway.value)
  }

  var body: some View {
    VStack {
      LazyVGrid(columns: columns, alignment: .leading, spacing: margin.small) {
        Text(lang.limits.limit)
          .font(.subheadline)
        VStack(alignment: .leading) {
          ForEach(limit.types, id: \.hashValue) { l in
            Text(l.translate(lang: lang.limits.types))
          }
        }
      }
    }
  }
}

struct BoatView: View {
  let info: BoatPoint
  var from: TrackRef { info.from }
  let lang: Lang

  func items() -> [InfoItem] {
    if let trackTitle = from.trackTitle {
      return [InfoItem(lang.name, trackTitle.title)]
    } else {
      return []
    }
  }

  var body: some View {
    InfoView(
      title: from.boatName.name, items: items(), footer: info.coord.time.dateTime,
      leftColumnSize: .fixed(80))
  }
}

struct VesselView: View {
  let vessel: Vessel
  let lang: Lang

  func items() -> [InfoItem] {
    destinationItem().toList + [InfoItem(lang.track.speed, vessel.speed.formattedKnots)] + [
      InfoItem(lang.ais.draft, vessel.draft.formatMeters)
    ]
  }

  func destinationItem() -> InfoItem? {
    guard let destination = vessel.destination else { return nil }
    return InfoItem(lang.ais.destination, destination)
  }

  var body: some View {
    InfoView(
      title: vessel.name, items: items(), footer: vessel.time.dateTime, leftColumnSize: .fixed(100))
  }
}

struct AreaView: View {
  let info: FairwayArea
  let limit: LimitArea?
  let lang: Lang
  var fairwayLang: FairwayLang { lang.fairway }

  func markItem() -> InfoItem? {
    guard let markType = info.markType else { return nil }
    return InfoItem(lang.mark.markType, markType.translate(lang: lang.mark.types))
  }
  func limitItems() -> [InfoItem] {
    guard let limit = limit else { return [] }
    return LimitView(limit: limit, lang: lang).items()
  }

  func items() -> [InfoItem] {
    [
      InfoItem(fairwayLang.fairwayType, info.fairwayType.translate(lang: fairwayLang.types)),
      InfoItem(fairwayLang.fairwayDepth, info.fairwayDepth.formatMeters),
      InfoItem(fairwayLang.harrowDepth, info.harrowDepth.formatMeters),
    ] + markItem().toList + limitItems()
  }

  var body: some View {
    InfoView(title: info.owner, items: items(), leftColumnSize: .fixed(limit != nil ? 100 : 80))
  }
}

struct TrailView: View {
  let info: TrackPoint
  let lang: Lang
  var coord: CoordBody { info.start }  // we use the start coord arbitrarily, close enough, could be end coord just as well

  func altitudeItem() -> InfoItem? {
    guard let altitude = coord.altitude else { return nil }
    return InfoItem(lang.track.env.altitude, altitude.formatMeters)
  }

  func temperatureItem() -> InfoItem? {
    guard let outsideTemp = coord.outsideTemp else { return nil }
    return InfoItem(lang.track.temperature, outsideTemp.formatCelsius)
  }

  func items() -> [InfoItem] {
    [
      InfoItem(lang.track.speed, info.avgSpeed.formatted(isBoat: info.isBoat))
    ] + temperatureItem().toList + altitudeItem().toList
  }

  var body: some View {
    InfoView(title: info.boatName.name, items: items(), footer: info.start.time.dateTime)
  }
}

struct TrailPointView: View {
  let info: SingleTrackPoint
  let lang: Lang
  var coord: CoordBody { info.point }  // we use the start coord arbitrarily, close enough, could be end coord just as well

  func altitudeItem() -> InfoItem? {
    guard let altitude = coord.altitude else { return nil }
    return InfoItem(lang.track.env.altitude, altitude.formatMeters)
  }

  func temperatureItem() -> InfoItem? {
    guard let outsideTemp = coord.outsideTemp else { return nil }
    return InfoItem(lang.track.temperature, outsideTemp.formatCelsius)
  }

  func items() -> [InfoItem] {
    [
      InfoItem(lang.track.speed, info.avgSpeed.formatted(isBoat: info.isBoat))
    ] + temperatureItem().toList + altitudeItem().toList
  }

  var body: some View {
    InfoView(
      title: info.boatName.name, items: items(), footer: info.point.time.dateTime,
      leftColumnSize: .fixed(100))
  }
}

struct InfoItem {
  let key, value: String

  init(_ key: String, _ value: String) {
    self.key = key
    self.value = value
  }
}

struct InfoView: View {
  let title: String?
  let items: [InfoItem]
  let footer: String?
  let leftColumnSize: GridItem.Size
  let gridAlignment: HorizontalAlignment

  init(
    title: String? = nil, items: [InfoItem] = [], footer: String? = nil,
    leftColumnSize: GridItem.Size = .flexible(), gridAlignment: HorizontalAlignment = .leading
  ) {
    self.title = title
    self.items = items
    self.footer = footer
    self.leftColumnSize = leftColumnSize
    self.gridAlignment = gridAlignment
  }

  var columns: [GridItem] { [GridItem(leftColumnSize), GridItem(.flexible(minimum: 140))] }

  var body: some View {
    VStack {
      if let title = title {
        Text(title)
          .font(.headline)
      }
      if !items.isEmpty {
        LazyVGrid(columns: columns, alignment: gridAlignment, spacing: margin.small) {
          ForEach(items, id: \.key) { item in
            /*@START_MENU_TOKEN@*/Text(item.key) /*@END_MENU_TOKEN@*/
              .font(.subheadline)
            Text(item.value)
              .lineLimit(nil)
          }
        }
      } else {
        Spacer().frame(height: margin.small)
      }
      if let footer = footer {
        Text(footer)
          .font(.subheadline)
      }
    }
    .padding(.all)
  }
}
