//
//  WatchConnectivityManager.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-07.
//

import WatchConnectivity
import Combine

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    
    static let shared = WatchConnector()
    
    @Published var todos: [Todo] = [] {
        didSet {
            saveTodos()
        }
    }
    
    private let storageKey = "todos"
    private let appGroupID = "group.com.slo.Gym-Time"
    
    private override init() {
        super.init()
        loadTodos() // Load todos from shared storage
        activateSession() // Activate WCSession
    }
    
    // MARK: - Persistence
    private func saveTodos() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("Error: Shared UserDefaults not available.")
            return
        }
        do {
            let data = try JSONEncoder().encode(todos)
            sharedDefaults.set(data, forKey: storageKey)
        } catch {
            print("Error saving todos: \(error.localizedDescription)")
        }
    }
    
    private func loadTodos() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID),
              let data = sharedDefaults.data(forKey: storageKey) else { return }
        do {
            todos = try JSONDecoder().decode([Todo].self, from: data)
        } catch {
            print("Error loading todos: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WatchConnectivity
    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func send(todos: [Todo]) {
        guard WCSession.default.isReachable else { return }
        do {
            let data = try JSONEncoder().encode(todos)
            WCSession.default.sendMessage(["todos": data], replyHandler: nil, errorHandler: nil)
        } catch {
            print("Error encoding todos: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message["todos"] as? Data else { return }
        do {
            let receivedTodos = try JSONDecoder().decode([Todo].self, from: data)
            DispatchQueue.main.async {
                self.todos = receivedTodos
            }
        } catch {
            print("Error decoding todos: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
