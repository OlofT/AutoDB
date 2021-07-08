//
//  File.swift
//  
//
//  Created by Olof Thorén on 2021-07-02.
//
import Foundation
import Combine
import AutoDB

// They must all inherit and implement AutoDBModel, AutoDBProtocol
// They must all not have an init OR an empty required one: required init() {... setup }, you may use convenience inits instead.
class DataAndDate: AutoDBModel, AutoDBProtocol {
    
    convenience init(_ id: UInt64) {
        self.init()
        self.id = id
    }
    
    var anOptObject: DataAndDate? = nil
    
    @Published var compexPub = BaseClass()
    @Published var compexPubOpt: DataAndDate? = nil
    var anOptDate: Date? = nil
    var id: UInt64 = 1
    var dubDub2: Float = 1.0
    var dubDub: Double = 1.0
    @Published var timeStamp: Date = Date()
    @Published var floating = 1.0
    @Published var optionalIntArray: [Int]? = [1, 2, 3, 4]
    var dataWith9: Data = Data([9, 9, 9, 9])
    
    var ignoreThis = 1
    
    class func autoDBSettings() -> AutoDBSettings? {
        .init(ignoreProperties: Set(["ignoreThis"]))
    }
}

open class BaseClass: AutoDBModel, AutoDBProtocol {
    
    var arrayWithEncodables = [Int]()
    @Published var arrayWithEncodablesPub = [Int]()
    
    @Published var anOptIntPub: Int? = nil
    @Published var regularIntPub: Int = 1
    
    var anOptInt: Int? = nil
    public var id: UInt64 = 0
    var ignoreProperty = "don't store this"
    
    /*
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    */
    
    func debug () {
        let some = BaseClass()
        some.id = 2
        print("some: \(some.id)")
    }
    public class func autoDBSettings() -> AutoDBSettings? {
        AutoDBSettings(ignoreProperties: Set(["ignoreProperty"]))
    }
}

class Child: BaseClass {
    
    required init() {
        super.init()
        ignoreProperty = "store this!"
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override class func autoDBSettings() -> AutoDBSettings? {
        nil
    }
}
