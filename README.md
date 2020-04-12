# TypeErasure

This is the project for the April 11, 2020 meetup for Flock of Swifts.

The playground demonstrates how to create a protocol with an `associatedType`, a type eraser, and a variadic generic function that uses the type eraser.

The project shows usage of the `AnyView` type eraser in SwiftUI to return a single concrete type from a function with an opaque return type amd usage of the `AnyPublisher` type eraser in Combine to 1) erase the type and hide implementation details at the API boundary and 2) box heterogenous Publishers with the same `Output` and `Failure` types so that they can be returned on different code paths in a `map` function.