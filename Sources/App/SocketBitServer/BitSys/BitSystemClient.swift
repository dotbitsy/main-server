//
//  File.swift
//  
//
//  Created by Ω on 7/22/22.
//
import Vapor
import Foundation

final class BitSystemClient: SocketClient {
    
    var name = ""
    
    public override init(id: UUID, socket: WebSocket) {
        super.init(id: id, socket: socket)
    }
}

final class BitSystemClients: SocketClients<BitSystemClient> {
    
   
    enum BitSysProcess {
        case refresh
        case data(WebSocket, ByteBuffer)
        case string(WebSocket, String)
    }
    
    private(set) var processing: ByteProcessing
    
    override init(eventloop: EventLoop, storage: [UUID : BitSystemClient] = [:]) {
        processing = ByteProcessing()
        super.init(eventloop: eventloop, storage: storage)
    }
    
 
    func update(type: BitSysProcess) async {
        switch type {
        case .refresh:
            storage = storage.filter { !$0.value.socket.isClosed }
        case .data(let ws, let buffer):
            await process(websocket: ws, with: buffer)
        case .string(let ws, let str):
            await process(websocket: ws, with: str)
        }
    }
    
    private func process(websocket ws:WebSocket, with buffer: ByteBuffer) async {
        if let msg = buffer.decodeSocketData(type: Connect.self) {
            let bit = await connect(uuid: msg.client, ws: ws)
            try? await bit.send(data: msg)
        } else if let msg = buffer.decodeSocketData(type: BitData.self) {
            await update(data: msg.data.data, client: msg.client)
        } else if let msg = buffer.decodeSocketData(type: Bit.self) {
            await update(state: msg.data.state, sender: msg.client)
        } else if let msg = buffer.decodeSocketData(type: SystemData.self) {
            await notify(data: msg.data.systematic, client: msg.client)
        } else if let msg = buffer.decodeSocketData(type: BitID.self) {
            guard let client = find(msg.client)
            else { return }
            client.name = msg.data.name
            await welcome(client: client)
        } else {
            print("[SS - Unknonw Buffer Data]")
        }
    }
    
    private func process(websocket ws:WebSocket, with str: String) async {
        if let data = str.data(using: .utf8) {
            if let msg = data.decodeSocketData(type: Bit.self) {
                await update(state: msg.data.state, sender: msg.client)
            } else if let msg = data.decodeSocketData(type: Connect.self) {
                let bit = await connect(uuid: msg.client, ws: ws)
                try? await bit.send(data: msg)
           }
        } else {
            print("[SS - Unknonw Data]")
        }
    }
    
    private func connect(uuid: UUID, ws: WebSocket) async -> BitSystemClient {
        let bit = BitSystemClient(id: uuid, socket: ws)
        add(bit)
        print("[ ADDING CLIENT] : ", bit.id)
        return bit
    }
    
    private func welcome(client: BitSystemClient) async {
        let data = SocketData(client: UUID(), data: SystemData(systematic: "Welcome: " + client.name))
        try? await client.send(data: data)
        let datas = SocketData(client: UUID(), data: SystemData(systematic: "Everybody Welcome: " + client.name))
        await send(data: datas)
    }
    
    private func notify(data: String, client: UUID) async {
        let data = SocketData(client: client, data: SystemData(systematic: data))
        await send(data: data)
    }
    
    private func update(data: String, client: UUID) async {
        let data = SocketData(client: client, data: BitData(data: data))
        await send(data: data)
    }
    
    private func update(state: Bool, sender: UUID) async {
        switch await processing.process(Bit(state: state)) {
        case .none: return
        case .byte(let byte):
            let data = SocketData(client: UUID(), data: byte)
            await send(data: data)
        case .seed(let seed):
            let data = SocketData(client: UUID(), data: seed)
            await send(data: data)
        }
    }
}
