//
//  HMS_Team_3App.swift
//  HMS-Team-3
//
//  Created by Devang Sethi on 11/02/25.
//
import SwiftUI
import Firebase
@main
struct HMS_Team3App: App {
    init() {
            FirebaseApp.configure()
        }
    var body: some Scene {
        WindowGroup {
            GetStartedView()
                .environmentObject(AppointmentManager.shared)
        }
    }
}
