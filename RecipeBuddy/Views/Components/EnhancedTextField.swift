import SwiftUI

struct EnhancedTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let focused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 17))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(focused ? Color.appPrimary : .clear, lineWidth: 1)
                )
        }
    }
} 