//
//  File.swift
//  
//
//  Created by Olof Thorén on 2021-07-05.
//

import Foundation
import CXShim

/**
 To keep track of all changes of all objects, we simply use Combine's objectWillChange method, and store them in a weak list - when deallocated we remove them and cancel their listeners.
*/
class AutoDBManager {
    
    typealias WeakStorage = WeakDictionary<UInt64, AnyObject>
    var lookupListeners = [String: [UInt64: Set<AnyCancellable>]]()
    var objects = LookupTable()
    var objectsWithChanges = LookupTable()
    
    static let sharedInstance = AutoDBManager()
    func storeListener<T: AutoDBIDProtocol>(_ object: T, _ list: inout Set<AnyCancellable>) {
        
        let typeName = object.typeName
        if lookupListeners[typeName] == nil {
            lookupListeners[typeName] = [UInt64: Set<AnyCancellable>]()
        }
        lookupListeners[typeName]![object.id] = list
    }
    
    static func register<T: AutoDBProtocol>(_ object: T) where T: AutoDBModel {
        
        let id = object.id
        let typeName = object.typeName
        sharedInstance.objects.setObject(object)
        
        var list = Set<AnyCancellable>()
        object.objectWillChange
            .sink { _ in
                
                if let wObject = sharedInstance.objects.getObject(typeName, id),
                   //ignore messages if not awake
                   wObject.isAwake {
                    
                    //We might speed things up by removing the listener when object is set - and then start listening again when saved, but I don't think it matters much.
                    sharedInstance.objectsWithChanges.setObject(wObject)
                }
            }
            .store(in: &list)
        sharedInstance.storeListener(object, &list)
        object.isAwake = true
    }
    
    //This function cannot depend on the IDProtocoll to automatically unregister all objects.
    static func unregister(_ object: AutoDBModel) {
        
        guard let object = object as? AutoDBIDProtocol else {
            return
        }
        let typeName = object.typeName
        
        //cancel listeners
        sharedInstance.lookupListeners[typeName]?[object.id] = nil
        sharedInstance.objects.objects[typeName]?[object.id] = nil
    }
    
    static func fetchId<T: AutoDBProtocol>(_ typeName: String, _ id: UInt64) -> T? {
        
        sharedInstance.objects.getObject(typeName, id) as? T
    }
}
