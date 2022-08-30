//
//  File.swift
//  
//
//  Created by Ω on 10/1/21.
//

import Fluent
import Vapor


enum ChainError: Error {
    case unauthorized
    case invalid
    case mismatchingIdentifier
}

struct ChainGate: Middleware {

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard
            let bearer = request.headers.bearerAuthorization,
            bearer.token == Environment.get("APIKEYCHAIN")
        else { return request.eventLoop.makeFailedFuture(Abort(.unauthorized)) }
        return next.respond(to: request)
    }
}

 
struct BlockChainController: RouteCollection {
    
    private(set) var stats: StatsController
    init(statsController: StatsController) {
        stats = statsController
    }
    
    func boot(routes: RoutesBuilder) throws {
        let chain = routes
            .grouped(ChainGate())
            .grouped("blockchain")
        chain.get(use: index)
        chain.post(use: create)
        chain.group(":identifier") { route in
            route.get(use: indexOne)
            route.post(use: add)
            route.delete(use: delete)
        }
    }

    func index(req: Request) throws -> EventLoopFuture<[BlockChain]> {
        req.chain()
    }
    
    func indexOne(req: Request) throws -> EventLoopFuture<BlockChain> {
        try req.findChain()
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        try req.addLicense(stats: stats)
    }
    
    func add(req: Request) throws -> EventLoopFuture<Response> {
        try req.addToChain(stats: stats)
    }
    
    func delete(req: Request) throws -> EventLoopFuture<Response> {
        try req.deleteChain()
    }
}

extension Request {
    
    func filterChain() throws -> String {
        guard let license = parameters.get(BlockChainFields.identifier.rawValue.description)
        else { throw Abort(.internalServerError, reason: "Request unexpectedly missing identifier parameter") }
        return license
    }

    func chain() -> EventLoopFuture<[BlockChain]> {
        BlockChain
            .query(on: db)
            .all()
    }

    func findChain() throws -> EventLoopFuture<BlockChain> {
        let identifier = try filterChain()
        return try findChain(identifier: identifier)
    }
    
    func findChain(identifier: String) throws -> EventLoopFuture<BlockChain> {
        return BlockChain
            .query(on: db)
            .filter(\.$identifier == identifier)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No license with matching id"))
            .guard({ chain in
                chain.valid
            }, else: ChainError.invalid)
    }
    
    func findBlocks(identifier: String) throws -> EventLoopFuture<[BlockModel]> {
        return BlockModel
            .query(on: db)
            .filter(\.$identifier == identifier)
            .all()
    }


    func addChain(identifier: String) throws -> EventLoopFuture<Response> {
        return try findChain(identifier: identifier)
            .flatMapAlways { result in
                switch result {
                case .success:
                    return self.eventLoop.makeSucceededFuture(Response(status: .ok))
                case .failure:
                    let genesis = DataModel(identifier: identifier,
                                            version: BlockChainFields.genesis.rawValue.description,
                                            model: BlockChainFields.genesis.rawValue.description,
                                            log: BlockChainFields.genesis.rawValue.description + "-" + identifier,
                                            value: 0.0)
                    return genesis.save(on: self.db)
                        .flatMap{ _ in
                            let block = BlockModel(identifier: identifier, dataModels: [genesis])
                            return block.save(on: self.db)
                                .flatMap { _ in
                                    let chain = BlockChain(genesis: block)
                                    return block.update(on: self.db)
                                        .flatMap { _ in
                                            return chain.save(on: self.db)
                                                .map { _ in Response(status: .ok) }
                                                .guard({ _ in
                                                    chain.valid
                                                }, else: ChainError.invalid)
                                        }
                                }.flatMapErrorThrowing { error in
                                    throw Abort(.conflict, reason: "A chain with identifier exists: \(error)")
                                }
                        }.flatMapErrorThrowing { error in
                            throw Abort(.conflict, reason: "A block with identifier exists: \(error)")
                        }
                }
            }
    }
//
    func addToChain(stats: StatsController) throws -> EventLoopFuture<Response> {
        let identifier = try filterChain()
        let newLog = try content.decode(DataLog.self)
        return try findChain()
            .guard({ chain in
                chain.identifier == newLog.identifier
            }, else: ChainError.mismatchingIdentifier)
            .tryFlatMap({ chain in
                let model = DataModel(identifier: identifier,
                                      version: newLog.version,
                                      model: newLog.model,
                                      log: newLog.log,
                                      value: newLog.value)
                return model.save(on: self.db)
                    .flatMap{ _ in
                        let block = chain.next(block: BlockModel(identifier: model.identifier, dataModels: [model]))
                        block.dataModels.forEach({
                            stats.add(value: $0.total)
                        })
                        return block.save(on: self.db)
                            .tryFlatMap { _ in
                                chain.add(block: block)
                                return chain
                                    .update(on: self.db)
                                    .guard({ _ in
                                        chain.valid
                                    }, else: ChainError.invalid)
                                    .map { _ in
                                        guard let encoded = try? JSONEncoder().encode(block)
                                        else  { return Response(status: .conflict) }
                                        return Response(status: .ok,
                                                        body: .init(data:  encoded))
                                    }
                            }
                    }.flatMapErrorThrowing{ error in
                        throw Abort(.conflict, reason: "Coudnl't find chains on save: \(error)")
                    }
            }).flatMapErrorThrowing{ error in
                throw Abort(.conflict, reason: "Coudnl't find chains: \(error)")
            }
    }
//
    func deleteChain() throws -> EventLoopFuture<Response> {
        let identifier = try filterChain()
        return BlockChain
            .query(on: db)
            .filter(\.$identifier == identifier)
            .delete()
            .map { _ in Response(status: .ok,
                                 body: .init(string: "\(identifier) deleted")) }
    }
}
