    import XCTest
    @testable import AutoDB
    import GRDB
    import Foundation
    
    class Resource {
        static var resourcePath = "./Tests/Resources"

        let name: String
        let type: String

        init(name: String, type: String) {
            self.name = name
            self.type = type
        }

        var path: String {
            guard let path: String = Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type) else {
                let filename: String = type.isEmpty ? name : "\(name).\(type)"
                return "\(Resource.resourcePath)/\(filename)"
            }
            return path
        }
    }

    final class AutoDBTests: XCTestCase {
        
        static var resourcePath: String = {
            let path = "./Tests/Resources"
            let manager = FileManager.default
            if manager.fileExists(atPath: path) == false {
                do {
                    try manager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Could not create resources folder: \(error.localizedDescription)")
                }
            }
            return path
        }()
        
        func testGRDBImport() throws {
            
            // 1. Open a database connection
            let dbQueue = try DatabaseQueue(path: Self.resourcePath + "/database.sqlite")
            // 2. Define the database schema
            try dbQueue.write { db in
                try db.create(table: "player", ifNotExists: true) { t in
                    t.autoIncrementedPrimaryKey("id")
                    t.column("name", .text).notNull().defaults(to: "sam")
                    t.column("score", .integer).defaults(to: 2).notNull()
                }
            }
            // 3. Define a record type
            struct Player: Codable, FetchableRecord, PersistableRecord {
                var id: Int64
                var name: String
                var score: Int
            }

            // 4. Access the database
            try? dbQueue.write { db in
                try Player(id: 1, name: "Arthur", score: 100).insert(db)
                try Player(id: 2, name: "Barbara", score: 1000).insert(db)
            }

            let players: [Player] = try dbQueue.read { db in
                try Player.fetchAll(db)
            }
            print(players.first!.name)
            
            //
            try dbQueue.read { db in
                
                //We can't find default values... Strange!
                let className = "player"
                let row = try Row.fetchOne(db, sql: "SELECT sql FROM sqlite_master WHERE name = '\(className)'")
                print(row!)
                
                for row in try Row.fetchAll(db, sql: "PRAGMA table_info('\(className)')") {
                    
                    print(row)
                    
                    let name:String = row["name"]
                    let type:String = row["type"]
                    let notnull:Int = row["notnull"]
                    
                    print("\(name) of \(type) \(notnull == 1 ? "NOTNULL" : "NULL")")
                }
            }
            
            print("done!")
        }
        
        func testReturningTypes() {
            
            let trial = DataAndDate()
            trial.id = 1
            AutoDBManager.register(trial)
            let item = DataAndDate.fetchId(1)
            XCTAssertEqual(item, trial)
            trial.dubDub = 6
            XCTAssertEqual(item?.dubDub, trial.dubDub)
        }
        
        func testTableGeneration() throws {
            
            let encoder = SQLTableEncoder()
            try encoder.setup(for: [DataAndDate.self])
            
            let className = DataAndDate.typeName
            let table = encoder.createTableSyntax(className)
            XCTAssertEqual(table, "CREATE table (compexPub,compexPubOpt,id,dubDub2,dubDub,timeStamp,floating,optionalIntArray,dataWith9,anOptObject,anOptDate) column statement: (compexPub : blob,compexPubOpt : blobOpt,id : integer,dubDub2 : real,dubDub : real,timeStamp : realOpt,floating : realOpt,optionalIntArray : blobOpt,dataWith9 : blob,anOptObject : blobOpt,anOptDate : realOpt)")
            
            print("\"\(encoder.createTableSyntax(className))\"")
        }
        
        func testTableGenerationInheritence() throws {
            
            let encoder = SQLTableEncoder()
            try encoder.setup(for: [BaseClass.self, Child.self])
            
            let table = encoder.createTableSyntax(Child.typeName)
            XCTAssertEqual(table, "CREATE table (arrayWithEncodables,arrayWithEncodablesPub,anOptIntPub,regularIntPub,id,ignoreProperty,anOptInt) column statement: (arrayWithEncodables : blob,arrayWithEncodablesPub : blob,anOptIntPub : integerOpt,regularIntPub : integer,id : integer,ignoreProperty : text,anOptInt : integerOpt)")
            
            print("\"\(encoder.createTableSyntax(Child.typeName))\"")
        }
        
        func testDecodable() {
            
            //let expect = XCTestExpectation(description: "expect")
            let testInt = 4
            let base = BaseClass()
            base.id = UInt64(testInt)
            base.regularIntPub = testInt
            
            let encoded = try! JSONEncoder().encode(base)
            let string = String(data: encoded, encoding: .utf8)!
            print(string)
            let decoded = try! JSONDecoder().decode(BaseClass.self, from: encoded)
            
            XCTAssertEqual(decoded.id, UInt64(testInt), "Id didn't work")
            XCTAssertEqual(decoded.regularIntPub, testInt, "regular int")
        }
        
        func lookupObjectsCount(_ typeName: String) -> Int {
            
            AutoDBManager.sharedInstance.objects.objects[typeName]?.cleanCount() ?? 0
        }
        
        func changeObjectsCount(_ typeName: String) -> Int {
            
            AutoDBManager.sharedInstance.objectsWithChanges.objects[typeName]?.cleanCount() ?? 0
        }
        
        func testWeakListeners() {
            
            var trial:BaseClass? = BaseClass()
            let typeName = trial!.typeName
            trial!.id = 7
            AutoDBManager.register(trial!)
            trial!.anOptIntPub = 2
            
            XCTAssertEqual(lookupObjectsCount(typeName), 1, "Adding items")
            XCTAssertEqual(changeObjectsCount(typeName), 1, "Changing items")
            
            var trial2:BaseClass? = BaseClass()
            trial2!.id = 666
            AutoDBManager.register(trial2!)
            trial2!.anOptIntPub = 2
            
            print("objects: \(lookupObjectsCount(typeName))")
            XCTAssertEqual(lookupObjectsCount(typeName), 2, "Adding items")
            XCTAssertEqual(changeObjectsCount(typeName), 2, "Fail changing in register")
            
            trial = nil
            trial2 = nil
            
            XCTAssertEqual(lookupObjectsCount(typeName), 0, "Not equal anymore")
            XCTAssertEqual(changeObjectsCount(typeName), 0, "Changing")
            print("objects: \(lookupObjectsCount(typeName))")
            //expect.fulfill()
            //wait(for: [expect], timeout: 9)
        }
    }
