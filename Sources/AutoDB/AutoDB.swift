import Foundation
//For linux we can't import Combine - we need conditional imports if combine nor any other like CombineX exists, and then implement ObservableObject + @Published
#if canImport(CombineX)
//we can use this: @_exported
import CombineX
#elseif canImport(Combine)
//we can use this: @_exported
import Combine
#endif

/*
 Tidbits and discussions:
 https://swift.org/blog/swift-atomics/
 
 //To solve:
    Create a resultType, like a dictionary, that returns the child-class
*/
public class AutoDB {
        
}

///Class specific settings to generate SQL information that can't be known automatically
public struct AutoDBSettings {
    
    public init(ignoreProperties: Set<String>? = nil) {
        self.ignoreProperties = ignoreProperties
    }
    let ignoreProperties: Set<String>?  //by default we store everything
}

//Base class is only for storing things we need for automation
open class AutoDBModel {
    
    public required init() {}
    
    // properties that every class needs to have, these are not stored since in superClass.
    var toBeInserted = false
    var isAwake = false
    var isDeleted = false
    
    deinit {
        AutoDBManager.unregister(self)
    }
}

//must be separate in order to use it as a selector
public protocol AutoDBIDProtocol: AnyObject {
    
    init()
    var id: UInt64 { get set }
    static func generateId()  -> UInt64
}

public extension AutoDBIDProtocol {
    
    var typeName: String {
        String(describing: type(of: self))
    }
    static var typeName: String {
        String(describing: self)
    }
    
    static func generateId() -> UInt64 {
        
        return UInt64(arc4random()) << 28 | (UInt64(arc4random()) >> 4)
    }
}

//Hashable uses self so we run into the generic conformance problem
public protocol AutoDBProtocol: AutoDBIDProtocol, Codable, Hashable, ObservableObject {
    
    static func autoDBSettings() -> AutoDBSettings? //implement using "class func ..."
    static func fetchId(_ id: UInt64) -> Self?
}

public extension AutoDBProtocol {
    
    static func autoDBSettings() -> AutoDBSettings? {
        return nil
    }
    static func fetchId(_ id: UInt64) -> Self? {
        
        return AutoDBManager.fetchId(typeName, id)
    }
    static func == (lhs: Self, rhs: Self) -> Bool
    {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(id)
    }
    
}

