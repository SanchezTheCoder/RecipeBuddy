import Foundation

enum IngredientType {
    case steak
    case otherProtein
    case pasta
    case rice
    case vegetable
    case potato
    case sauce
    case seasoning
    case liquid
    case other
    
    // Standard portion sizes per person (in standard units)
    var basePortionPerPerson: Double {
        switch self {
        case .steak: 
            return 1.0 // 1 steak per person
        case .otherProtein: 
            return 6.0 // 6oz (0.375 pounds) per person
        case .pasta: 
            return 4.0 // 4oz dry pasta per person (standard serving)
        case .rice: 
            return 0.25 // 1/4 cup dry rice per person (yields ~3/4 cup cooked)
        case .vegetable: 
            return 1.0 // 1 cup cooked vegetables per person
        case .potato: 
            return 1.0 // 1 medium potato per person (~5oz)
        case .sauce: 
            return 0.25 // 1/4 cup sauce per person
        case .seasoning: 
            return 1.0 // Base for scaling
        case .liquid: 
            return 1.0 // Base for scaling
        case .other: 
            return 1.0 // Default linear scaling
        }
    }
    
    // Scaling factors with culinary logic
    var scalingFactor: (Double) -> Double {
        switch self {
        case .pasta:
            return { servings in
                // Use basePortionPerPerson (4oz) * number of servings
                basePortionPerPerson * servings / 4.0
            }
        case .steak:
            return { servings in
                // One steak per person, direct scaling
                servings
            }
        case .seasoning:
            return { servings in
                // Seasonings scale sub-linearly
                sqrt(servings) / sqrt(4)
            }
        case .sauce:
            return { servings in
                // Sauces scale slightly sub-linearly for larger groups
                let factor = servings > 6 ? 0.9 : 1.0
                return (servings * factor) / 4.0
            }
        default:
            return { servings in
                // Linear scaling from base recipe
                servings / 4.0
            }
        }
    }
}

struct IngredientParser {
    static let steakTypes = ["ribeye", "sirloin", "filet", "t-bone", "steak"]
    static let otherProteins = ["chicken", "fish", "pork", "beef", "salmon"]
    static let pastaTypes = ["pasta", "spaghetti", "fettuccine", "penne", "linguine", "tagliatelle"]
    static let riceTypes = ["rice", "arborio", "basmati", "jasmine"]
    static let vegetables = ["asparagus", "broccoli", "carrot", "spinach", "kale", "zucchini"]
    static let potatoes = ["potato", "yukon", "russet"]
    static let sauces = ["sauce", "gravy", "dressing", "marinade"]
    static let seasonings = ["salt", "pepper", "spice", "herb", "garlic", "seasoning"]
    
    static func determineType(from ingredient: String) -> IngredientType {
        let lowercased = ingredient.lowercased()
        
        if steakTypes.contains(where: { lowercased.contains($0) }) {
            return .steak
        }
        if pastaTypes.contains(where: { lowercased.contains($0) }) {
            return .pasta
        }
        if riceTypes.contains(where: { lowercased.contains($0) }) {
            return .rice
        }
        if vegetables.contains(where: { lowercased.contains($0) }) {
            return .vegetable
        }
        if potatoes.contains(where: { lowercased.contains($0) }) {
            return .potato
        }
        if sauces.contains(where: { lowercased.contains($0) }) {
            return .sauce
        }
        if seasonings.contains(where: { lowercased.contains($0) }) {
            return .seasoning
        }
        if otherProteins.contains(where: { lowercased.contains($0) }) {
            return .otherProtein
        }
        
        return .other
    }
} 