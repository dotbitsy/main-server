//
//  StatsController.swift
//  
//
//  Created by Sina on 30.08.22.
//

import Vapor
import Fluent

struct ChainStats: Codable {
    let total: Double
    let count: Int
}


class StatsController: RouteCollection {
    enum StatsError: Error {
        case encoding
    }
    private(set) var totalChainValue: Double
    private(set) var totalChainCount: Int
    
    
    init(chain: [BlockChain]) {
        let bc = chain
            .map({ $0.blocks.map { $0.$dataModels.value }})
            .flatMap({ $0 })
        var v = 0.0
        bc.forEach { mdl in
            mdl?.forEach({ dm in
                v += dm.total
            })
        }
        totalChainValue = v
        totalChainCount = chain.count
    }
  
    func boot(routes: RoutesBuilder) throws {
        let stats = routes
            .grouped(ChainGate())
            .grouped("stats")
        stats.get(use: index)
    }
    
    func add(value: Double) {
        totalChainValue += value
    }
    
    func add(newChain: Int) {
        totalChainCount += newChain
    }
    
    func index(req: Request) throws -> EventLoopFuture<Response> {
        guard let encoded = try? JSONEncoder().encode(ChainStats(total: totalChainValue,
                                                                 count: totalChainCount))
        else  { return req.eventLoop.makeFailedFuture(StatsError.encoding) }
        return req.eventLoop.makeSucceededFuture(Response(status: .ok,
                                                          body: .init(data:  encoded)))
    }
}
