//
//  PublishedExtensions.swift
//
//  Created by Olof Thorén on 2021-03-31.
//

import Foundation
import CXShim

public enum AnyError: Error {
    case anError
}

/// Publishers need their initial value to be set manually when decoding
extension Published: Decodable where Value: Decodable
{
    public init(from decoder: Decoder) throws
    {
        //let decoded = try Value(from:decoder)
        //self = Published(initialValue:decoded)
        self.init(initialValue: try .init(from: decoder))
    }
}


public protocol IsPublisher {
    func isPublisher() -> Bool
    func isPublisher2() -> Bool
}

extension Published.Publisher {
    func isPublisher() -> Bool {
        isPublisher2()
    }
    func isPublisher2() -> Bool {
        return true
    }
}

/// Publishers need help when encoding, you need to grab their underlying storage, which can be value or storage
extension Published: Encodable where Value: Encodable
{
    func isPublisher() -> Bool {
        return true
    }
    func isPublisher2() -> Bool {
        return true
    }
    
    public func encode(to encoder: Encoder) throws
    {
        // If we are encoding a TableDefinition, respond with our type - if basic (we just need the type when creating the table)
        if let encoder = encoder as? SQLTableEncoder, let type = SQLTableEncoder.getColumnType(storageType()) {
            encoder.singleValueEncoder.lastType = type
            return
        }
        
        //Otherwise we dig out the value
        guard let storageValue = Mirror(reflecting: self).descendant("storage").map(Mirror.init)?.children.first?.value,
              let value = storageValue as? Value ??
                (storageValue as? Publisher).map(Mirror.init)?.descendant("subject", "currentValue") as? Value
        else
        {
            throw EncodingError.invalidValue(self, codingPath: encoder.codingPath, "notice")
        }
        
        //we know its a complex type, so we encode it as data - but is it optional or not?
        if let encoder = encoder as? SQLTableEncoder {
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional
            {
                encoder.singleValueEncoder.lastType = .blobOpt
            }
            else {
                encoder.singleValueEncoder.lastType = .blob
            }
            return
        }
        
        try value.encode(to: encoder)
        
        //if complex type is not optional we cannot assign it to an optionalBlob
    }
    
    public func storageType() -> Value.Type
    {
        Value.self
    }
}

extension EncodingError
{
    /// `invalidValue` without having to pass a `Context` as an argument.
    static func invalidValue(_ value: Any, codingPath: [CodingKey], _ debugDescription: String = .init()) -> Self
    {
        .invalidValue(value, .init(codingPath: codingPath, debugDescription: debugDescription))
    }
}
