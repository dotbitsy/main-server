//
//  File.swift
//  
//
//  Created by m4m4 on 22.06.21.
//
import Crypto
import Vapor
import Fluent


struct BlockChainNode: Content, Hashable {
    var address: String
    init(nodeAddress: String) {
        address = nodeAddress
    }
}

struct PreFixer {
    static let prefix = "817"
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
    var hex: String { bytes.map { String(format: "%02X", $0) }.joined() }
}

enum BlockChainFields: FieldKey {
    case schema = "BlockChain"
    case id
    case blocks
    case identifier
    case createdAt
    case genesis
}

final class BlockChain: Content, Model {
    
    static var schema: String = BlockChainFields.schema.rawValue.description
    
    init() { }
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: DataModelFields.createdAt.rawValue, on: .create)
    var createdAt: Date?
    
    @Field(key: BlockChainFields.blocks.rawValue)
    private(set) var blocks: [BlockModel]
    
    @Field(key: BlockChainFields.identifier.rawValue)
    private(set) var identifier: String
    
    private(set) var nodes: [BlockChainNode] = []
    private(set) var initialKey: String?
    
    var previous: BlockModel {
        blocks.last!
    }
    
    var genesisKey: String {
        initialKey ?? PreFixer.prefix + "00000000000000000000000000000000000"
    }
    
    
    init(genesis: BlockModel,
         createdAt: Date? = nil,
         blocks: [BlockModel] = []) {
        self.blocks = blocks
        self.createdAt = createdAt
        self.identifier = genesis.identifier
        add(block: genesis)
    }
    
    private enum CodingKeys: CodingKey {
        case blocks
    }
    
    func add(block: BlockModel) {
        
        if blocks.isEmpty {
            let genesis = block
            genesis.index = 0
            genesis.nonce = 0
            genesis.previousHash = genesisKey
            genesis.hashed()
            blocks.append(genesis)
            print(genesis.hash)
        } else {
            blocks.append(block)
        }
    }
    
    func register(node nds: [BlockChainNode]) -> [BlockChainNode] {
        nodes = Array(Set(nodes + nds))
        return nodes
    }
    
    func next(block datablock:BlockModel) -> BlockModel {
        let block = datablock
        block.index = blocks.count
        block.previousHash = previous.hash
        block.hashed()
        return block
    }
    
    var decoded: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }
    
    var valid: Bool {
        return blocks.filter({ !$0.valid }).count == 0
    }
}
