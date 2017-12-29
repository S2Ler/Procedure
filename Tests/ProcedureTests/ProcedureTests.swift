import XCTest
@testable import Procedure

class ProcedureTests: XCTestCase {

    private var queue: OperationQueue!

    override func setUp() {
        super.setUp()
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 10
        queue.isSuspended = false
    }

    override func tearDown() {
        queue.cancelAllOperations()
        queue = nil
        super.tearDown()
    }

    func testChaining() {
        let correctResultExpectation = expectation(description: "Correct result received")

        Procedure<Void, Bool>(executeOn: queue, { (_, fullfill) in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(true)
        }).then(Procedure<Bool, Int>(executeOn: queue, { (op1Result, fullfill) in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(op1Result ? 1 : 0)
        })).finally { (result) in
            correctResultExpectation.fulfill()
        }

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFinally() {
        let correctResultExpectation = expectation(description: "Correct result received")
        Procedure<Void, Int>(executeOn: queue) { (_, fullfill) in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(10)
            }.finally { (result) in
                correctResultExpectation.fulfill()
        }
        waitForExpectations(timeout: 05, handler: nil)
    }


    static var allTests = [
        ("testChaining", testChaining),
        ("testFinally", testFinally),
    ]
}
