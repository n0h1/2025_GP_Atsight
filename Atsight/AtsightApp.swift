//
//  AtsightApp.swift
//  Atsight
//
//  Created by lona on 28/01/2025.
//

import SwiftUI
import Firebase

@main
struct AtsightApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Keep the StateObject for the app's lifetime state
    @StateObject var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            // Use the RootView and provide the appState to its environment
                RootView()
                    .environmentObject(appState)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
                    .id(appState.isLoggedIn)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAuthScreen = false

    var body: some View {
        MainView()
            .onChange(of: appState.isLoggedIn) { oldValue, newValue in
                showAuthScreen = !newValue
            }
            .fullScreenCover(isPresented: $showAuthScreen) {
                ContentView()
                    .environmentObject(appState)
            }
            .onAppear {
                showAuthScreen = !appState.isLoggedIn
            }
    }
}




class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("succeeded FIREBASE!!!!!!!")
        return true
    }
}
