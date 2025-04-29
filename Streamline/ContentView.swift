//
//  ContentView.swift
//  Streamline
//
//  Created by gokul on 17/04/25.
//

import SwiftUI
import AppKit
import Combine
import OSLog

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings: Bool = false
    @State private var isFirstLaunch: Bool = false
    @State private var showPermissionsNeeded: Bool = false
    @State private var permissionGranted: Bool = false
    @State private var selectedSidebarItem: SidebarItem? = .dashboard
    @State private var showClipboardPermissionAlert = false
    @State private var clipboardPollingTimer: Timer?
    
    private let hotkeyManager = HotkeyManager()
    private let floatingPanel = FloatingPanelController()
    
    // Add TextCapture to the sidebar items
    enum SidebarItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case textCapture = "Text Capture"
        case history = "History"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .dashboard: return "house"
            case .textCapture: return "text.cursor"
            case .history: return "clock"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            sidebarView
            
            // Main content area
            ZStack {
                switch selectedSidebarItem {
                case .dashboard:
                    dashboardView
                case .textCapture:
                    TextCaptureView()
                        .environmentObject(appState)
                case .history:
                    historyView
                case .settings:
                    SettingsView()
                        .environmentObject(appState)
                case .none:
                    dashboardView // Default view if nothing selected
                }
            }
            .frame(minWidth: 600, idealWidth: 800)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    toggleSidebar()
                }) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
        .onAppear {
            // Check if this is first launch
            isFirstLaunch = appState.savedAPIKey.isEmpty
            
            // Check for permissions with enhanced methods
            checkPermissionsWithRetry()
            
            // Register hotkey to handle Option+Space
            registerHotkey()
            
            setupClipboardPolling()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $isFirstLaunch) {
            OnboardingView(isFirstLaunch: $isFirstLaunch)
                .environmentObject(appState)
        }
        .alert(isPresented: $showPermissionsNeeded) {
            Alert(
                title: Text("Accessibility Permission Required"),
                message: Text("Streamline needs accessibility permissions to capture text selections."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilitySettings()
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
        .alert(isPresented: $showClipboardPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text("To monitor clipboard changes, please allow Streamline to access your clipboard in System Settings > Privacy & Security > Accessibility."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilityPermissionSettings()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func checkPermissionsWithRetry() {
        // First try a basic check
        if hotkeyManager.hasAccessibilityPermission() {
            permissionGranted = true
            return
        }
        
        // Check if permissions may have been granted but cache not updated
        if hotkeyManager.examineProcessPrivileges() {
            permissionGranted = true
            return
        }
        
        // Advanced verification method with multiple retries
        hotkeyManager.verifyAccessibilityPermissions { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                
                // If permissions were detected on delayed verification,
                // the UI will automatically update due to state change
                if granted {
                    print("Accessibility permissions verified after advanced checks")
                } else {
                    // If still not granted after advanced checks, attempt one final restart of relevant services
                    self.performFinalPermissionRefresh()
                }
            }
        }
    }
    
    // Final attempt at refreshing permissions by restarting accessibility services
    private func performFinalPermissionRefresh() {
        // Create a task to restart accessibility services
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["SystemUIServer"]
        
        do {
            try task.run()
            
            // Wait a bit for the service to restart
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Check permissions again after restart
                if self.hotkeyManager.hasAccessibilityPermission() || 
                   self.hotkeyManager.examineProcessPrivileges() {
                    self.permissionGranted = true
                }
            }
        } catch {
            print("Failed to restart accessibility services: \(error)")
        }
    }
    
    private func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
    
    private func registerHotkey() {
        if appState.hotkeyEnabled {
            let success = hotkeyManager.registerHotkey { selectedText in
                handleSelectedText(selectedText)
            }
            
            if !success {
                // Alert the user if hotkey registration failed
                let alert = NSAlert()
                alert.messageText = "Hotkey Registration Failed"
                alert.informativeText = "Could not register Option+Space shortcut. Please check if another application is using this key combination."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
    
    // Handle the text when the hotkey is pressed
    private func handleSelectedText(_ text: String) {
        if !text.isEmpty {
            // Determine the source based on context clues
            let source: TextSource = text == NSPasteboard.general.string(forType: .string) ? 
                .clipboard : .directSelection
            
            // Update app state with the text and its source
            appState.updateSelectedText(text, source: source)
            
            // Show the floating panel with the selected text
            DispatchQueue.main.async {
                // If permission not granted, show the dialog instead
                if !hotkeyManager.hasAccessibilityPermission() {
                    showPermissionsNeeded = true
                } else {
                    floatingPanel.showPanel(with: text, appState: appState)
                }
            }
        } else {
            // Show the empty selection panel
            DispatchQueue.main.async {
                if !hotkeyManager.hasAccessibilityPermission() {
                    showPermissionsNeeded = true
                } else {
                    floatingPanel.showEmptySelectionPanel(appState: appState)
                }
            }
        }
    }
    
    private func refreshPermissions() {
        // Display temporary feedback
        let alert = NSAlert()
        alert.messageText = "Checking Permissions..."
        alert.informativeText = "If you've already enabled permissions, we'll verify the system status."
        alert.alertStyle = .informational
        
        // Show alert without blocking
        let alertWindow = alert.window
        alert.beginSheetModal(for: alertWindow) { _ in }
        
        // Check on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Try the enhanced permission checking process
            let hasAccessPermission = self.hotkeyManager.refreshAndCheckPermissions()
            let hasAutomationPermission = self.hotkeyManager.hasAutomationPermission()
            let hasAllPermissions = hasAccessPermission && hasAutomationPermission
            
            // If that fails, try advanced verification
            if !hasAllPermissions {
                // Try manual permission fixing
                self.hotkeyManager.showAllPermissionsDialog()
                
                // Dismiss any shown alert
                DispatchQueue.main.async {
                    alertWindow.sheetParent?.endSheet(alertWindow)
                }
            } else {
                DispatchQueue.main.async {
                    // Dismiss any shown alert
                    alertWindow.sheetParent?.endSheet(alertWindow)
                    
                    // Success from the first attempt
                    let successAlert = NSAlert()
                    successAlert.messageText = "Permissions Verified"
                    successAlert.informativeText = "All required permissions are now confirmed. You're all set!"
                    successAlert.alertStyle = .informational
                    successAlert.runModal()
                    
                    // Update state to trigger UI refresh
                    self.permissionGranted = true
                }
            }
        }
    }
    
    // Restart the accessibility subsystem completely
    private func restartAccessibilitySubsystem(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Launch and then kill System Events to restart the accessibility subsystem
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/System Events.app"))
            
            // Give it a moment to launch
            Thread.sleep(forTimeInterval: 0.5)
            
            // Terminate it to cause a restart
            let killTask = Process()
            killTask.launchPath = "/usr/bin/killall"
            killTask.arguments = ["System Events"]
            try? killTask.run()
            
            // Give time for the subsystem to restart
            Thread.sleep(forTimeInterval: 1.0)
            
            // Check permissions again
            DispatchQueue.main.async {
                let hasPermission = self.hotkeyManager.hasAccessibilityPermission() || 
                                    self.hotkeyManager.examineProcessPrivileges()
                completion(hasPermission)
            }
        }
    }
    
    private func setupClipboardPolling() {
        // Initialize timer to check clipboard periodically
        clipboardPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Get permission status
            let hasPermission = hotkeyManager.hasAccessibilityPermission()
            
            // If we don't have permission, we'll prompt once
            if !hasPermission && !showClipboardPermissionAlert {
                showClipboardPermissionAlert = true
                clipboardPollingTimer?.invalidate()
            }
        }
    }
    
    private func openAccessibilityPermissionSettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
    
    private var dashboardView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.and.waveform.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Streamline")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("AI Assistant is ready")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Select text in any application and press Option+Space")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("Featuring the new Kerlig-style interface")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.blue)
                .padding(.horizontal)
            
            Spacer().frame(height: 30)
            
            Button(action: {
                selectedSidebarItem = .textCapture
            }) {
                Label("Capture Text", systemImage: "text.cursor")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            if appState.apiKey.isEmpty {
                Text("⚠️ API key not configured")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.top, 8)
            }
            
            // Permission status indicator
            if !hotkeyManager.hasAccessibilityPermission() && !permissionGranted {
                VStack(spacing: 8) {
                    Button(action: {
                        showPermissionsNeeded = true
                    }) {
                        Label("Accessibility Permission Required", systemImage: "exclamationmark.triangle")
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Refresh permissions button
                    Button(action: {
                        refreshPermissions()
                    }) {
                        Label("Refresh Permissions", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 2)
                }
                .padding(.top, 12)
            }
            
            // Manual trigger button for testing
            Button(action: {
                // Check clipboard first
                let pasteboard = NSPasteboard.general
                if let clipboardText = pasteboard.string(forType: .string), !clipboardText.isEmpty {
                    // Update app state with clipboard content
                    appState.updateSelectedText(clipboardText, source: .clipboard)
                    floatingPanel.showPanel(with: clipboardText, appState: appState)
                } else {
                    // Show empty selection panel
                    floatingPanel.showEmptySelectionPanel(appState: appState)
                }
            }) {
                Label("Test Assistant", systemImage: "text.magnifyingglass")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 12)
        }
        .padding()
    }
    
    private var historyView: some View {
        VStack(spacing: 16) {
            Text("Interaction History")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            
            if appState.history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.bottom, 8)
                    
                    Text("No history yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your interactions with the AI assistant will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(appState.history.indices.reversed(), id: \.self) { index in
                        let interaction = appState.history[index]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(interaction.timestamp, formatter: itemFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(interaction.prompt.prefix(100) + (interaction.prompt.count > 100 ? "..." : ""))
                                .font(.headline)
                                .lineLimit(2)
                            
                            Text(interaction.response.prefix(150) + (interaction.response.count > 150 ? "..." : ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                        .padding(.vertical, 8)
                        .contextMenu {
                            Button(action: {
                                copyToClipboard(interaction.response)
                            }) {
                                Label("Copy Response", systemImage: "doc.on.doc")
                            }
                            
                            Button(action: {
                                appState.deleteHistoryItem(at: index)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                Button(action: {
                    appState.clearHistory()
                }) {
                    Label("Clear History", systemImage: "trash")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .padding()
    }
    
    private var sidebarView: some View {
        List {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                NavigationLink(
                    destination: EmptyView(), // This is handled by the main content area
                    tag: item,
                    selection: $selectedSidebarItem
                ) {
                    Label(item.rawValue, systemImage: item.icon)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 180, idealWidth: 220)
    }
    
    // Helper for clipboard copy
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // Date formatter for history items
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

