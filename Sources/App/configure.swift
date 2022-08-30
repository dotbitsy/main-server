import Fluent
import FluentMongoDriver
import Leaf
import Vapor


//SET .env file in production

//TIMES=2
//PORT=2001
//APIKEY-CHAIN=SUPERSECRETCHAINKEY
//APIKEY-LICENSE= SUPERSECRETLICENSEKEY

extension Request {
    var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
    
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }
}

public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    try app.databases.use(.mongo(
        connectionString: Environment.get("DATABASE_URL") ?? "mongodb://127.0.0.1:27017/institute"
    ), as: .mongo)
    // try app.autoRevert().wait()
    app.migrations.add(CreateLicenseMigrator())
    app.migrations.add(CreateDataModelMigrator())
    app.migrations.add(CreateBlockModelMigrator())
    app.migrations.add(CreateBlockChainMigrator())
    
    //try app.autoMigrate().wait()
    
    app.views.use(.leaf)
    try routes(app)
}
