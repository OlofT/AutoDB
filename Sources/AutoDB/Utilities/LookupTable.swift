//
//  LookupTable.swift
//  
//
//  Created by Olof Thorén on 2021-07-05.
//

import Foundation

///Generic implementation of a table to lookup weakly stored AutoModel objects
struct LookupTable {
    
    typealias WeakStorage = WeakDictionary<UInt64, AnyObject>
    var objects = [String: WeakStorage]()
    
    mutating func setObject<T: AutoDBIDProtocol>(_ object: T) {
        
        let typeName = object.typeName
        let id = object.id
        
        guard let object = object as? AutoDBModel else {
            print("you must use the baseClass")
            return
        }
        setObject(typeName, id, object)
    }
    
    mutating func setObject<T: AutoDBModel>(_ object: T) {
        
        guard let proto = object as? AutoDBIDProtocol else {
            print("you must implement the AutoDBIDProtocol")
            return
        }
        let typeName = proto.typeName
        let id = proto.id
        
        setObject(typeName, id, object)
    }
    
    mutating func setObject(_ typeName: String, _ id: UInt64, _ object: AutoDBModel) {
        
        if objects[typeName] == nil {
            objects[typeName] = WeakStorage([id: object])
        }
        else {
            objects[typeName]![id] = object
        }
    }
    
    //This will be called when you don't implement the IDProtocol
    mutating func getObject(_ typeName: String, _ id: UInt64) -> AutoDBModel? {
        if let object = objects[typeName]?[id] {
            return object as? AutoDBModel
        }
        return nil
    }
    
}
