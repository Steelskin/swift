// RUN: %target-typecheck-verify-swift  -target %target-swift-5.1-abi-triple

// REQUIRES: concurrency

actor SomeActor { }

@globalActor
struct GlobalActor {
  static var shared: SomeActor { SomeActor() }
}

@globalActor
struct GenericGlobalActor<T> {
  static var shared: SomeActor { SomeActor() }
}

protocol P1 {
  associatedtype Assoc

  @GlobalActor func method1()
  @GenericGlobalActor<Int> func method2()
  @GenericGlobalActor<Assoc> func method3()
  func method4()
}

protocol P2 {
  @GlobalActor func asyncMethod1() async
  @GenericGlobalActor<Int> func asyncMethod2() async
  func asyncMethod3() async
}

// expected-warning@+1{{conformance of 'C1' to protocol 'P1' crosses into global actor 'GlobalActor'-isolated code and can cause data races}}
class C1 : P1, P2 {
  // expected-note@-1{{turn data races into runtime errors with '@preconcurrency'}}

  typealias Assoc = String

  func method1() { }

  @GenericGlobalActor<String> func method2() { } // expected-note{{global actor 'GenericGlobalActor<String>'-isolated instance method 'method2()' cannot be used to satisfy global actor 'GenericGlobalActor<Int>'-isolated requirement from protocol 'P1'}}
  @GenericGlobalActor<String >func method3() { }
  @GlobalActor func method4() { } // expected-note{{global actor 'GlobalActor'-isolated instance method 'method4()' cannot be used to satisfy nonisolated requirement from protocol 'P1'}}

  // Okay: we can ignore the mismatch in global actor types for 'async' methods.
  func asyncMethod1() async { }
  @GenericGlobalActor<String> func asyncMethod2() async { }
  @GlobalActor func asyncMethod3() async { }
}

protocol NonIsolatedRequirement {
  func requirement()
}

@MainActor class OnMain {}

// expected-warning@+1{{conformance of 'OnMain' to protocol 'NonIsolatedRequirement' crosses into main actor-isolated code}}
extension OnMain: NonIsolatedRequirement {
  // expected-note@-1{{turn data races into runtime errors with '@preconcurrency'}}
  // expected-note@-2{{mark all declarations used in the conformance 'nonisolated'}}
  // expected-note@+1 {{main actor-isolated instance method 'requirement()' cannot be used to satisfy nonisolated requirement from protocol 'NonIsolatedRequirement'}}
  func requirement() {}
}

// expected-note@+1 {{calls to global function 'downgrade()' from outside of its actor context are implicitly asynchronous}}
@preconcurrency @MainActor func downgrade() {}

extension OnMain {
  struct Nested {
    // expected-note@+1 {{add '@MainActor' to make instance method 'test()' part of global actor 'MainActor'}}
    func test() {
      // expected-warning@+1 {{call to main actor-isolated global function 'downgrade()' in a synchronous nonisolated context}}
      downgrade()
    }
  }
}
