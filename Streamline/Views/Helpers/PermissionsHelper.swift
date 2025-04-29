import SwiftUI
import AppKit

struct PermissionsHelper: View {
    @State private var showPermissionsWindow = false
    @State private var accessibilityGranted = false
    @State private var appleEventsGranted = false
    @State private var currentStep = 0
    
    var body: some View {
        Button(action: {
            showPermissionsWindow = true
        }) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.blue)
                Text("Permissions Setup")
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showPermissionsWindow) {
            permissionsView
        }
    }
    
    private var permissionsView: some View {
        VStack(spacing: 20) {
            Text("Setup Required Permissions")
                .font(.title)
                .fontWeight(.bold)
            
            Text("EveryChat needs a few permissions to work properly and be able to access selected text from any application.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 15) {
                PermissionRow(
                    icon: "accessibility",
                    title: "Accessibility",
                    description: "Required to detect selected text in applications",
                    isGranted: accessibilityGranted,
                    action: requestAccessibilityPermission
                )
                
                PermissionRow(
                    icon: "text.viewfinder",
                    title: "Apple Events",
                    description: "Required to communicate with other applications",
                    isGranted: appleEventsGranted,
                    action: requestAppleEventsPermission
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Troubleshooting")
                    .font(.headline)
                
                Text("• If permissions dialogs don't appear, open System Preferences manually")
                    .font(.caption)
                
                Text("• Go to Privacy & Security → Accessibility and add EveryChat")
                    .font(.caption)
                
                Text("• Also enable Automation permissions for EveryChat")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Button(action: {
                showPermissionsWindow = false
            }) {
                Text("Close")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding()
        .frame(width: 500, height: 600)
        .onAppear {
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        // Check for accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        
        // Check for Apple Events permissions by attempting to get frontmost app
        let scriptToRequestPermission = """
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            set frontAppName to name of frontApp
            return frontAppName
        end tell
        """
        
        let scriptObject = NSAppleScript(source: scriptToRequestPermission)
        var error: NSDictionary?
        let _ = scriptObject?.executeAndReturnError(&error)
        appleEventsGranted = (error == nil)
    }
    
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
        // After some delay, check if permission was granted
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkPermissions()
        }
    }
    
    private func requestAppleEventsPermission() {
        // Show alert explaining what to expect
        let alert = NSAlert()
        alert.messageText = "Apple Events Permission"
        alert.informativeText = "EveryChat will now request permission to control System Events. Please click 'OK' when the permission dialog appears."
        alert.addButton(withTitle: "OK")
        alert.runModal()
        
        // Trigger permission request
        let scriptToRequestPermission = """
        tell application "System Events"
            set frontApp to first application process whose frontmost is true
            set frontAppName to name of frontApp
            return frontAppName
        end tell
        """
        
        let scriptObject = NSAppleScript(source: scriptToRequestPermission)
        var error: NSDictionary?
        let _ = scriptObject?.executeAndReturnError(&error)
        
        // After some delay, check if permission was granted
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkPermissions()
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 32, height: 32)
                .foregroundColor(isGranted ? .green : .blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else {
                Button(action: action) {
                    Text("Grant")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
    }
}

#Preview {
    PermissionsHelper()
} 