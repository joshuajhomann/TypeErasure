//
//  ContentView.swift
//  TypeErasure
//
//  Created by Joshua Homann on 4/10/20.
//  Copyright © 2020 com.josh. All rights reserved.
//

import SwiftUI
import Combine
import MapKit

enum LoadingState {
  case notSearching, loading, loaded([MKMapItem]), empty, error(Error)
}

final class Model: ObservableObject {
  @Published var searchTerm: String = ""
  @Published private (set) var loadingState: LoadingState = .empty

  private var subscriptions: Set<AnyCancellable> = []
  init() {
   makeItemPublisher()
   .assign(to: \.loadingState, on: self)
   .store(in: &subscriptions)
  }

  private func makeItemPublisher() -> AnyPublisher<LoadingState, Never> {
    $searchTerm
    .debounce(for: .milliseconds(250), scheduler: RunLoop.main)
    .removeDuplicates()
    .map { term -> AnyPublisher<LoadingState, Never> in
      guard !term.isEmpty else {
        return Just(.notSearching).eraseToAnyPublisher()
      }
      return Future<LoadingState, Never> { promise in
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = term
        MKLocalSearch(request: searchRequest).start { response, error in
          if let error = error {
            return (error as NSError).code == 4
              ? promise(.success(.empty))
              : promise(.success(.error(error)))
          }
          let items = response?.mapItems ?? []
          promise(.success(items.isEmpty ? .empty : .loaded(items)))
        }
      }
      .prepend(.loading)
      .eraseToAnyPublisher()
    }
    .switchToLatest()
    .receive(on: RunLoop.main)
    .eraseToAnyPublisher()

  }
}


struct ContentView: View {
  @ObservedObject var model: Model = .init()
  var body: some View {
    VStack {
      HStack {
        Image(systemName: "magnifyingglass")
        TextField("Search", text: $model.searchTerm)
      }
      .font(.headline)
      .padding()
      .border(Color.black)
      Spacer()
      self.viewFromState().font(.title)
      Spacer()
    }
    .padding()
  }

  private func viewFromState() -> some View {
    switch model.loadingState {
    case .notSearching:
      return Text("Type in a search above").eraseToAnyView()
    case .empty:
      return Text("There are no results").eraseToAnyView()
    case .error(let error):
      return Text("Something went wrong...\n\(error.localizedDescription)")
        .multilineTextAlignment(.center)
        .eraseToAnyView()
    case .loading:
      return Text("Loading").eraseToAnyView()
    case .loaded(let items):
      return List(items, id: \.name) { item in
        VStack(alignment: .leading) {
          Text(item.name ?? "").font(.headline)
          Text([item.phoneNumber, item.url?.absoluteString].compactMap{$0}.joined(separator: "\n")).font(.body)
          Text(item.placemark.title ?? "")
        }
      }
      .eraseToAnyView()
    }
  }
}

extension View {
  func eraseToAnyView() -> AnyView {
    AnyView(self)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
