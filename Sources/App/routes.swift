import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get("hello") { req in
        return req.view.render("index", ["title": "Hello Vapor!"])
    }
    
    app.get { req async throws in
           try await req.view.render("institute", ["title": "Hello Vapor!"])
       }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }
    
    let bitsys = BitSystem(eventloop: app.eventLoopGroup.next())
    app.webSocket("bitsys") { req, ws async in
        await bitsys.connect(ws: ws)
    }

     
    try app.register(collection: LicenseController())
    try app.register(collection: BlockChainController())
    try app.register(collection: BlockModelController())
}
