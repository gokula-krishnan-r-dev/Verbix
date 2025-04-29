import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var tempAPIKey: String = ""
    @State private var showHistory: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("API Configuration")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OpenAI API Key")
                            .font(.subheadline)
                        
                        SecureField("Enter API Key", text: $tempAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onAppear {
                                tempAPIKey = appState.apiKey
                            }
                        
                        Button("Save API Key") {
                            appState.apiKey = tempAPIKey
                            appState.saveSettings()
                        }
                        .disabled(tempAPIKey == appState.apiKey)
                        .padding(.top, 4)
                    }
                    
                    Picker("AI Model", selection: $appState.aiModel) {
                        Text("GPT-4o").tag("gpt-4o")
                        Text("GPT-4 Turbo").tag("gpt-4-turbo")
                        Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                    }
                    .onChange(of: appState.aiModel) { _ in
                        appState.saveSettings()
                    }
                }
                
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $appState.isDarkMode)
                        .onChange(of: appState.isDarkMode) { _ in
                            appState.saveSettings()
                        }
                }
                
                Section(header: Text("Keyboard Shortcuts")) {
                    Toggle("Enable Option+Space Shortcut", isOn: $appState.hotkeyEnabled)
                        .onChange(of: appState.hotkeyEnabled) { _ in
                            appState.saveSettings()
                        }
                }
                
                Section(header: Text("Defaults")) {
                    Picker("Default Response Style", selection: $appState.responseStyle) {
                        ForEach(ResponseStyle.allCases, id: \.self) { style in
                            Text(style.title)
                                .tag(style)
                        }
                    }
                    .onChange(of: appState.responseStyle) { _ in
                        appState.saveSettings()
                    }
                }
                
                Section {
                    Button("View Interaction History") {
                        showHistory.toggle()
                    }
                }
                
                Section {
                    Button("Clear All History") {
                        appState.clearHistory()
                    }
                    .foregroundColor(.red)
                }
            }
            .listStyle(DefaultListStyle())
            .navigationTitle("Settings")
            .sheet(isPresented: $showHistory) {
                HistoryView()
                    .environmentObject(appState)
            }
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if appState.history.isEmpty {
                    Text("No history yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(appState.history.indices.reversed(), id: \.self) { index in
                        let interaction = appState.history[index]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(interaction.prompt)
                                .lineLimit(2)
                                .font(.headline)
                            
                            Text(interaction.response)
                                .lineLimit(3)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(interaction.timestamp, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(interaction.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(interaction.responseStyle.title)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(action: {
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(interaction.response, forType: .string)
                            }) {
                                Label("Copy Response", systemImage: "doc.on.doc")
                            }
                            
                            Button(role: .destructive, action: {
                                appState.deleteHistoryItem(at: index)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Interaction History")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
} 