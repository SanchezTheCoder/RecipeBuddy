import Foundation

class CollectionsViewModel: ObservableObject {
    @Published var collections: [TheRecipeCollection] = []
    
    func createCollection(name: String, description: String, isPremiumOnly: Bool) {
        let newCollection = TheRecipeCollection(
            name: name,
            description: description,
            isPremiumOnly: isPremiumOnly
        )
        collections.append(newCollection)
    }
    
    func addRecipe(_ recipe: AIRecipe, to collection: TheRecipeCollection) {
        guard let index = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        
        if collections[index].recipes.contains(where: { $0.recipe.id == recipe.id }) {
            return
        }
        
        let savedRecipe = TheRecipeCollection.SavedRecipe(
            id: UUID(),
            recipe: recipe,
            addedAt: Date()
        )
        
        collections[index].recipes.append(savedRecipe)
    }
    
    func collectionContains(_ recipe: AIRecipe, in collection: TheRecipeCollection) -> Bool {
        collection.recipes.contains(where: { $0.recipe.id == recipe.id })
    }
} 