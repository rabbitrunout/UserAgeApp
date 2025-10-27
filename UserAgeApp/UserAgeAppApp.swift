//
//  UserAgeAppApp.swift
//  UserAgeApp
//
//  Created by Irina Saf on 2025-10-27.
//

import SwiftUI
import FirebaseCore

@main
struct UserAgeAppApp: App {
    init() {
           FirebaseApp.configure()
       }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
