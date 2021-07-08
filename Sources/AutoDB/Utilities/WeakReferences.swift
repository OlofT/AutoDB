//
//  WeakReferences.swift
//  
//
//  Created by Olof Thorén on 2021-07-02.
/*
 TODO: Move this to a Package of its own!
    fill in the rest, like them: https://www.raywenderlich.com/10286147-building-a-custom-collection-with-protocols-in-swift
 
 Taken/inspired by: https://www.objc.io/blog/2017/12/28/weak-arrays/
 */

import Foundation

//weak only applies to objects, otherwise no refs
final public class WeakBox<A: AnyObject> {
    weak var unbox: A?
    init(_ value: A) {
        unbox = value
    }
}

public struct WeakArray<Element: AnyObject> {
    private var items: [WeakBox<Element>] = []
    
    public init(_ elements: [Element]) {
        items = elements.map { WeakBox($0) }
    }
}

//can someone tell me WHY this is IN a extension?
extension WeakArray: Collection {
    public var startIndex: Int { return items.startIndex }
    public var endIndex: Int { return items.endIndex }
    
    public subscript(_ index: Int) -> Element? {
        return items[index].unbox
    }
    
    public func index(after idx: Int) -> Int {
        return items.index(after: idx)
    }
}

// MARK: - WeakDictionary

@frozen public struct WeakDictionary<Key: Hashable, Value: AnyObject>{
    
    //This cannot be lazy, since that might modify it when subscripting.
    private var items: [Key: WeakBox<Value>] = [:]
    init(_ elements: [Key: Value]) {
        
        items = Dictionary<Key, WeakBox<Value>>.init(uniqueKeysWithValues: elements.map {
            ($0, WeakBox($1))
        })
    }
}

extension WeakDictionary: MutableCollection {
    
    public typealias Item = (key: Key, value: WeakBox<Value>)
    public typealias Index = DictionaryIndex<Key, WeakBox<Value>>
    
    public subscript(position: Index) -> Item {
        get {
           return items[position]
       }
        set(newValue) {
            items[newValue.key] = newValue.value
        }
    }
    
    public func index(after i: Index) -> Index {
        items.index(after: i)
    }
    public subscript(position: Int) -> (key: Key, value: WeakBox<Value>) {
         get {
            let index = items.index(items.startIndex, offsetBy: position)
            return items[index]
        }
        set(newValue) {
            items[newValue.key] = newValue.value
        }
    }
    
    public subscript(key: Key) -> Value? {
        mutating get {
            items[key]?.unbox
        }
        set(newValue) {
            
            if let value = newValue {
                items[key] = WeakBox(value)
            } else {
                items.removeValue(forKey: key)
            }
        }
    }
    
    ///Remove all weak vars that are nil, this is useful if you rely on count.
    public mutating func cleanup() {
        for item in items {
            if self[item.key] == nil {
                items.removeValue(forKey: item.key)
            }
        }
    }
    
    public var startIndex: Index { return items.startIndex }
    public var endIndex: Index { return items.endIndex }
    
    ///Shortcut to first remove any weak vars, then fetch count
    public mutating func cleanCount() -> Int {
        cleanup()
        return items.count
    }
    public var count: Int { items.count }
    public var isEmpty: Bool { items.isEmpty }
    
    func debug() {
        
        
    }
}
