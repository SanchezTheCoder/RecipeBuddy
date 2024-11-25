import SwiftUI

@main
struct RecipeBuddy_XcodeApp: App {
    init() {
        setupApiKey()
    }
    
    private func setupApiKey() {
        // Only try to save API key if it hasn't been saved before
        if !KeychainManager.hasApiKey() {
            if let apiKey = ProcessInfo.processInfo.environment["RECIPE_BUDDY_API_KEY"] {
                do {
                    try KeychainManager.save(apiKey: apiKey)
                    print("Successfully saved API key to Keychain")
                } catch KeychainError.duplicateEntry {
                    // Try to update instead
                    do {
                        try KeychainManager.updateApiKey(apiKey)
                        print("Successfully updated API key in Keychain")
                    } catch {
                        print("Failed to update API key:", error)
                    }
                } catch {
                    print("Failed to save API key:", error)
                }
            } else {
                print("Warning: API key not found in environment variables")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
} 