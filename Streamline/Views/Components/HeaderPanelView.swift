//
//  HeaderPanelView.swift
//  Streamline
//
//  Created by gokul on 29/04/25.
//

import SwiftUI
import AppKit

struct HeaderPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var showChatHistory = false
    @State private var appIcon: NSImage?
    
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

#Preview {
    HeaderPanelView()
        .environmentObject(AppState())
}
