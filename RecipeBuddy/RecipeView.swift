import SwiftUI

struct RecipeView: View {
    @State private var servings: Int
    let recipe: AIRecipe
    
    init(recipe: AIRecipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.servingSize)
        print("DEBUG: View received chef notes:", recipe.chefNotes ?? [])
        print("DEBUG: View received wine pairings:", recipe.winePairings ?? [])
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title and Timing Info
                VStack(spacing: 16) {
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Timing and Difficulty
                    HStack(spacing: 16) {
                        TimingPill(icon: "clock", label: "Prep", time: recipe.prepTime)
                        TimingPill(icon: "flame", label: "Cook", time: recipe.cookTime)
                        TimingPill(icon: "timer", label: "Total", time: recipe.totalTime)
                    }
                    
                    DifficultyBadge(rating: recipe.difficultyRating)
                }
                .padding(.horizontal)
                
                // Serving Size Control
                ServingSizeControl(
                    servings: $servings,
                    originalServings: recipe.servingSize
                )
                .padding(.horizontal)
                
                // Required Equipment
                if !recipe.equipment.isEmpty {
                    EquipmentSection(equipment: recipe.equipment)
                        .padding(.horizontal)
                }
                
                // Ingredients
                IngredientsSection(
                    ingredients: recipe.ingredients,
                    servings: servings,
                    originalServings: recipe.servingSize
                )
                .padding(.horizontal)
                
                // Instructions
                InstructionsSection(instructions: recipe.instructions)
                    .padding(.horizontal)
                
                // Plating Instructions
                if let plating = recipe.plating,
                   !plating.sections.isEmpty {
                    PlatingSection(plating: plating)
                        .padding(.horizontal)
                }
                
                // Chef's Notes
                if let notes = recipe.chefNotes,
                   !notes.isEmpty {
                    ChefNotesSection(notes: notes)
                        .padding(.horizontal)
                }
                
                // Wine Pairings
                if let pairings = recipe.winePairings,
                   !pairings.isEmpty {
                    WinePairingsSection(pairings: pairings)
                        .padding(.horizontal)
                }
                
                // Nutrition Info
                NutritionSection(nutrition: recipe.nutrition)
                    .padding(.horizontal)
                
                // Tags
                if !recipe.tags.isEmpty {
                    TagsSection(tags: recipe.tags)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Supporting Views
struct TimingPill: View {
    let icon: String
    let label: String
    let time: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct DifficultyBadge: View {
    let rating: AIRecipe.DifficultyRating
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rating.level)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.appPrimary)
                
                Spacer()
                
                Text("?")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.appPrimary))
            }
            
            Text(rating.rationale)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Supporting Views for Recipe Details
struct IngredientsSection: View {
    let ingredients: AIRecipeSection
    let servings: Int
    let originalServings: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ingredients")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            // Process each subsection
            ForEach(Array(ingredients.sections.sorted(by: { $0.key < $1.key })), id: \.key) { sectionName, items in
                VStack(alignment: .leading, spacing: 12) {
                    Text(sectionName)  // Use the exact section name from GPT
                        .font(.headline)
                        .foregroundStyle(Color.appSecondary)
                    
                    ForEach(items, id: \.self) { ingredient in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(Color.appPrimary)
                                .padding(.top, 8)
                            
                            Text(scaleIngredient(ingredient))
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func scaleIngredient(_ ingredient: String) -> String {
        // First, check if the ingredient contains a number
        let pattern = #"(\d+(?:/\d+)?(?:\.\d+)?)\s*([a-zA-Z]+)?(.*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: ingredient, range: NSRange(ingredient.startIndex..<ingredient.endIndex, in: ingredient)) else {
            return ingredient // Return original if no number found
        }
        
        // Extract the components
        let originalString = ingredient[Range(match.range(at: 1), in: ingredient)!]
        
        // Handle fractions
        let originalNumber: Double
        if originalString.contains("/") {
            let parts = originalString.split(separator: "/")
            if parts.count == 2,
               let numerator = Double(parts[0]),
               let denominator = Double(parts[1]) {
                originalNumber = numerator / denominator
            } else {
                return ingredient
            }
        } else {
            guard let number = Double(originalString) else {
                return ingredient
            }
            originalNumber = number
        }
        
        // Calculate scaled number
        let scaledNumber = originalNumber * Double(servings) / Double(originalServings)
        
        // Get unit and remainder
        let unit = match.range(at: 2).location != NSNotFound ?
            ingredient[Range(match.range(at: 2), in: ingredient)!] : ""
        let remainder = match.range(at: 3).location != NSNotFound ?
            ingredient[Range(match.range(at: 3), in: ingredient)!] : ""
        
        // Format the number
        let formattedNumber = formatNumber(scaledNumber)
        
        // Always add a space between number and unit
        let unitWithSpace = unit.isEmpty ? "" : " \(unit)"
        
        // Reconstruct the ingredient string
        return "\(formattedNumber)\(unitWithSpace)\(remainder)"
    }
    
    private func formatNumber(_ number: Double) -> String {
        // Handle common fractions
        let fractions: [(threshold: Double, fraction: String)] = [
            (0.25, "1/4"),
            (0.33, "1/3"),
            (0.5, "1/2"),
            (0.67, "2/3"),
            (0.75, "3/4")
        ]
        
        let wholePart = floor(number)
        let fractionalPart = number.truncatingRemainder(dividingBy: 1)
        
        if fractionalPart == 0 {
            return String(format: "%.0f", number)
        }
        
        // For small numbers, try to use fractions
        if number < 5 {
            for (threshold, fraction) in fractions {
                if abs(fractionalPart - threshold) < 0.01 {
                    if wholePart == 0 {
                        return fraction
                    } else {
                        return "\(Int(wholePart)) \(fraction)"
                    }
                }
            }
        }
        
        // For larger numbers, show one decimal place
        return String(format: "%.1f", number)
    }
}

struct InstructionsSection: View {
    let instructions: AIRecipeSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Instructions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            // Process each subsection
            ForEach(Array(instructions.sections.sorted(by: { $0.key < $1.key })), id: \.key) { sectionName, steps in
                VStack(alignment: .leading, spacing: 12) {
                    Text(sectionName)  // Use the exact section name from GPT
                        .font(.headline)
                        .foregroundStyle(Color.appSecondary)
                    
                    ForEach(Array(steps.enumerated()), id: \.element) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.appPrimary)
                                .frame(width: 24, alignment: .center)
                            
                            Text(step)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct EquipmentSection: View {
    let equipment: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Equipment Needed")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(equipment.filter { !$0.isEmpty }, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.top, 8)
                        
                        Text(item)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct NutritionSection: View {
    let nutrition: AIRecipe.NutritionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Facts")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            HStack(spacing: 16) {
                NutritionPill(label: "Calories", value: nutrition.calories)
                NutritionPill(label: "Protein", value: nutrition.protein)
                NutritionPill(label: "Carbs", value: nutrition.carbohydrates)
                NutritionPill(label: "Fat", value: nutrition.fat)
            }
        }
    }
}

struct NutritionPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct TagsSection: View {
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Color.appPrimary)
                Text("Tags")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimary)
            }
            
            FlowLayout(spacing: 10) {
                ForEach(tags.sorted(), id: \.self) { tag in
                    TagPill(text: tag)
                }
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TagPill: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.appPrimary.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Text(text)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(Color.appPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.appPrimary.opacity(0.15))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appPrimary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// Custom FlowLayout that wraps content
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            width: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            width: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, frame) in result.frames {
            let position = CGPoint(
                x: bounds.minX + frame.minX,
                y: bounds.minY + frame.minY
            )
            subviews[index].place(at: position, proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [(index: Int, frame: CGRect)] = []
        
        init(width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            var row: [(Int, CGRect)] = []
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width, !row.isEmpty {
                    // Move to next row
                    frames.append(contentsOf: row)
                    row.removeAll()
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                row.append((index, CGRect(x: x, y: y, width: size.width, height: size.height)))
                x += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }
            
            frames.append(contentsOf: row)
            size = CGSize(width: width, height: y + maxHeight)
        }
    }
}

// Add these sections after the existing supporting views

struct PlatingSection: View {
    let plating: AIRecipeSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Plating & Presentation")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            ForEach(Array(plating.sections.values.joined()), id: \.self) { step in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.up.forward")
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 14))
                        .padding(.top, 4)
                    
                    Text(step)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ChefNotesSection: View {
    let notes: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chef's Notes")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            ForEach(notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 14))
                        .padding(.top, 4)
                    
                    Text(note)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WinePairingsSection: View {
    let pairings: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wine Pairings")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.appPrimary)
            
            ForEach(pairings, id: \.self) { pairing in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "wineglass.fill")
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 14))
                        .padding(.top, 4)
                    
                    Text(pairing)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color.appSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        RecipeView(recipe: AIRecipe(
            title: "Spaghetti Carbonara",
            servingSize: 4,
            prepTime: "15 mins",
            cookTime: "20 mins",
            totalTime: "35 mins",
            ingredients: AIRecipeSection(sections: [
                "Main": ["400g spaghetti", "200g guanciale", "4 large eggs", "100g Pecorino Romano", "Black pepper"]
            ]),
            instructions: AIRecipeSection(sections: [
                "Preparation": ["Boil pasta", "Cook guanciale", "Mix eggs and cheese", "Combine all ingredients"]
            ]),
            plating: AIRecipeSection(sections: [
                "Presentation": ["Twirl pasta into a nest", "Garnish with extra cheese"]
            ]),
            difficultyRating: .init(
                level: "Medium",
                rationale: "Requires timing and technique for egg sauce"
            ),
            nutrition: .init(
                calories: "850",
                protein: "35g",
                carbohydrates: "80g",
                fat: "45g"
            ),
            equipment: ["Large pot", "Pan", "Tongs"],
            tags: ["Italian", "Pasta", "Quick", "Classic"],
            chefNotes: ["Use room temperature eggs", "Reserve pasta water"],
            winePairings: ["Dry white wine", "Light-bodied red wine"]
        ))
    }
}
