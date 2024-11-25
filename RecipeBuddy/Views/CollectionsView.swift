import SwiftUI

extension CollectionsViewModel {
    func collectionContains(_ recipe: AIRecipe, in collection: TheRecipeCollection) -> Bool {
        collection.recipes.contains(where: { $0.recipe.id == recipe.id })
    }
}

struct CollectionsView: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @State private var showingNewCollection = false
    @State private var showingPremiumInfo = false
    @State private var quickCreateName = ""
    @FocusState private var isQuickCreateFocused: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Collections Header with Premium Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("My Collections")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Button {
                                showingPremiumInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                        
                        Text("Organize your favorite recipes")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Quick Create Collection
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Color.appPrimary)
                                .font(.system(size: 20))
                            
                            TextField("Add Collection", text: $quickCreateName)
                                .font(.system(size: 17))
                                .submitLabel(.done)
                                .focused($isQuickCreateFocused)
                                .onSubmit {
                                    if !quickCreateName.isEmpty {
                                        viewModel.createCollection(
                                            name: quickCreateName,
                                            description: "Created on \(Date().formatted(date: .abbreviated, time: .shortened))",
                                            isPremiumOnly: false
                                        )
                                        quickCreateName = ""
                                        isQuickCreateFocused = false
                                    }
                                }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.05), radius: 2, y: 2)
                        )
                        
                        // Advanced options button with better clarity
                        Button {
                            showingNewCollection = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 20))
                                Text("More")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(Color.appPrimary)
                            .frame(width: 44)
                        }
                        .help("Advanced Collection Options")
                    }
                    .padding(.horizontal)
                    
                    // Collections Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.collections) { collection in
                            EnhancedCollectionCard(collection: collection)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingNewCollection) {
                EnhancedNewCollectionSheet(
                    viewModel: viewModel,
                    isPresented: $showingNewCollection
                )
            }
            .sheet(isPresented: $showingPremiumInfo) {
                PremiumBenefitsView()
            }
        }
    }
}

struct EnhancedCollectionCard: View {
    let collection: TheRecipeCollection
    
    var body: some View {
        NavigationLink(destination: CollectionDetailView(collection: collection)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(collection.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(collection.description)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if collection.isPremiumOnly {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 14))
                    }
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    Label("\(collection.recipes.count)", systemImage: "book.closed")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(collection.updatedAt.formatted(.relative(presentation: .named)))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedNewCollectionSheet: View {
    @ObservedObject var viewModel: CollectionsViewModel
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var description = ""
    @State private var isPremiumOnly = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header with animation
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.appPrimary)
                    }
                    .padding(.top, 20)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    EnhancedTextField(
                        title: "Collection Name",
                        text: $name,
                        placeholder: "e.g., Weekend Favorites",
                        focused: focusedField == .name
                    )
                    .focused($focusedField, equals: .name)
                    
                    EnhancedTextField(
                        title: "Description",
                        text: $description,
                        placeholder: "What's special about this collection?",
                        focused: focusedField == .description
                    )
                    .focused($focusedField, equals: .description)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $isPremiumOnly) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.appPrimary)
                                Text("Premium Collection")
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                        .tint(Color.appPrimary)
                        
                        if isPremiumOnly {
                            Text("Premium collections include AI-powered organization and smart features")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 52)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: createCollection) {
                    Text("Create Collection")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    name.isEmpty ? 
                                        AnyShapeStyle(Color.gray) : 
                                        AnyShapeStyle(
                                            LinearGradient(
                                                colors: [.appPrimary, .appAccent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        )
                            .shadow(
                                color: Color.appPrimary.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                            .padding(.horizontal)
                }
                .disabled(name.isEmpty)
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func createCollection() {
        viewModel.createCollection(
            name: name,
            description: description,
            isPremiumOnly: isPremiumOnly
        )
        isPresented = false
    }
}

struct PremiumBenefitsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Premium Header with Animation
                    VStack(spacing: 16) {
                        ZStack {
                            // Animated background circles
                            Circle()
                                .fill(Color.appPrimary.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(1.2)
                                .blur(radius: 2)
                            
                            Circle()
                                .fill(Color.appSecondary.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .scaleEffect(1.1)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.appPrimary, .appAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.bounce)
                        }
                        .padding(.top, 20)
                        
                        Text("Premium Experience")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color.appPrimary)
                        
                        Text("Elevate your culinary journey")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Benefits List with Animations
                    VStack(alignment: .leading, spacing: 24) {
                        PremiumFeature(
                            icon: "wand.and.stars",
                            title: "AI-Powered Scaling",
                            description: "Perfect portions for any group size",
                            delay: 0.1
                        )
                        
                        PremiumFeature(
                            icon: "person.2.crop.square.stack.fill",
                            title: "Smart Collections",
                            description: "Organize recipes with AI assistance",
                            delay: 0.2
                        )
                        
                        PremiumFeature(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Ingredient Substitutions",
                            description: "Smart alternatives for any recipe",
                            delay: 0.3
                        )
                        
                        PremiumFeature(
                            icon: "sparkles",
                            title: "Wine Pairings",
                            description: "Expert wine recommendations",
                            delay: 0.4
                        )
                        
                        PremiumFeature(
                            icon: "chart.bar.fill",
                            title: "Nutritional Insights",
                            description: "Detailed nutritional information",
                            delay: 0.5
                        )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .shadow(
                                color: Color.appPrimary.opacity(0.1),
                                radius: 10,
                                x: 0,
                                y: 5
                            )
                    )
                    .padding(.horizontal)
                    
                    // Premium CTA
                    VStack(spacing: 12) {
                        Button(action: {
                            // Premium upgrade action
                            dismiss()
                        }) {
                            HStack {
                                Text("Upgrade Now")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.appPrimary, .appAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(
                                color: Color.appPrimary.opacity(0.3),
                                radius: 8,
                                y: 4
                            )
                        }
                        
                        Text("7-day free trial • Cancel anytime")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PremiumFeature: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
} 