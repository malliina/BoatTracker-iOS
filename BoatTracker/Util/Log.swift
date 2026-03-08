import AsyncAlgorithms
import Foundation
import os.log

class Logger {
  private let osLog: OSLog

  let subsystem: String
  let category: String
  let isLocalOnly: Bool
  
  private static var onEvent: ((LogEvent) -> Void)? = nil
  
  private static var events: AsyncStream<LogEvent> {
    AsyncStream(bufferingPolicy: .bufferingNewest(1000)) { continuation in
      onEvent = {
        continuation.yield($0)
      }
    }
  }
  
  static var logs: AsyncChunksOfCountOrSignalSequence<AsyncStream<LogEvent>, [LogEvent], AsyncTimerSequence<SuspendingClock>> {
    events.chunked(by: .repeating(every: .seconds(1)))
  }
  
  init(_ subsystem: String, category: String, isLocalOnly: Bool) {
    self.subsystem = subsystem
    self.category = category
    self.isLocalOnly = isLocalOnly
    self.osLog = OSLog(subsystem: subsystem, category: category)
  }

  func debug(_ message: String) {
    write(message, .debug)
  }

  func info(_ message: String) {
    write(message, .info)
  }

  func warn(_ message: String) {
    write(message, .default)
  }

  func error(_ message: String) {
    write(message, .error)
  }

  func write(_ message: String, _ level: OSLogType) {
    os_log("%@", log: osLog, type: level, message)
    if !isLocalOnly {
      let event = LogEvent(timestamp: Date.now, message: message, loggerName: category, threadName: Thread.current.threadName, level: toLogLevel(level), stackTrace: nil)
      if let onEvent = Logger.onEvent {
        onEvent(event)
      }
    }
  }
  
  private func toLogLevel(_ level: OSLogType) -> LogLevel {
    switch level {
    case .debug: return .debug
    case .default: return .warn
    case .info: return .info
    case .error: return .error
    case .fault: return .error
    default:
      return .info
    }
  }
}

class LoggerFactory {
  static let shared = LoggerFactory(packageName: "com.malliina.boat")

  let packageName: String

  init(packageName: String) {
    self.packageName = packageName
  }

  func network<Subject>(_ subject: Subject) -> Logger {
    return base("Network", category: subject)
  }

  func system<Subject>(_ subject: Subject) -> Logger {
    return base("System", category: subject)
  }

  func view<Subject>(_ subject: Subject) -> Logger {
    return base("Views", category: subject)
  }

  func vc<Subject>(_ subject: Subject) -> Logger {
    return base("ViewControllers", category: subject)
  }

  func boat<Subject>(_ subject: Subject) -> Logger {
    return base("Boat", category: subject)
  }

  func local<Subject>(_ subject: Subject) -> Logger {
    return baseCustom("Local", category: subject, isLocalOnly: true)
  }
  
  func base<Subject>(_ suffix: String, category: Subject) -> Logger {
    return baseCustom(suffix, category: category, isLocalOnly: false)
  }
  
  func baseCustom<Subject>(_ suffix: String, category: Subject, isLocalOnly: Bool) -> Logger {
    return Logger("\(packageName).\(suffix)", category: String(describing: category), isLocalOnly: isLocalOnly)
  }
}
