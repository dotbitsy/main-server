//
//  License.swift
//  
//
//  Created by Ω on 10/1/21.
//
import Fluent
import Vapor
import FluentMongoDriver

//id
//type
//name
//identifier
//model
//valid
//lastUpdateTime
//createdAt

enum LicenseFields: FieldKey {
    case schema = "license"
    case id
    case type
    case name // company name
    case identifier //model uuid
    case model //model type
    case valid
    case createdAt
    case lastUpdateTime
}


enum LicenseType: String, Codable {
    case enterprise
    case personal
    case entertainment
}

struct LicenseUpdate: Content {
    var valid: Bool
}

final class License: Model, Content {
    static let schema = LicenseFields.schema.rawValue.description
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: LicenseFields.type.rawValue)
    var type: LicenseType

    @Field(key: LicenseFields.name.rawValue) // company name
    var name: String
    
    @Field(key: LicenseFields.identifier.rawValue) //model uuid
    var identifier: String
    
    @Field(key: LicenseFields.model.rawValue) // modle name
    var model: String
    
    @Field(key: LicenseFields.valid.rawValue)
    var valid: Bool
    
    @Timestamp(key: LicenseFields.lastUpdateTime.rawValue, on: .update)
    var lastUpdateTime: Date?

    @Timestamp(key: LicenseFields.createdAt.rawValue, on: .create)
    var createdAt: Date?
   
    init() { }

    init(id: UUID? = nil,
         type: LicenseType,
         createdAt: Date? = nil,
         lastUpdate: Date? = nil,
         valid: Bool,
         model: String,
         name: String,
         identifier: String
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.identifier = identifier
        self.model = model
        self.createdAt = createdAt
        self.valid = valid
        self.lastUpdateTime = lastUpdate
    }
}
