//
//  File.swift
//  
//
//  Created by m4m4 on 24.06.21.
//

import Foundation
import Vapor
import Fluent

enum BlockModelFields: FieldKey {
    case schema = "BlockModel"
    case id
    case index
    case nonse
    case previousHash
    case identifier
    case hash
    case dataModels
    case key
    case createdAt
}

final class BlockModel: Content, Model {
    static let schema = BlockModelFields.schema.rawValue.description
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: BlockModelFields.index.rawValue)
    var index: Int
    
    @Field(key: BlockModelFields.nonse.rawValue)
    var nonce: Int
    
    @Field(key: BlockModelFields.previousHash.rawValue)
    var previousHash: String
    
    @Field(key: BlockModelFields.hash.rawValue)
    var hash: String
    
    @Field(key: BlockModelFields.identifier.rawValue)
    var identifier: String
    
    @Field(key: BlockModelFields.dataModels.rawValue)
    private(set) var dataModels: [DataModel]
    
    @Timestamp(key: BlockModelFields.createdAt.rawValue, on: .create)
    var createdAt: Date?
    
    var key: String {
        return index.description + previousHash + nonce.description + blockKey
    }
    
    init() { }
    init(id: UUID? = nil,
         createdAt: Date? = nil,
         index: Int = 0,
         nonse: Int = 0,
         previousHash: String = "",
         hash: String = "",
         identifier: String,
         dataModels: [DataModel] = []
    ) {
        self.id = id
        self.index = index
        self.nonce = nonse
        self.previousHash = previousHash
        self.hash = hash
        self.dataModels = dataModels
        self.identifier = identifier
        self.createdAt = createdAt
        self.dataModels = dataModels
    }
    
    private enum CodingKeys: CodingKey {
        case id
        case index
        case nonse
        case previousHash
        case hash
        case createdAt
        case dataModels
    }
    
    var hasher: String {
        guard
            let data = key.data(using: .utf8)
        else { return "" }
        return SHA256.hash(data: data).hex
    }
    
    private var blockKey: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = dataModels.map({
            dmdl -> DataLog in
            return dmdl.logKey
        })
        guard
            let c = try? encoder.encode(encoded)
        else { return "[ERROR - TRANSACTIONS KEY] ENCODING ERROR" }
        return String(data: c, encoding: .utf8)!
    }
    
    var valid: Bool {
        guard
            hasher.hasPrefix(PreFixer.prefix),
            hash == hasher
        else { return false }
        print("VALID: " + hasher)
        return true
    }
    
    func hashed() {
        hash = hasher
        while !hash.hasPrefix(PreFixer.prefix) {
            nonce += 1
            hash = hasher
            print(hash)
        }
    }
}
