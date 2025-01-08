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
    
    @Published var timers: [Timer] = [] {
        didSet {
            saveTimers()
        }
    }
    
    private let storageKey = "timers"
    private let appGroupID = "group.com.slo.Gym-Time"
    
    private override init() {
        super.init()
        loadTimers()
        activateSession()
    }
    
    // MARK: - Persistence
    private func saveTimers() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("Error: Shared UserDefaults not available.")
            return
        }
        do {
            let data = try JSONEncoder().encode(timers)
            sharedDefaults.set(data, forKey: storageKey)
        } catch {
            print("Error saving timers: \(error.localizedDescription)")
        }
    }
    
    private func loadTimers() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID),
              let data = sharedDefaults.data(forKey: storageKey) else {
            print("No timers found in shared UserDefaults.")
            return
        }
        do {
            timers = try JSONDecoder().decode([Timer].self, from: data)
        } catch {
            print("Error loading timers: \(error.localizedDescription)")
        }
    }
    
    // MARK: - WatchConnectivity
    private func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
    
    func send(timers: [Timer]) {
        guard WCSession.default.isReachable else {
            print("WCSession not reachable.")
            return
        }
        do {
            let data = try JSONEncoder().encode(timers)
            WCSession.default.sendMessage(["timers": data], replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        } catch {
            print("Error encoding timers: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let data = message["timers"] as? Data else { return }
        do {
            let receivedTimers = try JSONDecoder().decode([Timer].self, from: data)
            DispatchQueue.main.async {
                self.timers = receivedTimers
            }
        } catch {
            print("Error decoding timers: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Activation error: \(error.localizedDescription)")
        }
    }
    
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive.")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated, reactivating.")
        session.activate()
    }
    #endif
}
