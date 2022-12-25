import Foundation
import MapboxMaps

enum TapResult {
    case trophy(info: TrophyInfo, at: CLLocationCoordinate2D)
    case limit(area: LimitArea, at: CLLocationCoordinate2D)
    case miniMark(info: MinimalMarineSymbol, at: CLLocationCoordinate2D)
    case mark(info: MarineSymbol, point: CGPoint, at: CLLocationCoordinate2D)
    case boat(info: BoatPoint)
    case vessel(info: Vessel)
    case area(info: FairwayArea, limit: LimitArea?)
}

struct Tapped {
    let source: UIView
    let point: CGPoint
    let result: TapResult
}

extension JSONObject {
    func parse<T: Decodable>(_ t: T.Type) throws -> T {
        try Json.shared.parse(t, from: self)
    }
    func parseOpt<T: Decodable>(_ t: T.Type) -> T? {
        try? parse(t)
    }
}

class TapListener {
    let log = LoggerFactory.shared.vc(TapListener.self)
    
    let mapView: MapView
    let layers: MapboxLayers
    let marksLayers: Set<String>
    let limitsLayers: Set<String>
    let aisLayers: Set<String>
    let ais: AISRenderer?
    let boats: BoatRenderer
    
    init(mapView: MapView, layers: MapboxLayers, ais: AISRenderer?, boats: BoatRenderer) {
        self.mapView = mapView
        self.layers = layers
        self.marksLayers = Set(layers.marks)
        self.limitsLayers = Set(layers.limits)
        self.aisLayers = [layers.ais.vessel, layers.ais.trail]
        self.ais = ais
        self.boats = boats
    }
    
    func onTap(point: CGPoint) async -> TapResult? {
        let boat = await handleBoat(point)
        guard boat == nil else { return boat }
        let ais = await handleAis(point)
        guard ais == nil else { return ais }
        let trophy = await handleTrophy(point)
        guard trophy == nil else { return trophy }
        let mark = await handleMarks(point)
        guard mark == nil else { return mark }
        let area = await handleArea(point)
        guard area == nil else { return area }
        return await handleLimits(point)
    }
    
    private func handleMarks(_ point: CGPoint) async -> TapResult? {
        let features = (try? await queryFeatures(at: point, layerIds: Array(marksLayers))) ?? []
//        log.info("Tapped \(features.count) mark features.")
        guard let coordinate = self.markCoordinate(features.first) else {
            log.warn("No coordinate for mark feature. Found \(features.count) features at \(point).")
            return nil
        }
        let point = await pointAt(coord: coordinate)
        return features.first.flatMap { feature in
            let props = feature.feature.properties ?? [:]
            let full: TapResult? = props.parseOpt(MarineSymbol.self).map { symbol in
                .mark(info: symbol, point: point, at: coordinate)
            }

            let minimal: TapResult? = props.parseOpt(MinimalMarineSymbol.self).map { symbol in
                .miniMark(info: symbol, at: coordinate)
            }
            return full ?? minimal
        }
    }
    
    private func markCoordinate(_ feature: QueriedFeature?) -> CLLocationCoordinate2D? {
        switch feature?.feature.geometry {
        case .point(let point): return point.coordinates
        default: return nil
        }
    }
    
    private func handleBoat(_ point: CGPoint) async -> TapResult? {
        let boatLayers = boats.layers()
        if !boatLayers.isEmpty {
            let result = await queryVisibleFeatureProps(point, layers: Array(boats.layers()), t: BoatPoint.self)
            return result.map { boatPoint in
                    .boat(info: boatPoint)
            }
        } else {
            return nil
        }
    }
    
    private func handleTrophy(_ point: CGPoint) async -> TapResult? {
        let layers = boats.trophyLayers()
        if !layers.isEmpty {
            let result = await queryVisibleFeatureProps(point, layers: Array(layers), t: TrophyPoint.self)
            return result.map { point in
                .trophy(info: TrophyInfo(speed: point.top.speed, dateTime: point.top.time.dateTime), at: point.top.coord)
            }
        } else {
            return nil
        }
    }
    
    private func handleAis(_ point: CGPoint) async -> TapResult? {
        // Limits feature selection to just the following layer identifiers
        let result = await queryVisibleFeatureProps(point, layers: Array(aisLayers), t: VesselProps.self)
        guard let props = result, let ais = self.ais else { return nil }
        return ais.info(props.mmsi).map { vessel in
                .vessel(info: vessel)
        }
    }
    
    @MainActor
    private func handleArea(_ point: CGPoint) async -> TapResult? {
        let areaInfo = await queryVisibleFeatureProps(point, layers: layers.fairwayAreas, t: FairwayArea.self)
        let limitInfo = await queryLimitAreaInfo(point)
        if let area = areaInfo {
            // let coord = mapView.mapboxMap.coordinate(for: point)
            return .area(info: area, limit: limitInfo)
        } else {
            return nil
        }
    }
    
    @MainActor
    private func handleLimits(_ point: CGPoint) async -> TapResult? {
        let result = await queryLimitAreaInfo(point)
        return result.map { area in
            return .limit(area: area, at: mapView.mapboxMap.coordinate(for: point))
        }
    }
    
    @MainActor
    private func pointAt(coord: CLLocationCoordinate2D) -> CGPoint {
        mapView.mapboxMap.point(for: coord)
    }
    
    private func queryLimitAreaInfo(_ point: CGPoint) async -> LimitArea? {
        let raw = await queryVisibleFeatureProps(point, layers: Array(limitsLayers), t: RawLimitArea.self)
        return try? raw?.validate()
    }
    
    func queryVisibleFeatureProps<T: Decodable>(_ point: CGPoint, layers: [String], t: T.Type) async -> T? {
        do {
            let features = try await queryFeatures(at: point, layerIds: layers)
            return try features.first.flatMap { feature in
                let props = feature.feature.properties ?? [:]
                return try props.parse(t)
            }
        } catch {
            log.warn("Failed to parse props. \(error)")
            return nil
        }
    }
    
    @MainActor
    func queryFeatures(at: CGPoint, layerIds: [String]) async throws -> [QueriedFeature] {
        return try await withCheckedThrowingContinuation { cont in
            mapView.mapboxMap.queryRenderedFeatures(with: at, options: RenderedQueryOptions(layerIds: layerIds, filter: nil)) { result in
                switch result {
                case .success(let features):
                    cont.resume(returning: features)
                case .failure(let error):
                    self.log.warn("Failed to query rendered features. \(error)")
                    cont.resume(throwing: error)
                }
            }
        }
    }
}
