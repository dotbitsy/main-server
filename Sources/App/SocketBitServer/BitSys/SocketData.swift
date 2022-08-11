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


struct Connect: Codable {
    let connect: Bool
}

struct BitData: Codable {
    let data: String
}

struct Bit: Codable {
    let state: Bool
}

struct Byte: Codable {
    let bytes: [Bit]
}

struct BitID: Codable {
    let name: String
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
