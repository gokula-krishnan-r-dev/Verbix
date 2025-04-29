import SwiftUI
import AppKit

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var apiKey = ""
    @Binding var isFirstLaunch: Bool
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to EveryChat",
            description: "Your AI-powered writing assistant that works in any application.",
            imageName: "message.and.waveform.fill"
        ),
        OnboardingPage(
            title: "Select Text Anywhere",
            description: "Simply select text in any application and press Option+Space to activate EveryChat.",
            imageName: "text.cursor"
        ),
        OnboardingPage(
            title: "Multiple Response Styles",
            description: "Choose from concise, balanced, detailed, professional, or casual response styles.",
            imageName: "slider.horizontal.3"
        ),
        OnboardingPage(
            title: "Edit Before Sending",
            description: "Review and edit AI-generated responses before inserting them into your application.",
            imageName: "pencil"
        ),
        OnboardingPage(
            title: "API Key Required",
            description: "Enter your OpenAI API key to start using EveryChat. This will be securely stored in your keychain.",
            imageName: "key.fill"
        )
    ]
    
    var body: some View {
        VStack {
            // Progress indicators
            HStack {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Image(systemName: pages[index].imageName)
                            .font(.system(size: 70))
                            .foregroundColor(.accentColor)
                            .padding(.bottom, 20)
                        
                        Text(pages[index].title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(pages[index].description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        // API Key input on the last page
                        if index == pages.count - 1 {
                            VStack(alignment: .leading) {
                                Text("OpenAI API Key")
                                    .font(.headline)
                                
                                SecureField("Enter your API key", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(maxWidth: 300)
                                
                                Text("Get one at platform.openai.com")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .onTapGesture {
                                        if let url = URL(string: "https://platform.openai.com") {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding()
                    .tag(index)
                }
            }
            .tabViewStyle(DefaultTabViewStyle())
            .frame(height: 350)
            
            // Navigation buttons
            HStack {
                Button(action: {
                    withAnimation {
                        currentPage = max(0, currentPage - 1)
                    }
                }) {
                    Text("Previous")
                }
                .disabled(currentPage == 0)
                
                Spacer()
                
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        // On the last page, save API key and finish onboarding
                        appState.apiKey = apiKey
                        appState.saveSettings()
                        isFirstLaunch = false
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
                }
                .buttonStyle(BorderlessButtonStyle())
                .disabled(currentPage == pages.count - 1 && apiKey.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .frame(width: 600, height: 500)
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

#Preview {
    OnboardingView(isFirstLaunch: .constant(true))
        .environmentObject(AppState())
} 