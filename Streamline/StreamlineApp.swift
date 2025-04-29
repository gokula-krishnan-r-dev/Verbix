//
//  StreamlineApp.swift
//  Streamline
//
//  Created by gokul on 17/04/25.
//

import SwiftUI
import AppKit

@main
struct StreamlineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var statusBar: StatusBarController?
    @State private var popover = NSPopover()
    @State private var floatingPanel: FloatingPanelController?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 800, minHeight: 600)
                .onAppear {
                    // Request permissions on first launch
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let hotkeyManager = HotkeyManager()
                        hotkeyManager.showAccessibilityPermissionsDialog()
                    }
                    
                    // Set up popover
                    setupPopover()
                    
                    // Set up floating panel
                    setupFloatingPanel()
                    
                    // Register for panel close notifications
                    registerForPanelCloseNotifications()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("AI Assistant") {
                Button("Settings") {
                    NSApp.sendAction(#selector(NSApp.showSettingsWindow(_:)), to: nil, from: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Button("Check Permissions") {
                    let hotkeyManager = HotkeyManager()
                    hotkeyManager.showAccessibilityPermissionsDialog()
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
    
    private func setupPopover() {
        // Configure the popover
        popover.behavior = .transient
        popover.animates = true
         
        // Set ContentView as the popover's contentViewController
        let contentView = ContentView()
            .environmentObject(appState)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        // Create the status bar controller
        statusBar = StatusBarController(popover, appState: appState)
    }
    
    private func setupFloatingPanel() {
        // Initialize floating panel controller
        floatingPanel = FloatingPanelController()
        
        // Register hotkey to capture selected text and show the panel
        let hotkeyManager = HotkeyManager()
        _ = hotkeyManager.registerHotkey { selectedText in
            DispatchQueue.main.async {
                // Hide main window if it's open
                for window in NSApp.windows {
                    if window.title != "Settings" && window.title != "AI Assistant" {
                        window.orderOut(nil)
                    }
                }
                
                // Show floating panel with selected text
                if !selectedText.isEmpty {
                    self.floatingPanel?.showPanel(with: selectedText, appState: self.appState)
                } else {
                    self.floatingPanel?.showEmptySelectionPanel(appState: self.appState)
                }
            }
        }
    }
    
    private func registerForPanelCloseNotifications() {
        // Listen for panel close notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ClosePanelNotification"),
            object: nil,
            queue: .main
        ) { _ in
            // Update app state when panel is closed
            appState.isAIPanelVisible = false
            appState.emptySelectionMode = false
        }
    }
}

// Add the showSettingsWindow selector to NSApplication
extension NSApplication {
    @objc func showSettingsWindow(_ sender: Any?) {
        for window in windows {
            if window.title == "Settings" || window.frameAutosaveName == "Settings" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
}
