import Foundation

protocol MapDelegate {
    func close()
}

class MapEvents {
    static let shared = MapEvents()
    
    var reconnectOnActive: Bool = true
    var delegate: MapDelegate? = nil
    
    func onBackground() {
        close()
        reconnectOnActive = true
    }
    
    func onForeground() -> Bool {
        let old = reconnectOnActive
        reconnectOnActive = false
        return old
    }
    
    func close() {
        delegate?.close()
    }
}
