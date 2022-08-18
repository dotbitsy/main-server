//
//  ByteProcessing.swift
//  
//
//  Created by Sina on 18.08.22.
//

import Foundation

actor ByteProcessing {
    
    enum ByteResult {
        case none
        case seed(Seed)
        case byte(Byte)
    }
    
    private var bits       : [Bit]
    private var complexity  : Int
    private var output      : String
    private var raw         : String
    
    init() {
        bits       = []
        complexity  = 0
        output      = ""
        raw         = ""
    }
    
    func process(_ bit: Bit) -> ByteResult {
        bits.append(bit)
        switch bits.count {
        case 1...7: return .none
        case 8...:
            let byte = Byte(bits: bits)
            bits.removeAll()
            return crush(byte: byte)
        default: fatalError("May not go beyond 8")
        }
    }
    
    private func crush(byte: Byte) -> ByteResult {
        raw += byte.crushed
        switch byte.crushed.quant {
        case true:
            complexity += 1
            return ByteResult.byte(byte)
        case false:
            output += byte.crushed
            guard output.count >= 8
            else { return ByteResult.byte(byte) }
            let result = ByteResult.seed(Seed(complexity: complexity, output: output, raw: raw))
            complexity = 0
            output = ""
            raw = ""
            return result
        }
    }
}
