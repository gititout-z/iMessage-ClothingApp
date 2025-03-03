// MARK: - Logger.swift
import Foundation
import os.log

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

class Logger {
    static let shared = Logger()
    
    private let log: OSLog
    private let isDebugMode: Bool
    
    private init() {
        self.log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.clothingapp", category: "ClothingApp")
        
        #if DEBUG
        self.isDebugMode = true
        #else
        self.isDebugMode = false
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        if isDebugMode {
            log(level: .debug, message: message, file: file, function: function, line: line)
        }
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileURL = URL(fileURLWithPath: file)
        let fileName = fileURL.lastPathComponent
        
        let logMessage = "[\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log(.debug, log: log, "%{public}@", logMessage)
        case .info:
            os_log(.info, log: log, "%{public}@", logMessage)
        case .warning:
            os_log(.error, log: log, "%{public}@", logMessage)
        case .error:
            os_log(.fault, log: log, "%{public}@", logMessage)
        }
    }
}