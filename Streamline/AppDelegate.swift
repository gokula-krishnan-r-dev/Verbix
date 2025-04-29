import SwiftUI
import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyManager = HotkeyManager()
    private var statusBarItem: NSStatusItem?
    private var floatingPanel: FloatingPanelController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request accessibility permissions early at app startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestAccessibilityPermissions()
        }
        
        // Set up status bar icon
        setupStatusBarItem()
        
        // Initialize floating panel
        floatingPanel = FloatingPanelController()
        
        // Initialize clipboard monitoring for better text capture
        hotkeyManager.setupClipboardMonitoring()
        
        // Register to handle application activation
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            // Check if option+space is pressed
            if event.modifierFlags.contains(.option) && event.keyCode == 49 {
                // Add a very small delay to allow any clipboard operations to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Capture selected text and show panel
                    if let strongSelf = self {
                        let selectedText = strongSelf.hotkeyManager.getTextFromSelectionOrClipboard()
                        
                        // Log the text that was found for debugging
                        NSLog("📝 Captured text length: \(selectedText.count)")
                        
                        // Process on main thread
                        DispatchQueue.main.async {
                            // Get AppState and update it with the selected text
                            if let appState = strongSelf.getAppState() {
                                // Update the AppState with the selected text
                                appState.updateSelectedText(selectedText, source: .directSelection)
                                
                                // Show the panel with the selected text
                                strongSelf.floatingPanel?.showPanel(with: selectedText, appState: appState)
                            } else {
                                // Fallback if AppState isn't accessible - show empty panel
                                NotificationCenter.default.post(name: NSNotification.Name("ShowPanelWithText"), object: selectedText)
                            }
                        }
                    }
                }
                
                // Hide all non-essential windows
                self?.hideMainWindows()
            }
        }
        
        // Register for notification to update text in panel
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(handleShowPanelWithText(_:)), 
                                             name: NSNotification.Name("ShowPanelWithText"), 
                                             object: nil)
    }
    
    @objc private func handleShowPanelWithText(_ notification: Notification) {
        if let text = notification.object as? String {
            if let appState = getAppState() {
                // Show panel with the text
                floatingPanel?.showPanel(with: text, appState: appState)
            }
        }
    }
    
    private func hideMainWindows() {
        // Hide main application window while keeping AI Assistant panel visible
        for window in NSApp.windows {
            if window.title != "Settings" && window.title != "AI Assistant" {
                window.orderOut(nil)
            }
        }
    }
    
    private func requestAccessibilityPermissions() {
        // Request accessibility permissions which are needed for text operations
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessibilityEnabled {
            // If not enabled, show the dialog with instructions after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.hotkeyManager.showAccessibilityPermissionsDialog()
            }
        }
    }
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "text.bubble", accessibilityDescription: "Streamline")
        }
        
        setupStatusBarMenu()
    }
    
    private func setupStatusBarMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show AI Assistant", action: #selector(showAIPanel), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Check Permissions", action: #selector(checkPermissions), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc private func showAIPanel() {
        // Show AI panel without making main app visible
        let appState = (NSApp.delegate as? AppDelegate)?.getAppState()
        if let appState = appState {
            floatingPanel?.showEmptySelectionPanel(appState: appState)
        } else {
            // Fallback to normal app activation if appState not available
            openStreamline()
        }
    }
    
    @objc private func openStreamline() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc private func openSettings() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        NSApp.sendAction(#selector(NSApp.showSettingsWindow(_:)), to: nil, from: nil)
    }
    
    @objc private func checkPermissions() {
        // Show the accessibility permissions dialog
        hotkeyManager.showAccessibilityPermissionsDialog()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup when app is about to terminate
    }
    
    // Helper to get app state from SwiftUI app
    private func getAppState() -> AppState? {
        // This is a temporary solution - in a production app,
        // we would use a shared state container or dependency injection
        let windowController = NSApp.windows.first?.windowController
        let viewController = windowController?.contentViewController
        // Traverse view controller hierarchy to find our AppState
        if let hostingController = viewController as? NSHostingController<AnyView> {
            // This is complex and may not be reliable
            // We're using NotificationCenter as a more reliable alternative
            return nil
        }
        return nil
    }
} 