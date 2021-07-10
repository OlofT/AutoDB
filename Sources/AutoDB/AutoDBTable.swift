//
//  File.swift
//  
//
//  Created by Olof Thorén on 2021-07-05.
//

import Foundation
import CXShim

//Use this to get all optionals!

class AutoDBTable {
        
    static var sharedInstance = AutoDBTable()
    static func listProperties(_ classType: AutoDBIDProtocol.Type)
    {
        let inst = classType.init()
        let mirror = Mirror(reflecting: inst)
        iterateMirror(mirror, inst)
    }
    
    static func iterateMirror(_ mirror: Mirror, _ object: AutoDBIDProtocol)
    {
        guard !mirror.children.isEmpty else
        {
            print("is empty \(mirror.children.isEmpty)")
            return
        }
        
        for child in mirror.children
        {
            if let label = child.label
            {
                let metaType = type(of: child.value)
                print("child \(label): \(metaType) from: \(child)")
                
                let childMirror = Mirror(reflecting: child.value)
                if let valueChild = childMirror.descendant("storage") {
                    print("valueChild \(valueChild): \(type(of: valueChild))")
                }
                
                //iOS 14 does this too...
                if let valueChild = childMirror.descendant("storage","publisher","subject","currentValue") {
                    print("valueChild2 \(valueChild): \(type(of: valueChild))")
                }
                
                //we set and get properties with codable - codable is better for us in every way? NO, it can't get the actual type from the published-wrapper.
            }
        }
        print("done!")
    }
    
    //Here we check for optional but can also check for classes or structs, etc
    static func isOptional(_ instance: Any) -> Bool
    {
        let mirror = Mirror(reflecting: instance)
        return mirror.displayStyle == .optional
    }
}

extension Published where Value: Encodable {
    
    public func innerName() -> String?
    {
        guard let storageValue = Mirror(reflecting: self).descendant("storage").map(Mirror.init)?.children.first?.value,
              let value = storageValue as? Value ??
                (storageValue as? Publisher).map(Mirror.init)?.descendant("subject", "currentValue") as? Value
        else
        {
            return nil
        }
        print("we got! \(type(of: value))")
        return "\(type(of: value))"
    }
}

extension Published where Value: Any {
    
    public func innerName() -> String?
    {
        return nil
    }
}
