@testable import Procedure
import XCTest

class ProcedureTests: XCTestCase {
    private var queue: OperationQueue!
    private var queue2: OperationQueue!
    
    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        queue.isSuspended = false
        
        queue2 = OperationQueue()
        queue2.maxConcurrentOperationCount = 10
        queue2.isSuspended = false
    }
    
    override func tearDown() {
        queue.cancelAllOperations()
        queue = nil
        queue2.cancelAllOperations()
        queue2 = nil
        super.tearDown()
    }
    
    func testChaining() {
        let correctResultExpectation = expectation(description: "Correct result received")
        
        Procedure<Void, Bool>(executeOn: queue, { _, fullfill in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(true)
        }).then(Procedure<Bool, Int>(executeOn: queue, { op1Result, fullfill in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(op1Result ? 1 : 0)
        })).finally { _ in
            correctResultExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFinally() {
        let correctResultExpectation = expectation(description: "Correct result received")
        
        Procedure<Void, Int>(executeOn: queue) { _, fullfill in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(10)
            }.finally { _ in
                correctResultExpectation.fulfill()
        }
        waitForExpectations(timeout: 05, handler: nil)
    }
    
    func testTreeDependency() {
        let downloadProcedure = Procedure<Void, Int>(executeOn: queue) { () -> Int in
            return 10
        }
        
        let multiplyProcedure = Procedure<Int, Int>(executeOn: queue) { (value) -> Int in
            return value * value
        }
        
        let doubleProcedure = Procedure<Int, Int>(executeOn: queue2) { (value) -> Int in
            return value * 2
        }
        
        let multiplyFinished = expectation(description: "Multiply finished")
        
        downloadProcedure.then(multiplyProcedure).finally { (multipliedValue) in
            XCTAssertEqual(multipliedValue, 100)
            multiplyFinished.fulfill()
        }
        
        let doubleFinished = expectation(description: "Double finished")
        downloadProcedure.then(doubleProcedure).finally { (doubledValue) in
            XCTAssertEqual(doubledValue, 20)
            doubleFinished.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    //  func testReverseTreeDependency() {
    //    let download1Procedure = Procedure<Void, Int>(executeOn: queue) { () -> Int in
    //      return 10
    //    }
    //
    //    let download2Procedure = Procedure<Void, Int>(executeOn: queue) { () -> Int in
    //      return 20
    //    }
    //
    //    let multiplyProcedure = Procedure<Int, Int>(executeOn: queue) { (value) -> Int in
    //      return value * value
    //    }
    //
    //    let multiplyFinished = expectation(description: "Multiply finished")
    //    multiplyFinished.expectedFulfillmentCount = 2
    //
    //    download1Procedure.then(multiplyProcedure).finally { (multipliedValue) in
    //      XCTAssertEqual(multipliedValue, 100)
    //      multiplyFinished.fulfill()
    //    }
    //
    //    download2Procedure.then(multiplyProcedure).finally { (multipliedValue) in
    //      XCTAssertEqual(multipliedValue, 400)
    //      multiplyFinished.fulfill()
    //    }
    //
    //    waitForExpectations(timeout: 2, handler: nil)
    //  }
    
    static var allTests = [
        ("testChaining", testChaining),
        ("testFinally", testFinally),
    ]
}
