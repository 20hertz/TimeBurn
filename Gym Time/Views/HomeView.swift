//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//


import SwiftUI

struct HomeView: View {
    @EnvironmentObject var todoModel: TodoModel
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(todoModel.todos) { todo in
                    Text(todo.title)
                }
                .onDelete(perform: todoModel.deleteTodo)
            }
            .navigationTitle("To-Do List")
            .toolbar {
                NavigationLink("Create", destination: CreateView())
            }
        }
    }
}
