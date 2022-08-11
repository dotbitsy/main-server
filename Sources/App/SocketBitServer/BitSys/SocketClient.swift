//
//  File.swift
//  
//
//  Created by Ω on 7/22/22.
//
import Vapor
import Foundation

open class SocketClient {
    
    
    enum ClientError: Error {
        case send
    }

    open var id: UUID
    open var socket: WebSocket
    
    private var encoder: JSONEncoder = {
        JSONEncoder()
    }()

    func encode<T: Codable>(data: T) -> Data? {
        try? encoder.encode(data)
    }
    
    func send<T: Codable>(data: T) async throws {
        guard let bits = encode(data: data)
        else { throw ClientError.send }
        try await socket.send([UInt8](bits))
    }
    
    init(id: UUID, socket: WebSocket) {
        self.id = id
        self.socket = socket
    }
}

open class SocketClients<T: SocketClient> {
    var eventloop: EventLoop
    var storage: [UUID: T]
    var active: [T] {
        storage.values.filter{ !$0.socket.isClosed }
    }
    
    init(eventloop: EventLoop, storage: [UUID: T] = [:]) {
        self.eventloop = eventloop
        self.storage = storage
    }
    
    func add(_ client: T) {
        storage[client.id] = client
    }
    
    func remove(_ client: T) {
        storage[client.id] = nil
    }
    
    func find(_ uuid: UUID) -> T? {
        storage[uuid]
    }
    
    func send<T: Codable>(data: T) async {
        await active.asyncForEach { try? await $0.send(data: data) }
    }
    
    deinit {
        let futures = storage.values.map { $0.socket.close() }
        try! eventloop.flatten(futures).wait()
    }
}
