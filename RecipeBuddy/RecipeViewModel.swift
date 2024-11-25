import SwiftUI

// MARK: - Models
enum RecipeError: Error {
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to process recipe: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid data received"
        }
    }
}

enum RecipeModel: String {
    case basic = "gpt-3.5-turbo-0125"
    case premium = "gpt-4-0125-preview"
    
    var costPerInputToken: Double {
        switch self {
        case .basic: return 0.5 / 1_000_000
        case .premium: return 10.0 / 1_000_000
        }
    }
    
    var costPerOutputToken: Double {
        switch self {
        case .basic: return 1.5 / 1_000_000
        case .premium: return 30.0 / 1_000_000
        }
    }
}

// MARK: - Markdown Parser
struct MarkdownSection {
    let title: String
    var content: [String]
    var subsections: [MarkdownSection]
    let level: Int  // ### = 3, #### = 4, etc.
}

class MarkdownParser {
    private let text: String
    
    init(text: String) {
        self.text = text
    }
    
    func parse() -> [MarkdownSection] {
        var sections: [MarkdownSection] = []
        var currentMainSection: MarkdownSection?
        var currentSubsections: [MarkdownSection] = []
        var contentBuffer: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if let (level, title) = extractSectionHeader(from: trimmed) {
                if level == 3 { // Main section (###)
                    // Save previous main section if exists
                    if let mainSection = currentMainSection {
                        // Save any remaining content buffer to the last subsection
                        if !contentBuffer.isEmpty && !currentSubsections.isEmpty {
                            let lastIndex = currentSubsections.count - 1
                            let updatedSubsection = MarkdownSection(
                                title: currentSubsections[lastIndex].title,
                                content: contentBuffer,
                                subsections: [],
                                level: currentSubsections[lastIndex].level
                            )
                            currentSubsections[lastIndex] = updatedSubsection
                        }
                        
                        let updatedSection = MarkdownSection(
                            title: mainSection.title,
                            content: currentSubsections.isEmpty ? contentBuffer : mainSection.content,
                            subsections: currentSubsections,
                            level: mainSection.level
                        )
                        sections.append(updatedSection)
                    }
                    
                    // Start new main section
                    currentMainSection = MarkdownSection(
                        title: title,
                        content: [],
                        subsections: [],
                        level: level
                    )
                    currentSubsections = []
                    contentBuffer = []
                    
                } else if level == 4 { // Subsection (####)
                    // Save content buffer to previous subsection if exists
                    if !contentBuffer.isEmpty && !currentSubsections.isEmpty {
                        let lastIndex = currentSubsections.count - 1
                        let updatedSubsection = MarkdownSection(
                            title: currentSubsections[lastIndex].title,
                            content: contentBuffer,
                            subsections: [],
                            level: currentSubsections[lastIndex].level
                        )
                        currentSubsections[lastIndex] = updatedSubsection
                    }
                    
                    // Start new subsection
                    currentSubsections.append(MarkdownSection(
                        title: title,
                        content: [],
                        subsections: [],
                        level: level
                    ))
                    contentBuffer = []
                }
            } else if !trimmed.isEmpty {
                contentBuffer.append(trimmed)
            }
        }
        
        // Handle the final section
        if let mainSection = currentMainSection {
            // Save any remaining content buffer to the last subsection
            if !contentBuffer.isEmpty && !currentSubsections.isEmpty {
                let lastIndex = currentSubsections.count - 1
                let updatedSubsection = MarkdownSection(
                    title: currentSubsections[lastIndex].title,
                    content: contentBuffer,
                    subsections: [],
                    level: currentSubsections[lastIndex].level
                )
                currentSubsections[lastIndex] = updatedSubsection
            }
            
            let finalSection = MarkdownSection(
                title: mainSection.title,
                content: currentSubsections.isEmpty ? contentBuffer : mainSection.content,
                subsections: currentSubsections,
                level: mainSection.level
            )
            sections.append(finalSection)
        }
        
        return sections
    }
    
    private func extractSectionHeader(from line: String) -> (level: Int, title: String)? {
        // Match both ### Title and #### For the Component: formats
        let pattern = "^(#{3,4})\\s*([^:]+)(:)?\\s*(.*)?"
        
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else {
            return nil
        }
        
        if let levelRange = Range(match.range(at: 1), in: line),
           let titleRange = Range(match.range(at: 2), in: line) {
            let level = line[levelRange].count
            var title = String(line[titleRange]).trimmingCharacters(in: .whitespaces)
            
            // Include content after colon if present
            if let contentRange = Range(match.range(at: 4), in: line) {
                let content = String(line[contentRange]).trimmingCharacters(in: .whitespaces)
                if !content.isEmpty {
                    title = "\(title): \(content)"
                }
            }
            
            return (level, title)
        }
        
        return nil
    }
}

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var recipe: AIRecipe?
    @Published var isLoading = false
    @Published var error: String?
    @Published var isPremium = false
    @Published var lastQueryCost: Double = 0
    
    private var totalCost: Double = 0
    private var apiKey: String {
        guard let key = KeychainManager.getApiKey() else {
            print("DEBUG: Failed to get API key")
            return ""
        }
        return key
    }
    
    private var currentModel: RecipeModel {
        isPremium ? .premium : .basic
    }
    
    // Move extractSection to class level
    private func extractSection(_ marker: String, until endMarker: String? = nil, from text: String) -> String {
        print("DEBUG: Extracting section with marker: '\(marker)'")
        
        // Normalize markers by removing colons and converting to lowercase
        let normalizedMarker = marker
            .replacingOccurrences(of: ":", with: "")
            .lowercased()
        
        let lines = text.components(separatedBy: .newlines)
        var content: [String] = []
        var isInSection = false
        var foundSection = false
        
        // Try different header formats
        let headerFormats = ["###", "####", "**"]
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            let normalizedLine = trimmedLine
                .replacingOccurrences(of: ":", with: "")
                .lowercased()
            
            // Check for section start with any header format
            if !foundSection {
                for format in headerFormats {
                    let possibleMarker = "\(format) \(normalizedMarker)"
                    if normalizedLine.hasPrefix(possibleMarker) {
                        print("DEBUG: Found section start with format '\(format)': '\(line)'")
                        isInSection = true
                        foundSection = true
                        break
                    }
                }
                continue
            }
            
            // Check for section end
            if isInSection {
                var shouldBreak = false
                
                if let endMarker = endMarker {
                    // Check for specific end marker
                    for format in headerFormats {
                        if normalizedLine.hasPrefix("\(format) \(endMarker.lowercased())") {
                            print("DEBUG: Found specified end marker: '\(line)'")
                            shouldBreak = true
                            break
                        }
                    }
                } else {
                    // Check for any new section
                    for format in headerFormats {
                        if normalizedLine.hasPrefix(format) {
                            print("DEBUG: Found next section: '\(line)'")
                            shouldBreak = true
                            break
                        }
                    }
                }
                
                if shouldBreak {
                    break
                }
                
                // Collect content
                if !trimmedLine.isEmpty {
                    // Clean up the line
                    var cleanedLine = trimmedLine
                    
                    // Remove bullet points and asterisks
                    if cleanedLine.hasPrefix("-") {
                        cleanedLine = cleanedLine.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                    }
                    cleanedLine = cleanedLine.replacingOccurrences(of: "\\*\\*", with: "", options: .regularExpression)
                    
                    print("DEBUG: Adding line to section: '\(cleanedLine)'")
                    content.append(cleanedLine)
                }
            }
        }
        
        let result = content.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        print("DEBUG: Extracted content: '\(result)'")
        
        // If nothing found, try fallback search
        if result.isEmpty {
            print("DEBUG: Attempting fallback search for content")
            let fallbackResult = fallbackSearch(for: normalizedMarker, in: text)
            print("DEBUG: Fallback search result: '\(fallbackResult)'")
            return fallbackResult
        }
        
        return result
    }
    
    private func fallbackSearch(for marker: String, in text: String) -> String {
        // Try to find content by looking for keywords
        let keywords = marker.components(separatedBy: .whitespaces)
        let lines = text.components(separatedBy: .newlines)
        
        for (index, line) in lines.enumerated() {
            let normalizedLine = line.lowercased()
            if keywords.allSatisfy({ normalizedLine.contains($0) }) {
                // Found a matching line, collect following content until next section
                var content: [String] = []
                var currentIndex = index + 1
                
                while currentIndex < lines.count {
                    let nextLine = lines[currentIndex]
                    if nextLine.hasPrefix("#") || nextLine.hasPrefix("**") {
                        break
                    }
                    if !nextLine.isEmpty {
                        content.append(nextLine.trimmingCharacters(in: .whitespaces))
                    }
                    currentIndex += 1
                }
                
                return content.joined(separator: "\n")
            }
        }
        
        return ""
    }
    
    func searchRecipe(isPremiumSearch: Bool = false) async {
        self.isPremium = isPremiumSearch
        guard !searchQuery.isEmpty else { return }
        
        withAnimation {
            isLoading = true
            recipe = nil
            error = nil
        }
        
        do {
            print("DEBUG: Starting recipe search for '\(searchQuery)' (Premium: \(isPremiumSearch))")
            let recipe = try await fetchRecipe()
            
            withAnimation {
                self.recipe = recipe
                self.isLoading = false
            }
            
        } catch {
            print("DEBUG: Recipe search failed:", error.localizedDescription)
            withAnimation {
                self.isLoading = false
                self.error = error.localizedDescription
            }
        }
    }
    
    private func fetchRecipe() async throws -> AIRecipe {
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let requestBody: [String: Any] = [
            "model": currentModel.rawValue,
            "messages": [
                ["role": "system", "content": AIPrompts.systemPrompt],
                ["role": "user", "content": AIPrompts.generateUserPrompt(query: searchQuery, isPremium: isPremium)]
            ],
            "temperature": 0.8,
            "max_tokens": isPremium ? 2000 : 1500
        ]
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("DEBUG: Sending API request...")
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let response = try JSONDecoder().decode(AIAPIResponse.self, from: data)
        guard let content = response.choices.first?.message.content else {
            print("DEBUG: No content in response")
            throw RecipeError.invalidResponse
        }
        
        print("DEBUG: Received markdown response")
        print("DEBUG: Raw markdown content:")
        print("----------------------------------------")
        print(content)
        print("----------------------------------------")
        
        print("DEBUG: Parsing markdown into recipe model...")
        let recipe = try parseMarkdownToRecipe(content)
        
        // Calculate and update cost
        let cost = calculateCost(
            inputTokens: response.tokenMetrics.promptTokens,
            outputTokens: response.tokenMetrics.completionTokens
        )
        lastQueryCost = cost
        totalCost += cost
        
        return recipe
    }
    
    private func parseMarkdownToRecipe(_ markdown: String) throws -> AIRecipe {
        print("DEBUG: Starting markdown parsing...")
        
        let parser = MarkdownParser(text: markdown)
        let sections = parser.parse()
        
        // Extract title with better handling
        let title = sections.first { section in
                section.title.lowercased() == "title"
            }?.content.first?.trimmingCharacters(in: .whitespaces) ?? ""
        
        print("\nDEBUG: Extracted Recipe Model:")
        print("----------------------------------------")
        print("Title:", title)
        
        // Find ingredients and instructions sections
        let ingredientsSection = sections.first { $0.title.lowercased() == "ingredients" }
        let instructionsSection = sections.first { $0.title.lowercased() == "instructions" }
        
        print("DEBUG: Found ingredients section:", ingredientsSection?.subsections.map { $0.title } ?? [])
        print("DEBUG: Found instructions section:", instructionsSection?.subsections.map { $0.title } ?? [])
        
        // Create recipe model
        let recipe = AIRecipe(
            title: title,
            servingSize: parseServingSize(from: getSection("Serving Size", in: sections)),
            prepTime: getSection("Prep Time", in: sections)?.content.first ?? "",
            cookTime: getSection("Cook Time", in: sections)?.content.first ?? "",
            totalTime: getSection("Total Time", in: sections)?.content.first ?? "",
            ingredients: parseIngredients(from: ingredientsSection),
            instructions: parseInstructions(from: instructionsSection),
            plating: parsePlating(from: getSection("Plating", in: sections)),
            difficultyRating: parseDifficulty(from: getSection("Difficulty Rating", in: sections)),
            nutrition: parseNutrition(from: getSection("Nutrition Information", in: sections)),
            equipment: parseEquipment(from: getSection("Equipment", in: sections)),
            tags: parseTags(from: getSection("Tags", in: sections)),
            allergens: parseAllergens(from: getSection("Allergens", in: sections)),
            chefNotes: isPremium ? parseChefNotes(from: getSection("Chef Notes", in: sections)) : [],
            winePairings: isPremium ? parseWinePairings(from: getSection("Wine Pairings", in: sections)) : []
        )
        
        // Log the complete model
        print("\nDEBUG: Final Recipe Model:")
        print("----------------------------------------")
        print("Title: \(recipe.title)")
        print("\nServing Size: \(recipe.servingSize)")
        print("Prep Time: \(recipe.prepTime)")
        print("Cook Time: \(recipe.cookTime)")
        print("Total Time: \(recipe.totalTime)")
        
        print("\nIngredients:")
        recipe.ingredients.sections.forEach { section, items in
            print("\n\(section):")
            items.forEach { print("- \($0)") }
        }
        
        print("\nInstructions:")
        recipe.instructions.sections.forEach { section, steps in
            print("\n\(section):")
            steps.enumerated().forEach { index, step in
                print("\(index + 1). \(step)")
            }
        }
        
        if let plating = recipe.plating {
            print("\nPlating:")
            plating.sections.forEach { section, steps in
                steps.forEach { print("- \($0)") }
            }
        }
        
        print("\nDifficulty:")
        print("Level: \(recipe.difficultyRating.level)")
        print("Rationale: \(recipe.difficultyRating.rationale)")
        
        print("\nNutrition:")
        print("Calories: \(recipe.nutrition.calories)")
        print("Protein: \(recipe.nutrition.protein)")
        print("Carbs: \(recipe.nutrition.carbohydrates)")
        print("Fat: \(recipe.nutrition.fat)")
        
        print("\nEquipment:")
        recipe.equipment.forEach { print("- \($0)") }
        
        print("\nTags:")
        recipe.tags.forEach { print("- \($0)") }
        
        if let allergens = recipe.allergens {
            print("\nAllergens:")
            allergens.forEach { print("- \($0)") }
        }
        
        if let notes = recipe.chefNotes {
            print("\nChef Notes:")
            notes.forEach { print("- \($0)") }
        }
        
        if let pairings = recipe.winePairings {
            print("\nWine Pairings:")
            pairings.forEach { print("- \($0)") }
        }
        
        print("----------------------------------------")
        
        return recipe
    }
    
    // Helper method for recursive title handling
    private func parseMarkdownToRecipe(_ markdown: String, withTitle title: String) throws -> AIRecipe {
        print("DEBUG: Reparsing with extracted title: '\(title)'")
        let recipe = try parseMarkdownToRecipe(markdown)
        return AIRecipe(
            title: title,
            servingSize: recipe.servingSize,
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            totalTime: recipe.totalTime,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            plating: recipe.plating,
            difficultyRating: recipe.difficultyRating,
            nutrition: recipe.nutrition,
            equipment: recipe.equipment,
            tags: recipe.tags,
            allergens: recipe.allergens,
            chefNotes: recipe.chefNotes,
            winePairings: recipe.winePairings
        )
    }
    
    // Helper function to get sections more reliably
    private func getSection(_ title: String, in sections: [MarkdownSection]) -> MarkdownSection? {
        return sections.first { section in
            section.title.lowercased().replacingOccurrences(of: ":", with: "")
                .contains(title.lowercased())
        }
    }
    
    private func parseIngredients(from section: MarkdownSection?) -> AIRecipeSection {
        print("DEBUG: Parsing ingredients section...")
        var sections: [String: [String]] = [:]
        
        guard let section = section else {
            print("WARNING: No ingredients section found")
            return AIRecipeSection(sections: [:])
        }
        
        print("DEBUG: Found subsections:", section.subsections.map { $0.title })
        
        // Process ALL subsections
        for subsection in section.subsections {
            // Extract the exact section name from the markdown
            let sectionName = subsection.title
                .replacingOccurrences(of: "#### ", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            // Process bullet points in subsection
            let ingredients = subsection.content
                .filter { $0.hasPrefix("-") }
                .map { $0.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
                .filter { !$0.isEmpty }
            
            if !ingredients.isEmpty {
                sections[sectionName] = ingredients
                print("DEBUG: Added ingredient section '\(sectionName)' with \(ingredients.count) items")
            }
        }
        
        print("DEBUG: Found ingredient sections:", sections.keys)
        print("DEBUG: Total ingredients:", sections.values.map { $0.count }.reduce(0, +))
        sections.forEach { section, items in
            print("  Section '\(section)' contains \(items.count) ingredients:")
            items.forEach { print("    - \($0)") }
        }
        
        return AIRecipeSection(sections: sections)
    }
    
    private func parseInstructions(from section: MarkdownSection?) -> AIRecipeSection {
        print("DEBUG: Parsing instructions section...")
        var sections: [String: [String]] = [:]
        
        guard let section = section else {
            print("WARNING: No instructions section found")
            return AIRecipeSection(sections: [:])
        }
        
        print("DEBUG: Found subsections:", section.subsections.map { $0.title })
        
        // Process ALL subsections
        for subsection in section.subsections {
            // Extract the exact section name from the markdown
            let sectionName = subsection.title
                .replacingOccurrences(of: "#### ", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            // Process numbered steps in subsection
            let steps = subsection.content
                .filter { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return trimmed.first?.isNumber ?? false
                }
                .map { $0.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression) }
                .filter { !$0.isEmpty }
            
            if !steps.isEmpty {
                sections[sectionName] = steps
                print("DEBUG: Added instruction section '\(sectionName)' with \(steps.count) steps")
            }
        }
        
        print("DEBUG: Found instruction sections:", sections.keys)
        print("DEBUG: Total steps:", sections.values.map { $0.count }.reduce(0, +))
        sections.forEach { section, steps in
            print("  Section '\(section)' contains \(steps.count) steps:")
            steps.enumerated().forEach { index, step in
                print("    \(index + 1). \(step)")
            }
        }
        
        return AIRecipeSection(sections: sections)
    }
    
    private func parsePlating(from section: MarkdownSection?) -> AIRecipeSection? {
        print("DEBUG: Parsing plating section...")
        
        guard let section = section else {
            print("WARNING: No plating section found")
            return nil
        }
        
        let steps = section.content
            .filter { !$0.isEmpty }
            .map { line -> String in
                if line.hasPrefix("-") {
                    return line.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                }
                return line
            }
        
        print("DEBUG: Found \(steps.count) plating steps")
        return AIRecipeSection(sections: ["Presentation": steps])
    }
    
    private func parseDifficulty(from section: MarkdownSection?) -> AIRecipe.DifficultyRating {
        print("DEBUG: Parsing difficulty rating...")
        
        guard let section = section else {
            print("WARNING: No difficulty rating found, using default")
            return AIRecipe.DifficultyRating(level: "Medium", rationale: "")
        }
        
        var level = "Medium"
        var rationale = ""
        
        for line in section.content {
            if line.hasPrefix("- Level:") {
                level = line.replacingOccurrences(of: "- Level:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("- Rationale:") {
                rationale = line.replacingOccurrences(of: "- Rationale:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        print("DEBUG: Found difficulty - Level: \(level), Rationale: \(rationale)")
        return AIRecipe.DifficultyRating(level: level, rationale: rationale)
    }
    
    private func parseNutrition(from section: MarkdownSection?) -> AIRecipe.NutritionInfo {
        print("DEBUG: Parsing nutrition information...")
        
        guard let section = section else {
            print("WARNING: No nutrition section found")
            return AIRecipe.NutritionInfo(calories: "", protein: "", carbohydrates: "", fat: "")
        }
        
        var calories = "", protein = "", carbs = "", fat = ""
        
        for line in section.content {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- Calories:") {
                calories = trimmed.replacingOccurrences(of: "- Calories:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("- Protein:") {
                protein = trimmed.replacingOccurrences(of: "- Protein:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("- Carbohydrates:") {
                carbs = trimmed.replacingOccurrences(of: "- Carbohydrates:", with: "").trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("- Fat:") {
                fat = trimmed.replacingOccurrences(of: "- Fat:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        print("DEBUG: Found nutrition values - Cal: \(calories), Pro: \(protein), Carb: \(carbs), Fat: \(fat)")
        return AIRecipe.NutritionInfo(calories: calories, protein: protein, carbohydrates: carbs, fat: fat)
    }
    
    private func parseEquipment(from section: MarkdownSection?) -> [String] {
        print("DEBUG: Parsing equipment...")
        
        guard let section = section else {
            print("WARNING: No equipment section found")
            return []
        }
        
        let equipment = section.content
            .filter { !$0.isEmpty }
            .map { line -> String in
                if line.hasPrefix("-") {
                    return line.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                }
                return line
            }
        
        print("DEBUG: Found \(equipment.count) equipment items")
        return equipment
    }
    
    private func parseTags(from section: MarkdownSection?) -> [String] {
        print("DEBUG: Parsing tags...")
        
        guard let section = section else {
            print("WARNING: No tags section found")
            return []
        }
        
        let tags = section.content
            .flatMap { line -> [String] in
                let components = line
                    .replacingOccurrences(of: "^[-*]\\s*", with: "", options: .regularExpression)
                    .components(separatedBy: CharacterSet(charactersIn: ","))
                return components
            }
            .map { tag -> String in
                var cleaned = tag
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression)
                
                // Capitalize first letter of each word
                cleaned = cleaned.components(separatedBy: " ")
                    .map { word in
                        guard let first = word.first else { return word }
                        return String(first).uppercased() + word.dropFirst()
                    }
                    .joined(separator: " ")
                
                return cleaned
            }
            .filter { !$0.isEmpty }
        
        print("DEBUG: Found \(tags.count) tags:", tags)
        return Array(Set(tags)).sorted() // Remove duplicates and sort
    }
    
    private func parseAllergens(from section: MarkdownSection?) -> [String] {
        print("DEBUG: Parsing allergens...")
        
        guard let section = section else {
            print("WARNING: No allergens section found")
            return []
        }
        
        let allergens = section.content
            .filter { !$0.isEmpty }
            .map { line -> String in
                if line.hasPrefix("-") {
                    return line.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
                }
                return line
            }
            .map { $0.replacingOccurrences(of: "\\(.*\\)", with: "", options: .regularExpression) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        print("DEBUG: Found \(allergens.count) allergens")
        return allergens
    }
    
    private func parseChefNotes(from section: MarkdownSection?) -> [String] {
        print("DEBUG: Parsing chef notes...")
        
        guard let section = section else {
            print("WARNING: No chef notes section found")
            return []
        }
        
        let notes = section.content
            .filter { !$0.isEmpty }
            .flatMap { line -> [String] in
                if line.hasPrefix("-") || line.hasPrefix("*") {
                    return [line.replacingOccurrences(of: "^[-*]\\s*", with: "", options: .regularExpression)]
                } else if line.first?.isNumber ?? false {
                    return [line.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)]
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    // Split long paragraphs into separate notes
                    return line.components(separatedBy: ". ")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .map { $0.hasSuffix(".") ? $0 : $0 + "." }
                }
                return []
            }
            .map { note -> String in
                var cleaned = note
                    .replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression) // Remove parentheses
                    .trimmingCharacters(in: .whitespaces)
                
                // Capitalize first letter
                if let firstLetter = cleaned.first {
                    cleaned = String(firstLetter).uppercased() + cleaned.dropFirst()
                }
                
                return cleaned
            }
            .filter { !$0.isEmpty }
        
        print("DEBUG: Found \(notes.count) chef notes")
        return notes
    }
    
    private func parseWinePairings(from section: MarkdownSection?) -> [String] {
        print("DEBUG: Parsing wine pairings...")
        
        guard let section = section else {
            print("WARNING: No wine pairings section found")
            return []
        }
        
        var pairings: Set<String> = []
        let content = section.content.joined(separator: " ")
        
        // Extract wine names using multiple patterns
        let patterns = [
            "such as ([^,.]+(?:,\\s*[^,.]+)*)",
            "like ([^,.]+(?:,\\s*[^,.]+)*)",
            "pair(?:s|ed)? with ([^,.]+(?:,\\s*[^,.]+)*)",
            "recommend(?:ed)? ([^,.]+(?:,\\s*[^,.]+)*)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
               let wineRange = Range(match.range(at: 1), in: content) {
                let wines = content[wineRange]
                    .components(separatedBy: CharacterSet(charactersIn: ","))
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                pairings.formUnion(wines)
            }
        }
        
        // Also check for bullet points
        let bulletPoints = section.content
            .filter { $0.hasPrefix("-") }
            .map { $0.replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
        
        pairings.formUnion(bulletPoints)
        
        let cleanedPairings = pairings.map { wine -> String in
            var cleaned = wine
                .replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression) // Remove parentheses
                .replacingOccurrences(of: "such as|like|or|and", with: "", options: [.regularExpression, .caseInsensitive])
                .trimmingCharacters(in: .whitespaces)
            
            // Capitalize first letter
            if let firstLetter = cleaned.first {
                cleaned = String(firstLetter).uppercased() + cleaned.dropFirst()
            }
            
            return cleaned
        }
        .filter { !$0.isEmpty }
        .sorted()
        
        print("DEBUG: Found wine pairings:", cleanedPairings)
        return Array(cleanedPairings)
    }
    
    private func logParsingResults(_ recipe: AIRecipe) {
        print("\nDEBUG: Final Recipe Model Validation:")
        print("----------------------------------------")
        print("Title: \(!recipe.title.isEmpty)")
        print("Serving Size: \(recipe.servingSize)")
        print("Times: \(!recipe.prepTime.isEmpty), \(!recipe.cookTime.isEmpty), \(!recipe.totalTime.isEmpty)")
        print("Ingredients sections: \(recipe.ingredients.sections.count)")
        print("Instructions sections: \(recipe.instructions.sections.count)")
        print("Plating: \(recipe.plating != nil)")
        print("Difficulty: \(!recipe.difficultyRating.level.isEmpty)")
        print("Nutrition: \(!recipe.nutrition.calories.isEmpty)")
        print("Equipment: \(recipe.equipment.count)")
        print("Tags: \(recipe.tags.count)")
        print("Allergens: \(recipe.allergens?.count ?? 0)")
        print("Chef Notes: \(recipe.chefNotes?.count ?? 0)")
        print("Wine Pairings: \(recipe.winePairings?.count ?? 0)")
        print("----------------------------------------\n")
    }
    
    private func calculateCost(inputTokens: Int, outputTokens: Int) -> Double {
        let inputCost = Double(inputTokens) * currentModel.costPerInputToken
        let outputCost = Double(outputTokens) * currentModel.costPerOutputToken
        return inputCost + outputCost
    }
    
    private func parseServingSize(from section: MarkdownSection?) -> Int {
        guard let content = section?.content.first else {
            print("WARNING: No serving size found, using default")
            return 4
        }
        
        // Extract first number from content
        let numbers = content.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        
        if let servings = numbers.first {
            return servings
        }
        
        print("WARNING: Could not parse serving size, using default")
        return 4
    }
    
    // Add validation for critical fields
    private func validateRecipe(_ recipe: AIRecipe) -> [String] {
        var warnings: [String] = []
        
        // Check critical fields
        if recipe.title.isEmpty {
            warnings.append("Recipe title is missing")
        }
        
        if recipe.ingredients.sections.isEmpty {
            warnings.append("Recipe ingredients are missing")
        }
        
        if recipe.instructions.sections.isEmpty {
            warnings.append("Recipe instructions are missing")
        }
        
        if recipe.nutrition.calories.isEmpty {
            warnings.append("Nutrition information is incomplete")
        }
        
        // Check for empty or invalid times
        if recipe.prepTime.isEmpty || recipe.cookTime.isEmpty || recipe.totalTime.isEmpty {
            warnings.append("One or more time fields are missing")
        }
        
        return warnings
    }
}

