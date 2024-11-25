import Foundation

// MARK: - Collection Models
struct TheRecipeCollection: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    var recipes: [SavedRecipe]
    let isPremiumOnly: Bool
    let createdAt: Date
    let updatedAt: Date
    
    struct SavedRecipe: Codable, Identifiable, Hashable {
        let id: UUID
        let recipe: AIRecipe
        let addedAt: Date
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: SavedRecipe, rhs: SavedRecipe) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    init(id: UUID = UUID(),
         name: String,
         description: String,
         recipes: [SavedRecipe] = [],
         isPremiumOnly: Bool,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.recipes = recipes
        self.isPremiumOnly = isPremiumOnly
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - AI Recipe Models
struct AIRecipe: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let servingSize: Int
    let prepTime: String
    let cookTime: String
    let totalTime: String
    let ingredients: AIRecipeSection
    let instructions: AIRecipeSection
    let plating: AIRecipeSection?
    let difficultyRating: DifficultyRating
    let nutrition: NutritionInfo
    let equipment: [String]
    let tags: [String]
    let allergens: [String]?
    let chefNotes: [String]?
    let winePairings: [String]?
    
    struct DifficultyRating: Codable, Hashable {
        let level: String
        let rationale: String
    }
    
    struct NutritionInfo: Codable, Hashable {
        let calories: String
        let protein: String
        let carbohydrates: String
        let fat: String
    }
    
    private enum CodingKeys: CodingKey {
        case id, title, servingSize
        case prepTime, cookTime, totalTime
        case ingredients, instructions, plating
        case difficultyRating, nutrition
        case equipment, tags
        case allergens
        case chefNotes, winePairings
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.title = try container.decode(String.self, forKey: .title)
        self.servingSize = try container.decode(Int.self, forKey: .servingSize)
        self.prepTime = try container.decode(String.self, forKey: .prepTime)
        self.cookTime = try container.decode(String.self, forKey: .cookTime)
        self.totalTime = try container.decode(String.self, forKey: .totalTime)
        self.ingredients = try container.decode(AIRecipeSection.self, forKey: .ingredients)
        self.instructions = try container.decode(AIRecipeSection.self, forKey: .instructions)
        self.plating = try container.decodeIfPresent(AIRecipeSection.self, forKey: .plating)
        self.difficultyRating = try container.decode(DifficultyRating.self, forKey: .difficultyRating)
        self.nutrition = try container.decode(NutritionInfo.self, forKey: .nutrition)
        self.equipment = try container.decode([String].self, forKey: .equipment)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.allergens = try container.decodeIfPresent([String].self, forKey: .allergens)
        self.chefNotes = try container.decodeIfPresent([String].self, forKey: .chefNotes)
        self.winePairings = try container.decodeIfPresent([String].self, forKey: .winePairings)
    }
    
    init(id: UUID = UUID(),
         title: String,
         servingSize: Int,
         prepTime: String,
         cookTime: String,
         totalTime: String,
         ingredients: AIRecipeSection,
         instructions: AIRecipeSection,
         plating: AIRecipeSection? = nil,
         difficultyRating: DifficultyRating,
         nutrition: NutritionInfo,
         equipment: [String],
         tags: [String],
         allergens: [String]? = nil,
         chefNotes: [String]? = nil,
         winePairings: [String]? = nil) {
        self.id = id
        self.title = title
        self.servingSize = servingSize
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.totalTime = totalTime
        self.ingredients = ingredients
        self.instructions = instructions
        self.plating = plating
        self.difficultyRating = difficultyRating
        self.nutrition = nutrition
        self.equipment = equipment
        self.tags = tags
        self.allergens = allergens
        self.chefNotes = chefNotes
        self.winePairings = winePairings
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AIRecipe, rhs: AIRecipe) -> Bool {
        lhs.id == rhs.id
    }
}

struct AIRecipeSection: Codable, Hashable {
    private var _sections: [String: [String]]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self._sections = try container.decode([String: [String]].self)
    }
    
    init(sections: [String: [String]]) {
        self._sections = sections
    }
    
    var sections: [String: [String]] {
        get { _sections }
        set { _sections = newValue }
    }
    
    var totalItems: Int {
        sections.values.reduce(0) { $0 + $1.count }
    }
    
    var allItems: [String] {
        sections.values.flatMap { $0 }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(_sections)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sections)
    }
}

// MARK: - API Response Models
struct AIAPIResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let role: String
            let content: String
            let refusal: String?
        }
        let index: Int
        let message: Message
        let logprobs: String?
        let finish_reason: String
    }
    
    struct TokenMetrics: Codable {
        struct Details: Codable {
            let cachedTokens: Int?
            let audioTokens: Int?
            let reasoningTokens: Int?
            let acceptedPredictionTokens: Int?
            let rejectedPredictionTokens: Int?
            
            private enum CodingKeys: String, CodingKey {
                case cachedTokens = "cached_tokens"
                case audioTokens = "audio_tokens"
                case reasoningTokens = "reasoning_tokens"
                case acceptedPredictionTokens = "accepted_prediction_tokens"
                case rejectedPredictionTokens = "rejected_prediction_tokens"
            }
        }
        
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        let promptTokensDetails: Details?
        let completionTokensDetails: Details?
        
        private enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
            case promptTokensDetails = "prompt_tokens_details"
            case completionTokensDetails = "completion_tokens_details"
        }
    }
    
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [Choice]
    let tokenMetrics: TokenMetrics
    let systemFingerprint: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices
        case tokenMetrics = "usage"
        case systemFingerprint = "system_fingerprint"
    }
} 
