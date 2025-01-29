//
//  NavigationCoordinator.swift
//  Gym Time
//
//  Created by Stéphane on 2025-01-29.
//

import Foundation

public class NavigationCoordinator: ObservableObject {
    public static let shared = NavigationCoordinator()
    
    @Published public var selectedTimerID: UUID? = nil
    
    private init() {}
    
    public func navigateToTimer(uuidString: String) {
        if let uuid = UUID(uuidString: uuidString) {
            selectedTimerID = uuid
        }
    }
}
