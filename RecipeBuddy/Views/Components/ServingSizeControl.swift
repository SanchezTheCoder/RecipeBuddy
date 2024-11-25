import SwiftUI

struct ServingSizeControl: View {
    @Binding var servings: Int
    let originalServings: Int
    @State private var isVisible = false
    @State private var sliderValue: Double
    let range: ClosedRange<Int> = 1...12
    
    private let haptics = UIImpactFeedbackGenerator(style: .soft)
    
    init(servings: Binding<Int>, originalServings: Int) {
        self._servings = servings
        self.originalServings = originalServings
        self._sliderValue = State(initialValue: Double(servings.wrappedValue))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section with serving info
            HStack(alignment: .center, spacing: 12) {
                // Left side with icon and text
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.appPrimary)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("\(servings)")
                        .font(.system(size: 17, weight: .semibold))
                        .contentTransition(.numericText())
                        .foregroundStyle(Color.appPrimary)
                    
                    Text("Servings")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Right side with portion indicator
                Text(portionSizeText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(portionSizeColor.opacity(0.1))
                    .foregroundStyle(portionSizeColor)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.background)
            
            // Slider section
            HStack {
                Text("1")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Slider(value: $sliderValue, in: 1...12, step: 1)
                    .tint(Color.appPrimary)
                    .onChange(of: sliderValue) { oldValue, newValue in
                        servings = Int(newValue)
                        haptics.impactOccurred(intensity: 0.5)
                    }
                
                Text("12")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.background)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appSecondary.opacity(0.3), lineWidth: 1)
        )
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isVisible)
        .onAppear { isVisible = true }
    }
    
    // Helper computed properties for portion size indicator
    private var portionSizeText: String {
        switch servings {
        case 1...2: return "Small Gathering"
        case 3...4: return "Family Meal"
        case 5...8: return "Dinner Party"
        default: return "Large Group"
        }
    }
    
    private var portionSizeColor: Color {
        switch servings {
        case 1...2: return Color.appPrimary
        case 3...4: return Color.appPrimary
        case 5...8: return Color.appPrimary
        default: return Color.appAccent
        }
    }
    
    private func scaleIngredient(_ ingredient: String, for newServings: Int) -> String {
        let ingredientType = IngredientParser.determineType(from: ingredient)
        let regex = try! NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)\s*([a-zA-Z]+)(.*)"#)
        let nsRange = NSRange(ingredient.startIndex..<ingredient.endIndex, in: ingredient)
        
        guard let match = regex.firstMatch(in: ingredient, range: nsRange) else {
            return ingredient
        }
        
        let originalNumber = Double(ingredient[Range(match.range(at: 1), in: ingredient)!])!
        let unit = ingredient[Range(match.range(at: 2), in: ingredient)!]
        let remainder = ingredient[Range(match.range(at: 3), in: ingredient)!]
        
        let scalingFactor = ingredientType.scalingFactor(Double(newServings))
        let scaledNumber = originalNumber * scalingFactor / Double(originalServings)
        
        // Format number to avoid weird decimals
        let formattedNumber = formatNumber(scaledNumber)
        
        return "\(formattedNumber) \(unit)\(remainder)"
    }
    
    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", number)
        }
        // Convert to fraction if close to common fractions
        let fractions: [(threshold: Double, string: String)] = [
            (0.25, "¼"), (0.33, "⅓"), (0.5, "½"),
            (0.66, "⅔"), (0.75, "¾")
        ]
        
        let wholePart = floor(number)
        let fractionalPart = number.truncatingRemainder(dividingBy: 1)
        
        if let fraction = fractions.first(where: { abs($0.threshold - fractionalPart) < 0.05 }) {
            return wholePart > 0 ? "\(Int(wholePart))\(fraction.string)" : fraction.string
        }
        
        return String(format: "%.1f", number)
    }
}

#Preview {
    VStack {
        ServingSizeControl(servings: .constant(4), originalServings: 4)
            .padding()
        Spacer()
    }
} 