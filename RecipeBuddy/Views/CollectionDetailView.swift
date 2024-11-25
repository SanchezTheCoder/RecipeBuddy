import SwiftUI

struct CollectionDetailView: View {
    let collection: TheRecipeCollection
    
    var body: some View {
        List {
            if !collection.description.isEmpty {
                Section {
                    Text(collection.description)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("About")
                }
            }
            
            Section {
                if collection.recipes.isEmpty {
                    ContentUnavailableView {
                        Label("No Recipes", systemImage: "book.closed")
                    } description: {
                        Text("Add recipes to this collection to see them here")
                    }
                } else {
                    ForEach(collection.recipes) { savedRecipe in
                        NavigationLink {
                            RecipeView(recipe: savedRecipe.recipe)
                        } label: {
                            RecipeRow(savedRecipe: savedRecipe)
                        }
                    }
                }
            } header: {
                Text("Recipes")
            } footer: {
                if !collection.recipes.isEmpty {
                    Text("\(collection.recipes.count) recipes")
                }
            }
        }
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct RecipeRow: View {
    let savedRecipe: TheRecipeCollection.SavedRecipe
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(savedRecipe.recipe.title)
                .font(.headline)
            
            HStack(spacing: 12) {
                Label("\(savedRecipe.recipe.ingredients.totalItems)", systemImage: "basket")
                Label("\(savedRecipe.recipe.instructions.totalItems)", systemImage: "list.bullet")
                if let winePairings = savedRecipe.recipe.winePairings, !winePairings.isEmpty {
                    Label("\(winePairings.count)", systemImage: "wineglass")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        CollectionDetailView(collection: TheRecipeCollection(
            name: "Italian Favorites",
            description: "My favorite Italian recipes",
            isPremiumOnly: false
        ))
    }
} 