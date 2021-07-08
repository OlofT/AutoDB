    import XCTest
    @testable import AutoDB

    final class AutoDBTests: XCTestCase {
        
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
            XCTAssertEqual(table, "CREATE table (arrayWithEncodables,arrayWithEncodablesPub,anOptIntPub,regularIntPub,id,ignoreProperty,anOptInt) column statement: (arrayWithEncodables : blobOpt,arrayWithEncodablesPub : blobOpt,anOptIntPub : integerOpt,regularIntPub : integerOpt,id : integer,ignoreProperty : text,anOptInt : integerOpt)")
            
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
            trial2!.anOptInt = 2
            
            print("objects: \(lookupObjectsCount(typeName))")
            XCTAssertEqual(lookupObjectsCount(typeName), 2, "Adding items")
            XCTAssertEqual(changeObjectsCount(typeName), 2, "Changing")
            
            trial = nil
            trial2 = nil
            
            XCTAssertEqual(lookupObjectsCount(typeName), 0, "Not equal anymore")
            XCTAssertEqual(changeObjectsCount(typeName), 0, "Changing")
            print("objects: \(lookupObjectsCount(typeName))")
            //expect.fulfill()
            //wait(for: [expect], timeout: 9)
        }
    }
