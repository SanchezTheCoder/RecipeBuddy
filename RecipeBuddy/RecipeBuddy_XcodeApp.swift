import SwiftUI

@main
struct RecipeBuddy_XcodeApp: App {
    init() {
        // Set your API key here once
        do {
            try KeychainManager.save(apiKey: "your-api-key-here")
        } catch {
            print("Failed to save API key:", error)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 