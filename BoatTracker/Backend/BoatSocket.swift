import Foundation
import SwiftUI

protocol BoatSocketDelegate {
  func onCoords(event: CoordsData) async
}

protocol VesselDelegate {
  func on(vessels: [Vessel]) async
}

extension BoatSocket: WebSocketMessageDelegate {
  func on(isConnected: Bool) async {
    await update(isConnected: isConnected)
  }

  @MainActor
  private func update(isConnected: Bool) {
    self.isConnected = isConnected
  }

  func on(message: String) async {
    do {
      guard let json = message.data(using: .utf8) else {
        throw JsonError.invalid("Not JSON.", message)
      }
      await onMessage(json: json)
    } catch {
      log.warn("Not JSON: '\(message)'.")
    }
  }
}

class BoatSocket {
  private let log = LoggerFactory.shared.network(BoatSocket.self)

  private let baseUrl: URL

  private var socket: WebSocket? = nil

  // Delegate for the map view
  var delegate: BoatSocketDelegate? = nil
  // Delegate for the profile page with a summary view of the current track
  var statsDelegate: BoatSocketDelegate? = nil
  var vesselDelegate: VesselDelegate? = nil

  @Published var isConnected: Bool = false

  init(_ baseUrl: URL) {
    self.baseUrl = baseUrl
  }

  private func open() {
    if let socket = socket {
      log.info("Opening socket to \(socket.baseURL.absoluteString)...")
      socket.connect()
    } else {
      log.warn("Opening non-existing socket? Seems like a user error.")
    }
  }

  func reconnect(token: AccessToken?, track: TrackName?) {
    close()
    prep(token: token, track: track)
    open()
  }

  private func prep(token: AccessToken?, track: TrackName?) {
    var headers: [String: String] = [:]
    if let token = token {
      headers = [
        Headers.authorization: "bearer \(token)",
        Headers.accept: BoatHttpClient.BoatVersion,
      ]
    } else {
      headers = [
        Headers.accept: BoatHttpClient.BoatVersion
      ]
    }
    let trackQuery = track.map { "?track=\($0.name)" } ?? ""
    let url = URL(string: "/ws/updates\(trackQuery)", relativeTo: baseUrl)!
    //        log.info("Opening socket with \(track?.name ?? "no track") and token \(token?.token ?? "no token")")
    socket = WebSocket(baseURL: url, headers: headers)
    socket?.delegate = self
  }

  func updateToken(token: AccessToken?) {
    socket?.updateAuthHeader(newValue: token.map(BoatHttpClient.authValue))
  }

  func onMessage(json: Data) async {
    let decoder = JSONDecoder()
    do {
      let event = try decoder.decode(BoatEvent.self, from: json)
      // log.info("Got \(event)")
      switch event.event {
      case "ping":
        ()
      case "coords":
        let data = try decoder.decode(CoordsBody.self, from: json)
        if let delegate = delegate {
          // log.info("Passing \(data.body.coords.count) coords to delegate.")
          await delegate.onCoords(event: data.body)
        } else {
          log.warn("No delegate for coords. This is probably an error.")
        }
        if let delegate = statsDelegate {
          await delegate.onCoords(event: data.body)
        }
      case "vessels":
        let data = try decoder.decode(VesselsBody.self, from: json)
        if let vesselDelegate = vesselDelegate {
          await vesselDelegate.on(vessels: data.body.vessels)
        }
      case "loading":
        ()
      case "noData":
        ()
      default:
        log.info("Unknown event: '\(event)'.")
      }
    } catch DecodingError.typeMismatch(let t, let ctx) {
      log.info(
        "Type mismatch: '\(t) with context \(ctx)'. \(ctx.debugDescription)")
    } catch DecodingError.keyNotFound(let key, let ctx) {
      log.info(
        "Key not found: '\(key)' with context '\(ctx)'. \(ctx.debugDescription)"
      )
    } catch DecodingError.valueNotFound(let t, let ctx) {
      log.info(
        "Value not found in type: \(t) with context: '\(ctx)'. \(ctx.debugDescription)"
      )
    } catch DecodingError.dataCorrupted(let ctx) {
      log.info("Data corrupted with context: 'ctx'. \(ctx.debugDescription)")
    } catch {
      if case JsonError.missing(let key) = error {
        log.error("Missing: \(key)")
      } else if case JsonError.invalid(let msg, let value) = error {
        log.error("\(msg) with value \(value)")
      } else {
        log.info("Unknown JSON.")
      }
    }
  }

  func send<T: Encodable>(t: T) -> SingleError? {
    guard let asString = try? Json.shared.stringify(t) else {
      return failWith("Unable to send data, cannot stringify payload.")
    }
    let isSuccess = socket?.send(asString) ?? false
    return isSuccess
      ? nil : SingleError(message: "Failed to send message over socket.")
  }

  func failWith(_ message: String) -> SingleError {
    log.error(message)
    return SingleError(message: message)
  }

  func close() {
    socket?.disconnect()
  }
}

struct BoatEvent: Codable {
  let event: String
}
