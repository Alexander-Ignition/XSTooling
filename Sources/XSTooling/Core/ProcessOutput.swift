import Foundation

public struct ProcessOutput: Equatable {
    /// Output bytes.
    public let data: Data

    /// A new process output.
    ///
    /// - Parameter data: Process output bytes.
    public init(data: Data) {
        self.data = data
    }
}

// MARK: - String decoding

extension ProcessOutput {

    /// Decoded UTF-8 string.
    public var string: String {
        string(strippingNewline: true)
    }

    public var lines: [String] {
        return string.split(separator: "\n").map { String($0) }
    }

    /// Decode output bytes to string.
    ///
    /// - Parameter strippingNewline: If true, newline characters are stripped from the result; otherwise, newline characters are preserved.
    /// - Returns: Decoded UTF-8 string.
    public func string(strippingNewline: Bool) -> String {
        let string = String(decoding: data, as: UTF8.self)

        if strippingNewline, string.hasSuffix("\n") {
            return String(string.dropLast())
        }
        return string
    }
}

// MARK: - JSON Decoding

extension ProcessOutput {
    /// Default JSON decoder.
    private static let decoder = JSONDecoder()

    public func decode<T>(
        _ type: T.Type
    ) throws -> T where T: Decodable {
        try decode(type, using: ProcessOutput.decoder)
    }

    public func decode<T>(
        _ type: T.Type,
        using decoder: JSONDecoder
    ) throws -> T where T: Decodable {
        try decoder.decode(type, from: data)
    }
}

// MARK: - String protocols

extension ProcessOutput: CustomStringConvertible {
    public var description: String { string }
}

extension ProcessOutput: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.data = Data(value.utf8)
    }
}
