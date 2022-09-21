//
//  File.swift
//  
//
//  Created by Ω on 7/22/22.
//
import Vapor
import Foundation

struct SocketData<T: Codable>: Codable {
    let client: UUID
    let data: T
}

extension ByteBuffer {
    func decodeSocketData<T: Codable>(type: T.Type) -> SocketData<T>? {
        return try? JSONDecoder().decode(SocketData<T>.self, from: self)
    }
}

extension Data {
    func decodeSocketData<T: Codable>(type: T.Type) -> SocketData<T>? {
        return try? JSONDecoder().decode(SocketData<T>.self, from: self)
    }
}

public enum BinaryBit: UInt8, CustomStringConvertible, CaseIterable, Codable {
    case one, zero
    public var description: String  {
        switch self {
        case .zero: return "0"
        case .one: return "1"
        }
    }
    public var bool: Bool  {
        switch self {
        case .zero: return false
        case .one: return true
        }
    }
    
    public static var random: BinaryBit {
        Bool.random() ? BinaryBit.one : BinaryBit.zero
    }
}

public enum QBit: Codable, CustomStringConvertible {
    case binary, quantum
    public var description: String  {
        switch self {
        case .binary: return "Binary"
        case .quantum: return "Quantum"
        }
    }
}

struct Connect: Codable {
    let connect: Bool
}

struct BitData: Codable {
    let data: String
}

struct SystemData: Codable {
    let systematic: String
}

struct Bit: Codable {
    let state: Bool
}

struct Byte: Codable {
    let bits: [Bit]
    
    public var crushed: String {
        let bits = bits.compactMap{ $0.state ? BinaryBit.one : BinaryBit.zero }.reduce("") { $0 + $1.description }
        return sequence(state: bits.startIndex) {
            index -> (idx: String.Index, nextIdx: String.Index)? in
            let prev = index
            return bits.formIndex(&index, offsetBy: 8, limitedBy: bits.endIndex) ? (prev, index) : nil
        }.reduce("") {
            guard let ø = UInt8(bits[$1.idx..<$1.nextIdx], radix: 2)
            else { return $0 + BinaryBit.random.description }
            return $0 + String(UnicodeScalar(ø))
        }
    }
    
    public var binaries: [BinaryBit] {
        bits.compactMap{ $0.state ? BinaryBit.one : BinaryBit.zero }
    }
    
    public var bitsy: String {
        binaries.reduce("") { $0 + $1.description }
    }
}

struct BitID: Codable {
    let name: String
}

struct Seed: Codable {
    let complexity: Int
    let output: String
    let raw: String
}

extension Sequence {
    func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}

public extension String {
    var quant: Bool {
        let reg = ".*[^A-Za-z0-9åäöÅÄÖ ].*"
        return range(of: reg, options: .regularExpression) != nil
    }
}

