import SwiftUI

extension Color {
    static let appPrimary = Color(red: 124/255, green: 153/255, blue: 135/255) // Sophisticated sage green
    static let appSecondary = Color(red: 198/255, green: 212/255, blue: 206/255) // Light sage
    static let appAccent = Color(red: 76/255, green: 95/255, blue: 83/255) // Deep sage
}

extension LinearGradient {
    static let appGradient = LinearGradient(
        colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ContentView: View {
    @StateObject private var viewModel = RecipeViewModel()
    @StateObject private var collectionsViewModel = CollectionsViewModel()
    
    var body: some View {
        TabView {
            RecipeSearchView(viewModel: viewModel, collectionsViewModel: collectionsViewModel)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            
            CollectionsView(viewModel: collectionsViewModel)
                .tabItem {
                    Label("Collections", systemImage: "folder.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
