import Foundation

extension Data {
    // thanks Martin, http://codereview.stackexchange.com/a/86613
    func hexString() -> String {
        // "Array" of all bytes
        let bytes = UnsafeBufferPointer<UInt8>(start: (self as NSData).bytes.bindMemory(to: UInt8.self, capacity: self.count), count: self.count)
        // Array of hex strings, one for each byte
        let hexBytes = bytes.map { String(format: "%02hhx", $0) }
        // Concatenates all hex strings
        return hexBytes.joined(separator: "")
    }
}
