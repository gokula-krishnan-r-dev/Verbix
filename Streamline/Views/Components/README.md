# AI Prompt Field Component

This directory contains reusable UI components for the Streamline app.

## AIPromptField

`AIPromptField` is a reusable SwiftUI component that provides a consistent and polished UI for AI prompt interactions. It includes:

- Input field for user prompts
- Real-time status indicators
- Support for multiple modes (blank, with content, custom)
- Loading indicators
- Animation and focus management
- Voice input via speech recognition (macOS compatible)
- Keyboard navigation support

### Usage

```swift
AIPromptField(
    searchQuery: $searchQuery,
    isProcessing: $isProcessing,
    selectedTab: $selectedTab,
    aiModel: $aiModel,
    onSubmit: handleSubmit,
    onCancel: handleCancel
)
```

### Parameters

- `searchQuery`: Binding to the text input string
- `isProcessing`: Binding to a boolean indicating if an operation is in progress
- `selectedTab`: Binding to an AIPromptTab enum value (blank, withContent, or custom)
- `aiModel`: Binding to a string containing the name/ID of the AI model being used
- `onSubmit`: A closure that executes when the user submits the prompt
- `onCancel`: A closure that executes when the user cancels an operation

### Example

See `AIPromptDemoView.swift` for a complete implementation example showing how to use this component.

### Features

- ✅ Responsive design with proper animations
- ✅ Focus management
- ✅ Status indicators
- ✅ Custom tab support
- ✅ Voice input via speech recognition
- ✅ Keyboard shortcuts
- ✅ Clean API with callbacks

### Speech Recognition for macOS

The component integrates Apple's Speech framework to provide voice input capabilities on macOS:

- Click the microphone button to start recording
- Speak your prompt clearly
- The recognized text will be inserted into the search field in real-time
- Click the microphone button again to stop recording
- Visual indicators show recording status (red pulsing circle and "Listening..." label)

The component automatically handles:
- Permission requests for microphone access
- Speech recognition lifecycle
- Error handling and user feedback
- Proper cleanup when the component is dismissed

#### Implementation Details

The speech recognition is implemented using Apple's Speech framework with macOS-specific audio handling:

1. **Permissions**: The component requests proper authorization for speech recognition when it appears
2. **macOS Audio Engine**: Uses AVAudioEngine configured for macOS without AVAudioSession (which is iOS-only)
3. **UI Feedback**: Visual indicators show when recording is active, including a pulsing animation
4. **Real-time Transcription**: Text appears in the search field as it's recognized
5. **Error Handling**: Graceful error handling for permission denials or hardware issues
6. **Localization Support**: Can be configured to work with different languages by changing the `SFSpeechRecognizer` locale

#### Requirements

For speech recognition to work properly, your app must:

1. Include the `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` keys in Info.plist
2. Add the Speech and AVFoundation frameworks to your project
3. Request permissions at runtime (handled by the component)

#### Adding Required Info.plist Entries

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone to transcribe your voice commands into text</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>We need access to speech recognition to convert your voice to text for AI prompts</string>
```

### Customization

The component is designed to work well with the app's existing color scheme and UI patterns. You can customize it by:

1. Modifying the tab enum to add more modes
2. Updating the visuals via standard SwiftUI modifiers
3. Adding additional buttons or indicators by wrapping the component
4. Changing the speech recognizer locale to support different languages 