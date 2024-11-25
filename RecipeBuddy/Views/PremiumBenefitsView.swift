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

#Preview {
    PremiumBenefitsView()
} 