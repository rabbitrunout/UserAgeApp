//
//  UserAgeAppApp.swift
//  UserAgeApp
//
//  Created by Douglas Jasper on 2025-10-27.
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
