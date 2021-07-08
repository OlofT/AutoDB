//
//  File.swift
//  
//
//  Created by Olof Thorén on 2021-07-06.
//

import Foundation
import Combine

//TODO: encode all unknown formats to data, JSON or some faster/smaller format

public enum ColumnType: Int32 {
    
    //Notice that date doesn't exist in SQLite, and we don't care since Codable handles conversion for us
    case integer
    case real
    case text
    case blob
    case json   //also data but with jsonEncoding - use a better format and convert to built in support in the future if that happens.
    //we also need optional types
    case integerOpt
    case realOpt
    case textOpt
    case blobOpt
    case jsonOpt
    
    case error
}

struct TableInfo {
    
    init(settings: AutoDBSettings?) {
        self.settings = settings
    }
    
    //strangely swift-collections doesn't load so we need to do OrderedDictionary the hard way
    var columns = [String: ColumnType]()
    var columnOrder = [String]()
    var settings: AutoDBSettings?
    
    var columnNames: [String] {
        columnOrder.map { $0 }
    }
    var columnNameString: String {
        columnNames.joined(separator: ",")
    }
    var columnStatement: String {
        //TODO: not done
        columnOrder.map { $0 + " : \(columns[$0]!)" }
            .joined(separator: ",")
    }
    
    //TODO: Work in progress
    var createTableSyntax: String {
        
        return "CREATE table (\(columnNameString)) column statement: (\(columnStatement))"
    }
}

class SQLTableEncoder: Encoder {
    
    var encodedTables = [String: TableInfo]()
    var currentClass = ""
    
    func setup<T: AutoDBProtocol>(for classTypes:[T.Type]) throws {
        
        for classType in classTypes {
            let object = classType.init()
            currentClass = object.typeName
            encodedTables[currentClass] = TableInfo(settings: classType.autoDBSettings())
            
            //we automatically get all values
            try object.encode(to: self)
            //but for optionals we need reflection
            iterateOptionalProperties(Mirror(reflecting: object))
            
            //Now compare with current tableDefinition and handle migration
        }
    }
    
    func createTableSyntax(_ className: String) -> String {
        return encodedTables[className]!.createTableSyntax
    }
    
    func addColumn(_ column: String, _ type: ColumnType) {
        
        if ignoreKey(column) {
            return
        }
        encodedTables[currentClass]!.columns[column] = type
        encodedTables[currentClass]!.columnOrder.append(column)
    }
    
    func ignoreKey(_ column: String) -> Bool {
        if let settings = encodedTables[currentClass]!.settings {
            return settings.ignoreProperties?.contains(column) ?? false
        }
        return false
    }
    
    public var codingPath: [CodingKey]
    public var userInfo: [CodingUserInfoKey : Any]
    var singleValueEncoder = SingleValueEncoder()
    
    init(_ codingPath: [CodingKey] = [], _ userInfo: [CodingUserInfoKey : Any] = [:]) {
        self.codingPath = codingPath
        self.userInfo = userInfo
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        
        return KeyedEncodingContainer(Container(enc: self))
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return singleValueEncoder
    }
    func singleValueContainer() -> SingleValueEncodingContainer {
        return singleValueEncoder
    }
    
    //It was impossible to extend protocols to do this automatically, now we need to do this for every individual type
    static func getColumnType<T>(_ value: T) -> ColumnType? {
        
        //Problem: There are too many types, we need the encoded result!
        //do we? We know they are Encodable so we can always turn them into data
        
        var columnType:ColumnType? = nil
        switch value {
            //we can have values
            case is String:
                columnType = .text
            case is Data:
                columnType = .blob
            case is Double, is Float, is Date:
                columnType = .real
            case is Int, is Int8, is Int16, is Int64, is Int32,
                 is UInt, is UInt8, is UInt16, is UInt64, is UInt32:
                columnType = .integer
            
            //or types
            case is String.Type:
                columnType = .textOpt
            case is Data.Type:
                columnType = .blobOpt
            case is Double.Type, is Float.Type, is Date.Type:
                columnType = .realOpt
            case is Int.Type, is Int8.Type, is Int16.Type, is Int64.Type, is Int32.Type,
                 is UInt.Type, is UInt8.Type, is UInt16.Type, is UInt64.Type, is UInt32.Type:
                columnType = .integerOpt
                
            //or types that are optional
            case is String?.Type:
                columnType = .textOpt
            case is Data?.Type:
                columnType = .blobOpt
            case is Double?.Type, is Float?.Type, is Date?.Type:
                columnType = .realOpt
            case is Int?.Type, is Int8?.Type, is Int16?.Type, is Int64?.Type, is Int32?.Type,
                 is UInt?.Type, is UInt8?.Type, is UInt16?.Type, is UInt64?.Type, is UInt32?.Type:
                columnType = .integerOpt
                
            default:
                //All other gets JSON format since we know they are enodable
                //.blob
                break
        }
        return columnType
    }
    
    func iterateOptionalProperties(_ mirror: Mirror)
    {
        guard !mirror.children.isEmpty else
        {
            //print("Mirror is empty \(mirror.children.isEmpty)")
            if let mirror = mirror.superclassMirror {
                iterateOptionalProperties(mirror)
            }
            return
        }
        
        for child in mirror.children
        {
            if let label = child.label
            {
                let childMirror = Mirror(reflecting: child.value)
                if childMirror.displayStyle != .optional {
                    continue
                }
                let metaType = type(of: child.value)
                //print("child \(label): \(metaType) from: \(child)")
                if let columnType = SQLTableEncoder.getColumnType(metaType) {
                    
                    addColumn(label, columnType)
                }
                else {
                    
                    //If not of basic type, we can still encode it as blob.
                    addColumn(label, .blobOpt)
                }
                
            }
        }
        if let mirror = mirror.superclassMirror {
            iterateOptionalProperties(mirror)
        }
    }
    
    class Container<KeyType: CodingKey>: KeyedEncodingContainerProtocol {
        var codingPath: [CodingKey] = []

        func encodeNil(forKey key: KeyType) throws { fatalError("All columns must have a value") }
        func encode(_ value: String, forKey key: KeyType) throws {
            enc.addColumn(key.stringValue, .text)
        }
        
        func encode<T>(_ value: T, forKey key: KeyType) throws where T : Encodable {
            
            if enc.ignoreKey(key.stringValue) {
                return
            }
            print("doing: \(type(of: value)) for: \(key.stringValue)")
            if let sqlType = SQLTableEncoder.getColumnType(value) {
                enc.addColumn(key.stringValue, sqlType)
            }
            else {
                // When its a Published or Array etc (not a base type) we get here, to encode Published correctly we must ask its for the type of the wrappedValue. The only way I managed to do that was to use encode(to:) from Encodable.
                
                try value.encode(to: enc)
                if let sqlType = enc.singleValueEncoder.lastType {
                    enc.addColumn(key.stringValue, sqlType)
                    enc.singleValueEncoder.lastType = nil
                }
                else {
                    //print("Could not encode \(T.self) for \(key.stringValue)")
                    //We know we can handle it since a codable - but it's not of our basic types so encode/decode using optional data.
                    
                    //NO! if its a publisher with non-opt values, this will break stuff!
                    
                    enc.addColumn(key.stringValue, .blobOpt)
                    //let js = JSONEncoder.init()
                    //let data = try js.encode(value)
                    //print("we got JSON: \(String(data: data, encoding: .utf8)!)")
                }
            }
        }
        //Optionals are not called automatically, so we skip those. Needs to be handled in other ways.

        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: KeyType) -> KeyedEncodingContainer<NestedKey> where NestedKey: CodingKey { fatalError() }
        func nestedUnkeyedContainer(forKey key: KeyType) -> UnkeyedEncodingContainer { fatalError() }
        func superEncoder() -> Encoder { fatalError() }
        func superEncoder(forKey key: KeyType) -> Encoder { fatalError() }

        typealias Key = KeyType

        var enc: SQLTableEncoder

        init(enc: SQLTableEncoder) {
            self.enc = enc
        }
    }
    
    class SingleValueEncoder: SingleValueEncodingContainer, UnkeyedEncodingContainer {
        
        enum EncodingError: Error {
            ///We don't know how to store nil columns - typically an error when decoding optionals
            case nilEncoding
        }
        
        var lastType: ColumnType?
        func encode<T>(_ value: T) throws where T : Encodable {
            lastType = SQLTableEncoder.getColumnType(value)
        }
        var codingPath: [CodingKey] = []
        var count: Int = 1
        
        func encodeNil() throws {
            throw EncodingError.nilEncoding
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            fatalError()
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            fatalError()
        }
        
        func superEncoder() -> Encoder {
                    
            fatalError()
        }
    }
    
}

/*
//THIS IS WEIRD!
extension BinaryFloatingPoint {
    // Creates a new instance from the given value if possible otherwise returns nil
    var double: Double? { Double(exactly: self) }
    // Creates a new instance from the given value, rounded to the closest possible representation.
    var doubleValue: Double { .init(self) }
}
 
protocol SQLType {
    func columnType() -> ColumnType
}

protocol BinaryFloatingPoint: SQLType {
}

 protocol BinaryInteger: SQLType {
}
extension BinaryFloatingPoint {
    func columnType() -> ColumnType {
        .real
    }
}

extension BinaryInteger {
    func columnType() -> ColumnType {
        .integer
    }
}
 
extension Date: SQLType {
    func columnType() -> ColumnType {
        .date
    }
}
extension String: SQLType {
    func columnType() -> ColumnType {
        .text
    }
}
extension Data: SQLType {
    func columnType() -> ColumnType {
        .blob
    }
}
 */
