import SwiftUI
import PlaygroundSupport
import Combine

protocol Loadable {
  associatedtype Content
  func load(completion: @escaping (Result<Content, Error>) -> Void)
}

struct LoadableInt: Loadable {
  typealias Content = Int
  func load(completion: @escaping (Result<Content, Error>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now()+delay) { [content] in
      print("\(Self.self) \(content)")
      completion(.success(content))
    }
  }
  var content: Content
  var delay: TimeInterval
}

struct LoadableString: Loadable {
  typealias Content = String
  func load(completion: @escaping (Result<Content, Error>) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now()+delay) { [content] in
      print("\(Self.self) \(content)")
      completion(.success(content))
    }
  }
  var content: Content
  var delay: TimeInterval
}

let a = LoadableInt.init(content: 1, delay: 1)
let b = LoadableString.init(content: "hello", delay: 0.5)

struct AnyLoadable: Loadable {
  typealias Content = Void
  private let _load: (@escaping (Result<Content, Error>) -> Void) -> Void
  init<SomeLoadable: Loadable>(_ loadable: SomeLoadable) {
    _load = { (completion: @escaping (Result<Content, Error>) -> Void) in
      loadable.load { result in
        completion(result.map { _ in () })
      }
    }
  }

  func load(completion: @escaping (Result<Void, Error>) -> Void) {
    _load(completion)
  }
}

extension Loadable {
  func eraseToAnyLoable() -> AnyLoadable {
    AnyLoadable(self)
  }
}

func whenAllLoaded(onLoad: @escaping () -> Void, loadables: AnyLoadable...) {
  let group = DispatchGroup()
  loadables.forEach {
    group.enter()
    $0.load { Void in
      group.leave()
    }
  }
  group.notify(queue: .main) {
    onLoad()
  }
}

whenAllLoaded(onLoad: { print("All done")}, loadables: .init(a), b.eraseToAnyLoable())
