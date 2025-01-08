//
//  HomeView.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(connectivityManager.todos) { todo in
                    Text(todo.title)
                }
            }
            .navigationTitle("To-Do List")
        }
    }
}
