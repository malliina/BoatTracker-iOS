import Foundation
import MapboxMaps

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
    
    func onTap(point: CGPoint) async -> CustomAnnotation? {
        // Preference: boats > ais > trophy > marks > fairway info > limits
        // Fairway info includes any limits
        let boat = await handleBoatTap(point)
        guard boat == nil else { return boat }
        let ais = await handleAisTap(point)
        guard ais == nil else { return ais }
        let trophy = await handleTrophyTap(point)
        guard trophy == nil else { return trophy }
        let mark = await handleMarksTap(point)
        guard mark == nil else { return mark }
        let area = await handleAreaTap(point)
        guard area == nil else { return area }
        return await handleLimitsTap(point)
    }
    
    private func handleMarksTap(_ point: CGPoint) async -> CustomAnnotation? {
        let features = (try? await queryFeatures(at: point, layerIds: Array(marksLayers))) ?? []
        guard let coordinate = self.markCoordinate(features.first) else {
            self.log.warn("No coordinate for mark feature.")
            return nil
        }
        return features.first.flatMap { feature in
            let props = feature.feature.properties ?? [:]
            let full: MarkAnnotation? = (try? Json.shared.parse(MarineSymbol.self, from: props)).map { symbol in
                MarkAnnotation(mark: symbol, coord: coordinate)
            }
            let minimal: MinimalMarkAnnotation? = (try? Json.shared.parse(MinimalMarineSymbol.self, from: props)).map { symbol in
                MinimalMarkAnnotation(mark: symbol, coord: coordinate)
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
    
    private func handleBoatTap(_ point: CGPoint) async -> CustomAnnotation? {
        let boatLayers = boats.layers()
        if !boatLayers.isEmpty {
            let result = await queryVisibleFeatureProps(point, layers: Array(boats.layers()), t: BoatPoint.self)
            return result.map { boatPoint in
                BoatAnnotation(info: boatPoint)
            }
        } else {
            return nil
        }
    }
    
    private func handleTrophyTap(_ point: CGPoint) async -> CustomAnnotation? {
        let layers = boats.trophyLayers()
        if !layers.isEmpty {
            let result = await queryVisibleFeatureProps(point, layers: Array(boats.trophyLayers()), t: TrophyPoint.self)
            return result.map { point in
                TrophyAnnotation(top: point.top)
            }
        } else {
            return nil
        }
    }
    
    private func handleAisTap(_ point: CGPoint) async -> CustomAnnotation? {
        // Limits feature selection to just the following layer identifiers
        let result = await queryVisibleFeatureProps(point, layers: Array(aisLayers), t: VesselProps.self)
        guard let props = result, let ais = self.ais else { return nil }
        return ais.info(props.mmsi).map { vessel in
            VesselAnnotation(vessel: vessel)
        }
    }
    
    @MainActor
    private func handleAreaTap(_ point: CGPoint) async -> CustomAnnotation? {
        let result1 = await queryVisibleFeatureProps(point, layers: layers.fairwayAreas, t: FairwayArea.self)
        let result2 = await queryLimitAreaInfo(point)
        if let area = result1 {
            let coord = mapView.mapboxMap.coordinate(for: point)
            return FairwayAreaAnnotation(info: area, limits: result2, coord: coord)
        } else {
            return nil
        }
    }
    
    @MainActor
    private func handleLimitsTap(_ point: CGPoint) async -> CustomAnnotation? {
        let result = await queryLimitAreaInfo(point)
        return result.map { area in
            return LimitAnnotation(limit: area, coord: mapView.mapboxMap.coordinate(for: point))
        }
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
                return try Json.shared.parse(t, from: props)
            }
        } catch let error {
            self.log.warn("Failed to parse props. \(error)")
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
