import SwiftUI

struct NewCollectionSheet: View {
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
                    
                    Toggle(isOn: $isPremiumOnly) {
                        Label("Premium Collection", systemImage: "star.fill")
                            .foregroundStyle(Color.appPrimary)
                    }
                    .tint(Color.appPrimary)
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
                                .fill(name.isEmpty ? .gray : Color.appPrimary)
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