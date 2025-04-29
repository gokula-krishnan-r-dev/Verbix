import SwiftUI
import AppKit

struct TextCaptureView: View {
    @EnvironmentObject var appState: AppState
    @State private var capturedText: String = ""
    @State private var isCapturing: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var sourceApp: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Capture Text")
                .font(.system(size: 24, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Source app info
            if !sourceApp.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "app.fill")
                        .foregroundColor(.blue)
                    Text("Source: \(sourceApp)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)
            }
            
            // Capture status indicator
            HStack(spacing: 12) {
                if isCapturing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Capturing selected text...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: capturedText.isEmpty ? "text.cursor" : "text.badge.checkmark")
                        .font(.system(size: 20))
                        .foregroundColor(capturedText.isEmpty ? .secondary : .green)
                    Text(capturedText.isEmpty ? "No text captured yet" : "Text captured successfully")
                        .font(.headline)
                        .foregroundColor(capturedText.isEmpty ? .secondary : .primary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.windowBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            
            // Captured text display (if any)
            if !capturedText.isEmpty {
                ScrollView {
                    Text(capturedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.textBackgroundColor))
                        .cornerRadius(8)
                }
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            
            // Actions
            VStack(spacing: 16) {
                Button(action: {
                    captureSelectedText()
                }) {
                    HStack {
                        Image(systemName: "text.cursor")
                        Text("Capture Selected Text")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isCapturing)
                
                if !capturedText.isEmpty {
                    HStack(spacing: 16) {
                        Button(action: {
                            useTextForAnalysis()
                        }) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Analyze")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            copyToClipboard()
                        }) {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            clearCapturedText()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Clear")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            Spacer()
            
            // Help text
            Text("Tip: Use Option+Space to quickly capture selected text anywhere.")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)
        }
        .padding()
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            checkForAccessibilityPermission()
            
            // Get frontmost app name
            if let app = NSWorkspace.shared.frontmostApplication {
                sourceApp = app.localizedName ?? "Unknown Application"
            }
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Accessibility Permission Required"),
                message: Text("To capture text from other applications, Streamline needs accessibility permissions. Please open System Settings and grant permission."),
                primaryButton: .default(Text("Open Settings")) {
                    openAccessibilitySettings()
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkForAccessibilityPermission() {
        if !hasAccessibilityPermission() {
            // Show permission alert after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showPermissionAlert = true
            }
        }
    }
    
    private func captureSelectedText() {
        guard hasAccessibilityPermission() else {
            showPermissionAlert = true
            return
        }
        
        isCapturing = true
        
        // Use a slight delay to allow UI to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Get selected text using accessibility APIs
            let selectedText = getSelectedTextViaAccessibility() ?? ""
            
            // If no text via accessibility, try clipboard as fallback
            if selectedText.isEmpty {
                if let clipboardText = NSPasteboard.general.string(forType: .string), !clipboardText.isEmpty {
                    self.capturedText = clipboardText
                    appState.updateSelectedText(clipboardText, source: .clipboard)
                } else {
                    // Use forced clipboard method as last resort
                    self.capturedText = getTextViaClipboard()
                    if !self.capturedText.isEmpty {
                        appState.updateSelectedText(self.capturedText, source: .clipboard)
                    }
                }
            } else {
                // We got text via accessibility
                self.capturedText = selectedText
                appState.updateSelectedText(selectedText, source: .directSelection)
            }
            
            // Update source app info
            if let app = NSWorkspace.shared.frontmostApplication {
                sourceApp = app.localizedName ?? "Unknown Application"
            }
            
            isCapturing = false
        }
    }
    
    private func useTextForAnalysis() {
        guard !capturedText.isEmpty else { return }
        
        // Update app state with captured text
        appState.updateSelectedText(capturedText, source: .directSelection)
        
        // Show the AI panel with captured text
        appState.isAIPanelVisible = true
        NotificationCenter.default.post(name: NSNotification.Name("ShowPanelWithText"), object: capturedText)
    }
    
    private func copyToClipboard() {
        guard !capturedText.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(capturedText, forType: .string)
        
        // Visual feedback could be added here
    }
    
    private func clearCapturedText() {
        capturedText = ""
        appState.selectedText = ""
        sourceApp = ""
    }
    
    // MARK: - Accessibility Methods
    
    private func hasAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    private func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        } else {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!)
        }
    }
    
    private func getSelectedTextViaAccessibility() -> String? {
        // Get the frontmost application
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        
        // Create accessibility element for the app
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        
        // Get the focused element
        var focusedElementRef: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)
        
        if focusedStatus == .success, let focusedElement = focusedElementRef {
            // Try to get selected text
            var selectedTextRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedTextRef) == .success,
               let textAsCFString = selectedTextRef as? String, !textAsCFString.isEmpty {
                return textAsCFString
            }
            
            // Try value
            var valueRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXValueAttribute as CFString, &valueRef) == .success,
               let value = valueRef as? String, !value.isEmpty {
                return value
            }
        }
        
        return nil
    }
    
    private func getTextViaClipboard() -> String {
        // Save current clipboard content
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string) ?? ""
        
        // Clear the clipboard
        pasteboard.clearContents()
        
        // Simulate Cmd+C
        simulateKeyCombination(virtualKey: 0x08) // Command+C
        
        // Wait briefly for clipboard to update
        usleep(100000) // 100ms
        
        // Get the text from clipboard
        let newContents = pasteboard.string(forType: .string) ?? ""
        
        // Restore original clipboard
        pasteboard.clearContents()
        pasteboard.setString(oldContents, forType: .string)
        
        return newContents
    }
    
    private func simulateKeyCombination(virtualKey: CGKeyCode) {
        // Create source
        let source = CGEventSource(stateID: .combinedSessionState)
        
        // Command key down
        if let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true) {
            cmdDown.post(tap: .cghidEventTap)
        }
        
        // Key down
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        // Small delay
        usleep(10000) // 10ms
        
        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
        
        // Command key up
        if let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false) {
            cmdUp.post(tap: .cghidEventTap)
        }
    }
}

// MARK: - Previews

struct TextCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        TextCaptureView()
            .environmentObject(AppState())
            .preferredColorScheme(.light)
    }
} 