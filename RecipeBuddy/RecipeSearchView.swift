import SwiftUI

struct RecipeSearchView: View {
    @ObservedObject var viewModel: RecipeViewModel
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State private var searchFieldFocused = false
    @State private var searchOffset: CGFloat = 0
    @State private var selectedCategory: String?
    @State private var isPremiumSearch = false
    
    private let categories = [
        ("Quick & Easy", "bolt.fill"),
        ("Vegetarian", "leaf.fill"),
        ("Comfort Food", "house.fill"),
        ("Trending", "flame.fill"),
        ("Healthy", "heart.fill")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header section
                    VStack(alignment: .leading, spacing: 32) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RecipeBuddy")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color.appPrimary)
                            
                            Text("Your personal chef")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 16)
                        
                        // Search section
                        VStack(spacing: 20) {
                            // Search bar with premium toggle
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(Color.appPrimary)
                                            .font(.system(size: 17))
                                        
                                        TextField("What would you like to cook today?", text: $viewModel.searchQuery)
                                            .font(.body)
                                            .textInputAutocapitalization(.never)
                                            .submitLabel(.search)
                                            .onSubmit {
                                                Task { await viewModel.searchRecipe(isPremiumSearch: isPremiumSearch) }
                                            }
                                        
                                        if !viewModel.searchQuery.isEmpty {
                                            Button {
                                                withAnimation {
                                                    viewModel.searchQuery = ""
                                                    viewModel.recipe = nil
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.secondary)
                                                    .font(.system(size: 16))
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                    )
                                    
                                    Button {
                                        Task { await viewModel.searchRecipe(isPremiumSearch: isPremiumSearch) }
                                    } label: {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 38))
                                            .foregroundColor(Color.appPrimary)
                                    }
                                    .disabled(viewModel.searchQuery.isEmpty)
                                    .opacity(viewModel.searchQuery.isEmpty ? 0.5 : 1)
                                }
                                
                                // Premium Search Toggle
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isPremiumSearch.toggle()
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: isPremiumSearch ? "crown.fill" : "crown")
                                            .font(.system(size: 16))
                                            .foregroundStyle(isPremiumSearch ? Color.appPrimary : .secondary)
                                            .symbolEffect(.bounce, value: isPremiumSearch)
                                        
                                        Text(isPremiumSearch ? "Premium Search Active" : "Enable Premium Search")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(isPremiumSearch ? Color.appPrimary : .secondary)
                                        
                                        Spacer()
                                        
                                        if isPremiumSearch {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(Color.appPrimary)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isPremiumSearch ? 
                                                Color.appPrimary.opacity(0.1) : 
                                                Color.secondary.opacity(0.1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        isPremiumSearch ? 
                                                            Color.appPrimary.opacity(0.3) : 
                                                            Color.secondary.opacity(0.2),
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                }
                                
                                if isPremiumSearch {
                                    Text("Premium search includes detailed instructions, wine pairings, and chef's notes")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 4)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            
                            // Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(categories, id: \.0) { category, icon in
                                        CategoryButton(
                                            category: category,
                                            icon: icon,
                                            isSelected: selectedCategory == category
                                        ) {
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedCategory = category
                                                viewModel.searchQuery = category
                                                Task { await viewModel.searchRecipe(isPremiumSearch: isPremiumSearch) }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Dynamic content area
                    if viewModel.isLoading {
                        LoadingView()
                            .transition(.opacity)
                    } else if let recipe = viewModel.recipe {
                        NavigationLink(destination: RecipeView(recipe: recipe)) {
                            RecipeCard(
                                recipe: recipe, 
                                cost: viewModel.lastQueryCost,
                                collectionsViewModel: collectionsViewModel
                            )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(ScaledButtonStyle())
                    } else {
                        EmptyStateView()
                            .transition(.opacity)
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

// Supporting Views...
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.appPrimary)
            Text("Creating your recipe...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// Break out RecipeCard into smaller components
struct RecipeIngredientPreview: View {
    let ingredients: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            ForEach(Array(ingredients.prefix(3)), id: \.self) { ingredient in
                Text("• \(ingredient)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if ingredients.count > 3 {
                Text("and more...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .italic()
            }
        }
    }
}

struct RecipeCostView: View {
    let cost: Double?
    
    var body: some View {
        if let cost = cost {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.appSecondary)
                Text("AI Credits: \(String(format: "%.3f", cost))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct RecipeCard: View {
    let recipe: AIRecipe
    let cost: Double?
    @ObservedObject var collectionsViewModel: CollectionsViewModel
    @State private var showingCollectionSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and save button
            HStack {
                Text(recipe.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
                
                Spacer()
                
                Button {
                    showingCollectionSheet = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.appPrimary)
                }
            }
            
            // Ingredients preview
            RecipeIngredientPreview(
                ingredients: Array(recipe.ingredients.sections.values.joined())
            )
            
            // Cost indicator
            RecipeCostView(cost: cost)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .padding(.horizontal)
        .sheet(isPresented: $showingCollectionSheet) {
            AddToCollectionSheet(recipe: recipe, viewModel: collectionsViewModel)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 44))
                .foregroundStyle(Color.appPrimary)
            
            Text("Ready to Cook?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Search for any dish and I'll create a recipe for you")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct ScaledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct CollectionListItem: View {
    let collection: TheRecipeCollection
    let recipe: AIRecipe
    let viewModel: CollectionsViewModel
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Collection Icon
                CollectionIcon(collection: collection)
                
                // Collection Info
                CollectionInfo(collection: collection)
                
                Spacer()
                
                // Checkmark if recipe exists
                if viewModel.collectionContains(recipe, in: collection) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .imageScale(.large)
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(viewModel.collectionContains(recipe, in: collection))
    }
}

struct CollectionIcon: View {
    let collection: TheRecipeCollection
    
    var body: some View {
        ZStack {
            Circle()
                .fill(collection.isPremiumOnly ? 
                      Color.appPrimary.opacity(0.1) : 
                      .secondary.opacity(0.1))
                .frame(width: 40, height: 40)
            
            Image(systemName: collection.isPremiumOnly ? 
                  "star.fill" : "folder.fill")
                .foregroundStyle(collection.isPremiumOnly ? 
                               Color.appPrimary : .secondary)
        }
    }
}

struct CollectionInfo: View {
    let collection: TheRecipeCollection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(collection.name)
                .font(.headline)
            Text("\(collection.recipes.count) recipes")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct AddToCollectionSheet: View {
    let recipe: AIRecipe
    @ObservedObject var viewModel: CollectionsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingNewCollection = false
    @State private var searchText = ""
    
    private var filteredCollections: [TheRecipeCollection] {
        if searchText.isEmpty {
            return viewModel.collections
        }
        return viewModel.collections.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Recipe Preview
                VStack(spacing: 12) {
                    Text("Add to Collection")
                        .font(.title2.bold())
                    
                    Text(recipe.title)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                
                // Search bar if needed
                if viewModel.collections.count > 5 {
                    SearchBar(text: $searchText)
                }
                
                // Collections list or empty state
                if filteredCollections.isEmpty {
                    EmptyCollectionsView(showingNewCollection: $showingNewCollection)
                } else {
                    CollectionsList(
                        collections: filteredCollections,
                        recipe: recipe,
                        viewModel: viewModel,
                        dismiss: dismiss
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewCollection = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.appPrimary)
                            .font(.system(size: 22))
                    }
                }
            }
            .sheet(isPresented: $showingNewCollection) {
                NewCollectionSheet(
                    viewModel: viewModel,
                    isPresented: $showingNewCollection
                )
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search collections", text: $text)
                .textFieldStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.secondary.opacity(0.1))
        )
        .padding()
    }
}

struct EmptyCollectionsView: View {
    @Binding var showingNewCollection: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label {
                Text("No Collections")
            } icon: {
                Image(systemName: "folder.badge.plus")
                    .foregroundStyle(Color.appPrimary)
            }
        } description: {
            Text("Create a collection to save your recipes")
        } actions: {
            Button(action: { showingNewCollection = true }) {
                Text("Create Collection")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.appPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 40)
    }
}

struct CollectionsList: View {
    let collections: [TheRecipeCollection]
    let recipe: AIRecipe
    let viewModel: CollectionsViewModel
    let dismiss: DismissAction
    
    var body: some View {
        List {
            ForEach(collections) { collection in
                CollectionListItem(
                    collection: collection,
                    recipe: recipe,
                    viewModel: viewModel
                ) {
                    withAnimation {
                        viewModel.addRecipe(recipe, to: collection)
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

// Break out the category button view
struct CategoryButton: View {
    let category: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(category)
                    .font(.system(size: 15, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.appSecondary.opacity(0.3))
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected ? Color.appPrimary.opacity(0.3) : .secondary.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
        .foregroundColor(isSelected ? Color.appPrimary : .primary)
    }
}

#Preview {
    RecipeSearchView(
        viewModel: RecipeViewModel(),
        collectionsViewModel: CollectionsViewModel()
    )
}