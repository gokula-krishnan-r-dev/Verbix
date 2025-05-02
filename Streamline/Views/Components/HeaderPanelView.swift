//
//  HeaderPanelView.swift
//  Streamline
//
//  Created by gokul on 29/04/25.
//

import SwiftUI
import AppKit
import Foundation
import Combine



// Internal struct for model option information
fileprivate struct ModelOption {
    let id: String
    let name: String
    let iconName: String
    let iconColor: Color
    let cost: Double
    let provider: String
    let capabilities: String
    let speed: String
    
    // Formatted cost string
    var formattedCost: String {
        return "$\(String(format: "%.5f", cost))/request"
    }
}

struct HeaderPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var showChatHistory = false
    @State private var appIcon: NSImage?
    @State private var showModelSelector = false
    @State private var selectedOption: String = "Select Model"
    @State private var hoverItem: String? = nil
    
  // Rich model options for the dropdown
private let modelOptions: [String: [ModelOption]] = [
    "OpenAI": [
        ModelOption(id: "gpt-4o", name: "GPT-4o", iconName: "sparkle.magnifyingglass", iconColor: .green, cost: 0.01, provider: "OpenAI", capabilities: "Excellent", speed: "Fast"),
        ModelOption(id: "gpt-4o-mini", name: "GPT-4o Mini", iconName: "sparkle", iconColor: .green, cost: 0.001, provider: "OpenAI", capabilities: "Good", speed: "Very Fast")
    ],
    "Anthropic": [
        ModelOption(id: "claude-3-opus", name: "Claude 3 Opus", iconName: "wand.and.stars", iconColor: .purple, cost: 0.015, provider: "Anthropic", capabilities: "Excellent", speed: "Medium"),
        ModelOption(id: "claude-3-sonnet", name: "Claude 3 Sonnet", iconName: "wand.and.stars.inverse", iconColor: .blue, cost: 0.003, provider: "Anthropic", capabilities: "Very Good", speed: "Fast"),
        ModelOption(id: "claude-3-haiku", name: "Claude 3 Haiku", iconName: "wand.and.rays", iconColor: .teal, cost: 0.00025, provider: "Anthropic", capabilities: "Good", speed: "Very Fast")
    ],
    "Google": [
        ModelOption(id: "gemini-pro", name: "Gemini Pro", iconName: "g.circle", iconColor: .orange, cost: 0.0005, provider: "Google", capabilities: "Good", speed: "Fast")
    ],
    "Cloudflare Workers AI": [
        // Text Models
        ModelOption(id: "@cf/meta/llama-3-8b-instruct", name: "Llama 3 8B Instruct", iconName: "cloud", iconColor: .orange, cost: 0.0005, provider: "Cloudflare", capabilities: "Good", speed: "Fast"),
        ModelOption(id: "@cf/meta/llama-3-70b-instruct", name: "Llama 3 70B Instruct", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),
        ModelOption(id: "@cf/mistral/mistral-7b-instruct-v0.1", name: "Mistral 7B Instruct", iconName: "wind", iconColor: .blue, cost: 0.0005, provider: "Cloudflare", capabilities: "Good", speed: "Fast"),
        ModelOption(id: "@cf/mistral/mistral-large-latest", name: "Mistral Large", iconName: "wind.snow", iconColor: .blue, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),


        //@cf/deepseek-ai/deepseek-r1-distill-qwen-32b
        ModelOption(id: "@cf/deepseek-ai/deepseek-r1-distill-qwen-32b", name: "DeepSeek R1 Distill Qwen 32B", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),


        //@hf/google/gemma-7b-it
        ModelOption(id: "@hf/google/gemma-7b-it", name: "Gemma 7B IT", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),

        //@hf/google/gemma-2-9b-it
        ModelOption(id: "@hf/google/gemma-2-9b-it", name: "Gemma 2 9B IT", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),

        //@hf/google/gemma-2-9b-it
        ModelOption(id: "@hf/google/gemma-2-9b-it", name: "Gemma 2 9B IT", iconName: "cloud.bolt", iconColor: .orange, cost: 0.0015, provider: "Cloudflare", capabilities: "Very Good", speed: "Medium"),


        // Embedding Models
        ModelOption(id: "@cf/baai/bge-base-en-v1.5", name: "BGE Base English", iconName: "square.stack.3d.up", iconColor: .teal, cost: 0.0001, provider: "Cloudflare", capabilities: "Embeddings", speed: "Very Fast"),
        ModelOption(id: "@cf/baai/bge-large-en-v1.5", name: "BGE Large English", iconName: "square.stack.3d.up.fill", iconColor: .teal, cost: 0.0002, provider: "Cloudflare", capabilities: "Embeddings", speed: "Fast"),
        
        // Vision Models
        ModelOption(id: "@cf/openai/clip-vit-b-32", name: "CLIP ViT-B/32", iconName: "eye", iconColor: .purple, cost: 0.0001, provider: "Cloudflare", capabilities: "Vision", speed: "Fast"),
        ModelOption(id: "@cf/openai/clip-vit-l-14", name: "CLIP ViT-L/14", iconName: "eye.fill", iconColor: .purple, cost: 0.0002, provider: "Cloudflare", capabilities: "Vision", speed: "Medium"),
        
        // Text-to-Image Models
        ModelOption(id: "@cf/stabilityai/stable-diffusion-xl-base-1.0", name: "Stable Diffusion XL", iconName: "paintbrush", iconColor: .pink, cost: 0.002, provider: "Cloudflare", capabilities: "Image Generation", speed: "Slow"),
        ModelOption(id: "@cf/lykon/dreamshaper-8-lcm", name: "Dreamshaper 8 LCM", iconName: "sparkles", iconColor: .pink, cost: 0.001, provider: "Cloudflare", capabilities: "Image Generation", speed: "Medium"),
        
        // Translation Models
        ModelOption(id: "@cf/meta/m2m100-1.2b", name: "M2M100 1.2B", iconName: "globe", iconColor: .green, cost: 0.0002, provider: "Cloudflare", capabilities: "Translation", speed: "Fast"),
        
        // Speech Recognition Models
        ModelOption(id: "@cf/openai/whisper", name: "Whisper", iconName: "waveform", iconColor: .blue, cost: 0.0005, provider: "Cloudflare", capabilities: "Speech-to-Text", speed: "Medium")
    ]
]
    
    // Helper to get the selected model's name
    private var selectedModelName: String {
        for (_, models) in modelOptions {
            if let model = models.first(where: { $0.id == appState.aiModel }) {
                return model.name
            }
        }
        return "Select Model"
    }
    
    // Helper to get the selected model's icon
    private var selectedModelIcon: (name: String, color: Color)? {
        for (_, models) in modelOptions {
            if let model = models.first(where: { $0.id == appState.aiModel }) {
                return (model.iconName, model.iconColor)
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top header with app info
            HStack(spacing: 12) {
                // App icon and name
                HStack(spacing: 8) {
                    // Display app icon
                    if let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .cornerRadius(6)
                    } else {
                        // Fallback icon
                        Image(systemName: "app")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 28, height: 28)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    // App name and info
                    VStack(alignment: .leading, spacing: 1) {
                        Text(appState.currentAppName.isEmpty ? "Google Chrome" : appState.currentAppName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                .help("This is the app from which Kerlig was launched. It is used as a context when starting a chat or running an action.")
                
                Spacer()

                // Button to start a blank page
                Button(action: {
                    appState.isAIPanelVisible = true
                    appState.selectedText = ""
                    appState.aiResponse = ""
                }) {
                    HStack(spacing: 6) {
                        Text("Start blank")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Start a new blank conversation")

                // AI Model Selector - Enhanced Menu
                Menu {
                    // Model selection header
                    Text("Select AI Model")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Divider()
                    
                    // Group models by provider
                    ForEach(modelOptions.keys.sorted(), id: \.self) { provider in
                        Section(header: 
                            Text(provider)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        ) {
                            ForEach(modelOptions[provider] ?? [], id: \.id) { model in
                                Button(action: {
                                    appState.aiModel = model.id

                                    //save in local storage 
                                    UserDefaults.standard.set(model.id, forKey: "aiModel")
                                    selectedOption = model.name
                                }) {
                                    HStack {
                                        // Provider icon
                                        ZStack {
                                            Circle()
                                                .fill(model.iconColor.opacity(0.15))
                                                .frame(width: 22, height: 22)
                                            
                                            Image(systemName: model.iconName)
                                                .font(.system(size: 12))
                                                .foregroundColor(model.iconColor)
                                        }
                                        
                                        // Model details
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(model.name)
                                                .font(.system(size: 12, weight: .medium))
                                            
                                            // Model metadata
                                            HStack(spacing: 4) {
                                                // Cost
                                                HStack(spacing: 1) {
                                                    Image(systemName: "dollarsign.circle")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(model.formattedCost)
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                // Separator
                                                Text("•")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .opacity(0.5)
                                                
                                                // Capabilities
                                                HStack(spacing: 1) {
                                                    Image(systemName: "chart.bar")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(model.capabilities)
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                // Separator
                                                Text("•")
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .opacity(0.5)
                                                
                                                // Speed
                                                HStack(spacing: 1) {
                                                    Image(systemName: "bolt")
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(model.speed)
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Selected indicator
                                        if model.id == appState.aiModel {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                    }
                                }
                                .help("Select \(model.name) by \(model.provider)")
                            }
                        }
                        
                        if provider != modelOptions.keys.sorted().last {
                            Divider()
                        }
                    }
                    
                    Divider()
                    
                    // Learn more option
                    Button(action: {
                        // Open model info page
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            
                            Text("Learn more about models")
                                .foregroundColor(.blue)
                            
                            Spacer()
                        }
                    }
                    .help("View detailed information about available AI models")
                    
                } label: {
                    // Custom designed menu button
                    HStack(spacing: 6) {
                        // Model icon with colored background
                        if let iconInfo = selectedModelIcon {
                            ZStack {
                                Circle()
                                    .fill(iconInfo.color.opacity(0.15))
                                    .frame(width: 18, height: 18)
                                
                                Image(systemName: iconInfo.name)
                                    .font(.system(size: 10))
                                    .foregroundColor(iconInfo.color)
                            }
                        } else {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .frame(width: 18, height: 18)
                        }
                        
                        // Model name
                        Text(selectedModelName)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        
                        // Dropdown indicator
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                            )
                    )
                    .contentShape(Rectangle())
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .help("Select AI model to use for this conversation")
                .frame(width: 160)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
        }
        .onAppear {
            loadAppIcon()
        }
        .onChange(of: appState.currentAppPath) { _ in
            loadAppIcon()
        }
    }
    
    // Load app icon from path
    private func loadAppIcon() {
        if !appState.currentAppPath.isEmpty {
            appIcon = NSWorkspace.shared.icon(forFile: appState.currentAppPath)
        } else if !appState.currentAppBundleID.isEmpty {
            // Try to get the icon from bundle ID if path isn't available
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appState.currentAppBundleID) {
                appIcon = NSWorkspace.shared.icon(forFile: appURL.path)
            }
        } else {
            // Default icon
            appIcon = nil
        }
    }
}
    

