import Foundation

public final class Procedure<Input, Output>: ConcurrentOperation {
    private var input: Input!
    private var output: Output!

    private let work: (_ input: Input, _ fullfill: @escaping (Output) -> Void) -> Void
    private let queue: OperationQueue

    public init(executeOn queue: OperationQueue = .main,
                _ work: @escaping (_ input: Input, _ fullfill: @escaping (Output) -> Void) -> Void) {
        self.work = work
        self.queue = queue
    }

    public convenience init(executeOn queue: OperationQueue = .main, _ work: @escaping (Input) -> Output) {
        self.init(executeOn: queue) { input, fullfill in
            fullfill(work(input))
        }
    }

    public override func execute() {
        if Input.self == Void.self {
            runVoidMain()
        } else {
            runMain()
        }
    }

    public func then<NewOutput>(_ nextProcedure: Procedure<Output, NewOutput>) -> Procedure<Output, NewOutput> {
        guard !self.isFinished else {
            nextProcedure.input = self.output
            nextProcedure.queue.addOperation(nextProcedure)
            return nextProcedure
        }

        let adapter = BlockOperation { [unowned nextProcedure] in
            nextProcedure.input = self.output
        }

        adapter.addDependency(self)
        nextProcedure.addDependency(adapter)

        if !self.isAlreadyAddedToQueue() {
            addToQueue()
        }
        queue.addOperation(adapter)

        guard !nextProcedure.isAlreadyAddedToQueue() else {
            preconditionFailure("Two procedures chains to the same procedure isn't supported.")
        }
        nextProcedure.addToQueue()

        return nextProcedure
    }

    public func finally(_ block: @escaping (Output) -> Void) {
        let finalBlock = Procedure<Output, Void> { output, fullfill in
            block(output)
            fullfill(())
        }
        _ = then(finalBlock)
    }
}

private extension Procedure {
    func runMain() {
        work(input) { [unowned self] output in
            self.output = output
            self.finish()
        }
    }

    private func runVoidMain() {
        work(() as! Input) { [unowned self] output in
            self.output = output
            self.finish()
        }
    }

    private func addToQueue() {
        queue.addOperation(self)
    }

    private func isAlreadyAddedToQueue() -> Bool {
        return queue.operations.contains(self)
    }
}

/// An abstract class that makes building simple asynchronous operations easy.
/// Subclasses must implement `execute()` to perform any work and call
/// `finish()` when they are done. All `NSOperation` work will be handled
/// automatically.
open class ConcurrentOperation: Operation {
    @objc(DSLConcurrentOperationState)
    private enum State: Int {
        case ready
        case executing
        case finished
    }

    private let stateQueue = DispatchQueue(label: "com.diejmon.operation.state", attributes: .concurrent)

    private var rawState = State.ready

    @objc
    private dynamic var state: State {
        get {
            return stateQueue.sync { rawState }
        }
        set {
            willChangeValue(forKey: #keyPath(state))
            stateQueue.sync(flags: .barrier) { rawState = newValue }
            didChangeValue(forKey: #keyPath(state))
        }
    }

    public final override var isReady: Bool {
        return state == .ready && super.isReady
    }

    public final override var isExecuting: Bool {
        return state == .executing
    }

    public final override var isFinished: Bool {
        return state == .finished
    }

    // MARK: - NSObject

    @objc
    private dynamic class func keyPathsForValuesAffectingIsReady() -> Set<String> {
        return [#keyPath(state)]
    }

    @objc
    private dynamic class func keyPathsForValuesAffectingIsExecuting() -> Set<String> {
        return [#keyPath(state)]
    }

    @objc private dynamic class func keyPathsForValuesAffectingIsFinished() -> Set<String> {
        return [#keyPath(state)]
    }

    // MARK: - Foundation.Operation

    public final override func start() {
        super.start()

        guard !isCancelled else {
            finish()
            return
        }

        state = .executing
        execute()
    }

    // MARK: - Public

    /// Subclasses must implement this to perform their work and they must not
    /// call `super`. The default implementation of this function throws an
    /// exception.
    open func execute() {
        fatalError("Subclasses must implement `execute`.")
    }

    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func finish() {
        state = .finished
    }
}

public extension Operation {
    func run(on queue: OperationQueue) {
        queue.addOperation(self)
    }

    func addDependencies(_ operations: [Operation]) {
        operations.forEach {
            addDependency($0)
        }
    }
}
