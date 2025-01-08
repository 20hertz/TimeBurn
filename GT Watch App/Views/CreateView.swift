//
//  CreateView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//


import SwiftUI

struct CreateView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var todoModel: TodoModel
    @State private var title: String = ""
    
    var body: some View {
        Form {
            TextField("Title", text: $title)
            Button("Add") {
                todoModel.addTodo(title: title)
                dismiss()
            }
            .disabled(title.isEmpty)
        }
        .navigationTitle("Create To-Do")
    }
}