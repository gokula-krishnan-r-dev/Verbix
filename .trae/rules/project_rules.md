

## **SwiftUI macOS Project Rules**

### 1. **App Structure & Organization**
- Use **MVVM or MV architecture** with well-defined folder hierarchies: `Views/`, `ViewModels/`, `Models/`, `Services/`, `Extensions/`, `Resources/`.
- Modularize features as **Swift packages** or **independent modules** where feasible.
- Group related UI components with folders and mark reusable components clearly.

### 2. **UI/UX Guidelines**
- Leverage **native SwiftUI components** optimized for macOS: `Toolbar`, `Sidebar`, `WindowGroup`, `SplitView`, etc.
- Ensure full support for **light/dark mode** and **high-resolution Retina displays**.
- Implement **keyboard shortcuts**, **drag-and-drop**, and **context menus** to enhance productivity features.
- Maintain **consistent styling** with a central `Theme.swift` or styling utility.

### 3. **Performance Optimization**
- Avoid unnecessary UI updates using `@StateObject`, `@ObservedObject`, and `@Published` correctly.
- Offload heavy tasks to background threads using `Task`, `async/await`, or `Combine`.
- Use **lazy loading** for heavy views or data-heavy lists.

### 4. **Data Persistence & Sync**
- Choose appropriate storage (e.g., `UserDefaults`, `CoreData`, `FileManager`, or custom `JSON/Plist` files).
- Ensure sync-friendly designs if integrating with cloud or external sources.
- Encrypt sensitive user data when stored locally.

### 5. **Preview & Testing**
- Leverage **SwiftUI Previews** with mock data for all major views.
- Write **unit tests** for core logic and **UI tests** for essential workflows.
- Use **Xcode test plans** to run tests across different configurations.

### 6. **Automation & CI/CD**
- Integrate with **Fastlane** or **Xcode Cloud** for automated builds and releases.
- Use **GitHub Actions** or **GitLab CI** to run tests and perform lint checks.

### 7. **Build & Release**
- Define separate **Development** and **Production** schemes.
- Use **AppSandbox** and properly configure **entitlements** for security compliance.
- Prepare `Info.plist` with required permissions and descriptions.
- Sign and notarize the app using Apple Developer tools before distribution.

### 8. **Documentation**
- Maintain clear in-code documentation using `///` for public APIs.
- Include an in-app **Help** menu with user guidance or link to online docs.
- Provide a `README.md` with setup steps, build instructions, and usage details.

### 9. **Error Handling & Logging**
- Use structured error types (`enum AppError: Error`) and handle gracefully in views.
- Implement a global error logger and user-friendly feedback for failures.
- Optionally integrate with logging frameworks (e.g., `os.log`, `Sentry`).

### 10. **Accessibility & Internationalization**
- Use SwiftUI’s `accessibility*` modifiers for screen reader support.
- Prepare strings for localization using `LocalizedStringKey` and `.strings` files.
- Support font scaling and UI adaptability for all display sizes.

