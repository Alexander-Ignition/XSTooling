import Foundation

public struct ProcessError: Error, Equatable {
    public let status: Int32
    public let reason: Process.TerminationReason
    public let data: Data

    public init(status: Int32, reason: Process.TerminationReason, data: Data) {
        self.status = status
        self.reason = reason
        self.data = data
    }

    public var string: String {
        String(decoding: data, as: UTF8.self)
    }
}

extension ProcessError: CustomStringConvertible {
    public var description: String {
        "\(reasonDescription): \(status), \(string)"
    }

    private var reasonDescription: String {
        switch reason {
        case .exit:
            return "exit"
        case .uncaughtSignal:
            return "uncaught signal"
        @unknown default:
            return "unknown reason(\(reason.rawValue))"
        }
    }
}
