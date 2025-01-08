//
//  TodoModel.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-08.
//


import Foundation
import Combine

struct Todo: Identifiable, Codable {
    let id: UUID
    var title: String
}

class TodoModel: ObservableObject {
    @Published var todos: [Todo] = [] {
        didSet {
            syncWithWatch()
            WatchConnector.shared.todos = todos // Persist todos
        }
    }
    
    init() {
        // Load persisted todos from WatchConnectivityManager
        todos = WatchConnector.shared.todos
    }
    
    func addTodo(title: String) {
        let newTodo = Todo(id: UUID(), title: title)
        todos.append(newTodo)
    }
    
    func deleteTodo(at offsets: IndexSet) {
        todos.remove(atOffsets: offsets)
    }
    
    private func syncWithWatch() {
        #if os(iOS)
        WatchConnector.shared.send(todos: todos)
        #endif
    }
}
