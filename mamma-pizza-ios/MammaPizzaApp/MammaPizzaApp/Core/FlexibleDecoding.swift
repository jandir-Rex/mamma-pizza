import Foundation

extension KeyedDecodingContainer {
    func flexDouble(_ key: Key) throws -> Double {
        if let d = try? decode(Double.self, forKey: key) { return d }
        if let s = try? decode(String.self, forKey: key), let d = Double(s) { return d }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "No es un número")
    }

    func flexInt(_ key: Key) throws -> Int {
        if let i = try? decode(Int.self, forKey: key) { return i }
        if let d = try? decode(Double.self, forKey: key) { return Int(d) }
        if let s = try? decode(String.self, forKey: key), let i = Int(s) { return i }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "No es un entero")
    }

    func flexString(_ key: Key) throws -> String {
        if let s = try? decode(String.self, forKey: key) { return s }
        if let i = try? decode(Int.self, forKey: key) { return String(i) }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "No es texto")
    }
}
