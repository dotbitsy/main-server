//
//  LicenseController.swift
//  
//
//  Created by Ω on 10/1/21.
//

import Fluent
import Vapor


struct LicenseGate: Middleware {

    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard
            let bearer = request.headers.bearerAuthorization,
            bearer.token == Environment.get("APIKEYLICENSE")
        else { return request.eventLoop.makeFailedFuture(Abort(.unauthorized)) }
        return next.respond(to: request)
    }
}


struct LicenseController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let license = routes
            .grouped(LicenseGate())
            .grouped("license")
        license.get(use: index)
        license.post(use: create)
        license.group(":identifier") { route in
            route.get(use: indexOne)
            route.delete(use: delete)
            route.patch(use: patch)
        }
        
        print("Router Set")
    }

    func index(req: Request) throws -> EventLoopFuture<[License]> {
        req.licenses()
    }
    
    func indexOne(req: Request) throws -> EventLoopFuture<Response> {
        try req.findLicense()
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        try req.addLicense()
    }
    
    func patch(req: Request) throws -> EventLoopFuture<Response> {
        try req.updateLicense()
    }

    func delete(req: Request) throws -> EventLoopFuture<Response> {
        try req.deleteLicense()
    }
}


extension Request {
    
    func filterLicense() throws -> String {
        guard
            let license = parameters.get(LicenseFields.identifier.rawValue.description)
        else { throw Abort(.internalServerError, reason: "Request unexpectedly missing identifier parameter") }
        return license
    }
        
    func licenses() -> EventLoopFuture<[License]> {
        License
            .query(on: db)
            .all()
    }
    
    func findLicense() throws -> EventLoopFuture<Response> {
        let identifier = try filterLicense()
        return License
            .query(on: db)
            .filter(\.$identifier == identifier)
            .first()
            .unwrap(or: Abort(.notFound, reason: "No license with matching id"))
            .map({
                Response(status: .created,
                         body: .init(data: try! JSONEncoder().encode($0)))
            })
    }
    
    func addLicense() throws -> EventLoopFuture<Response> {
        let newLicense = try content.decode(License.self)
        return try addChain(identifier: newLicense.identifier)
            .flatMap { _ in
                return newLicense
                    .save(on: self.db)
                    .flatMapAlways({ result in
                        switch result {
                        case .success:
                            return self.eventLoop.makeSucceededFuture(Response(status: .created,
                                                                               body: .init(data: try! JSONEncoder().encode(newLicense))))
                        case .failure(let error):
                            return self.eventLoop.makeFailedFuture(Abort(.conflict, reason: "Failed to create License. License Exists: \(error)"))
                        }
                    })
            }
            .flatMapErrorThrowing { error in
                throw Abort(.conflict, reason: "Failed to create BlockChain: \(error)")
            }
    }


    func updateLicense() throws -> EventLoopFuture<Response> {
        let identifier = try filterLicense()
        let update = try content.decode(LicenseUpdate.self)
        return License
            .query(on: db)
            .set(\.$valid, to: update.valid)
            .filter(\.$identifier == identifier)
            .update()
            .map { _ in Response(status: .ok,
                                 body: .init(string: "\(identifier) updated")) }
    }

    func deleteLicense() throws -> EventLoopFuture<Response> {
        let identifier = try filterLicense()
        return License.query(on: db)
            .filter(\.$identifier == identifier)
            .delete()
            .map { _ in Response(status: .ok,
                                 body: .init(string: "\(identifier) deleted")) }
    }
}
