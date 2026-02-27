# ProteinTracker

A clean, modern iOS app for tracking daily protein intake. Built with SwiftUI following MVVM architecture and best practices.

## Features

- 📊 **Visual Progress Ring** - See your daily protein progress at a glance
- ⚡ **Quick Add** - One-tap buttons for common amounts
- 📝 **Detailed Logging** - Track source, time, and notes for each entry
- 📈 **Weekly Charts** - View your protein history with beautiful bar charts
- 🎯 **Customizable Goals** - Set and adjust your daily protein target
- 💾 **Persistent Storage** - Data saved locally using UserDefaults

## Architecture

- **MVVM Pattern** - Clean separation of concerns
- **SwiftUI** - Modern declarative UI framework
- **Swift Package Manager** - Dependency management
- **Unit Tests** - Comprehensive test coverage

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Project Structure

```
ProteinTracker/
├── ProteinTracker/
│   ├── Models/           # Data models
│   ├── Views/            # SwiftUI views
│   └── ViewModels/       # Business logic
├── ProteinTrackerTests/  # Unit tests
└── Package.swift         # SPM manifest
```

## Building

```bash
swift build
swift test
```

## GitHub Actions

This project includes CI that builds and tests on every push.

## License

MIT License
