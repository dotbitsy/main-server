//
//  File.swift
//  
//
//  Created by Ω on 7/22/22.
//

import Vapor
import Foundation


class BitSystem {
    var clients: BitSystemClients
    
    init(eventloop: EventLoop) {
        clients = BitSystemClients(eventloop: eventloop)
    }
    
    func connect( ws: WebSocket) async {
        ws.onBinary(process)
        ws.onText(process)
        await clients.update(type: .refresh)
    }
    
    func process(_ ws: WebSocket, buffer: ByteBuffer) async {
        await clients.update(type: .data(ws, buffer))
    }
    
    func process(_ ws: WebSocket, str: String) async {
        await clients.update(type: .string(ws, str))
    }
}
