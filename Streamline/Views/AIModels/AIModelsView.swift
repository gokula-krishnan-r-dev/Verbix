import SwiftUI

struct AIModelsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedModel: AIModelInfo?
    @Environment(\.presentationMode) var presentationMode
    
    // Grid layout configuration
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Models")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Description
            Text("Select an AI model to use for processing your queries.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // Models grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AIModelInfo.allModels) { model in
                        modelCard(for: model)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Set the initial selected model
            selectedModel = AIModelInfo.allModels.first { $0.apiIdentifier == appState.aiModel }
        }
    }
    
    // Model card view
    private func modelCard(for model: AIModelInfo) -> some View {
        let isSelected = model.apiIdentifier == appState.aiModel
        
        return Button(action: {
            selectModel(model)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with provider logo and model name
                HStack {
                    // Model icon
                    Image(systemName: model.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(model.iconColor)
                        .frame(width: 36, height: 36)
                        .background(model.iconColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.name)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(model.provider)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // Model details
                VStack(alignment: .leading, spacing: 8) {
                    detailRow(icon: "dollarsign.circle", title: "Cost per request", value: "$\(String(format: "%.5f", model.costPerRequest))")
                    
                    detailRow(icon: "bolt", title: "Processing speed", value: getSpeedRating(for: model))
                    
                    detailRow(icon: "chart.bar", title: "Capabilities", value: getCapabilitiesRating(for: model))
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.05) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper function for detail rows
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    // Select a model and update AppState
    private func selectModel(_ model: AIModelInfo) {
        withAnimation {
            selectedModel = model
            appState.aiModel = model.apiIdentifier
            appState.saveSettings()
        }
    }
    
    // Helper function to get speed rating based on model
    private func getSpeedRating(for model: AIModelInfo) -> String {
        switch model.id {
        case "gpt-4o":
            return "Fast"
        case "gpt-4o-mini":
            return "Very Fast"
        case "claude-3-opus":
            return "Medium"
        case "claude-3-sonnet":
            return "Fast"
        case "claude-3-haiku":
            return "Very Fast"
        case "gemini-pro":
            return "Fast"
        default:
            return "Medium"
        }
    }
    
    // Helper function to get capabilities rating based on model
    private func getCapabilitiesRating(for model: AIModelInfo) -> String {
        switch model.id {
        case "gpt-4o":
            return "Excellent"
        case "gpt-4o-mini":
            return "Good"
        case "claude-3-opus":
            return "Excellent"
        case "claude-3-sonnet":
            return "Very Good"
        case "claude-3-haiku":
            return "Good"
        case "gemini-pro":
            return "Good"
        default:
            return "Good"
        }
    }
}

// For Xcode Preview
struct AIModelsView_Previews: PreviewProvider {
    static var previews: some View {
        AIModelsView()
            .environmentObject(AppState())
    }
} 