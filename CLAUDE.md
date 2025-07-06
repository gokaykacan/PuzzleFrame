# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status
This is a PuzzleFrame iOS project directory that's currently in setup phase. The directory structure contains:
- Configuration files for Claude AI development workflow
- GitHub Actions automation setup
- Placeholder image assets (image1.jpg through image10.jpg)
- **No actual iOS project files yet** - needs .xcodeproj, .swift files, or Package.swift to be created

## Development Workflow Rules
1. First think through the problem, read the codebase for relevant files, and write a plan to tasks/todo.md.
2. The plan should have a list of todo items that you can check off as you complete them
3. Before you begin working, check in with me and I will verify the plan.
4. Then, begin working on the todo items, marking them as complete as you go.
5. Please every step of the way just give me a high level explanation of what changes you made
6. Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
7. Finally, add a review section to the [todo.md](http://todo.md/) file with a summary of the changes you made and any other relevant information.

## iOS Development Commands
Since no iOS project exists yet, these commands will be available once an iOS project is created:

### Build Commands
- `xcodebuild -project PuzzleFrame.xcodeproj -scheme PuzzleFrame -configuration Debug build` - Build the project
- `xcodebuild -project PuzzleFrame.xcodeproj -scheme PuzzleFrame -configuration Release build` - Release build

### Testing Commands  
- `xcodebuild test -project PuzzleFrame.xcodeproj -scheme PuzzleFrame -destination 'platform=iOS Simulator,name=iPhone 15'` - Run tests on simulator

### SwiftPM Commands (if using Package.swift)
- `swift build` - Build the package
- `swift test` - Run tests
- `swift run` - Run the executable

## Project Architecture
**Current State:** Project directory setup without iOS project files

**Next Steps Needed:**
1. Create iOS project using Xcode or `swift package init`
2. Set up proper .gitignore for iOS development
3. Organize image assets in proper iOS bundle structure
4. Configure project schemes and build settings

## Available Assets
- 10 placeholder images (image1.jpg through image10.jpg) available for use in the iOS project

## GitHub Integration
- GitHub Actions workflow configured for Claude PR Assistant
- Responds to "@claude" comments in pull requests and issues
