# Procedure

Swift 4, SPM

Simple wrapper around NSOperation to allow operation chaining. 

# Usage

```swift
Procedure<Void, Bool>(executeOn: queue, { (_, fullfill) in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(true)
        }).then(Procedure<Bool, Int>(executeOn: queue, { (op1Result, fullfill) in
            Thread.sleep(forTimeInterval: 0.3)
            fullfill(op1Result ? 1 : 0)
        })).finally { (result) in
            // Do something with the result from previous procedure
        }
```

# TODO:

- improve chaining performance when there are a lot of operations in queue
- iOS xcodeproj
- add sugar and improve interface and comman usages
- travis