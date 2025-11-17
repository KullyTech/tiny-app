# Developer Guidelines

## 📑 Table of Contents
1. [SwiftLint Guide](#-swiftlint-guide)
   - [Installation](#-1-installation)
   - [Xcode Build Phase Script](#️-2-xcode-build-phase-script)
   - [Configuration Rules](#-3-configuration-rules)
   - [Ignoring or Disabling Rules](#-4-ignoring-or-disabling-rules)
   - [Ignored Directories](#-5-ignored-directories)
   - [Reporter Output](#-6-reporter-output)
   - [Tips](#-7-tips)
2. [Commit Message Guide](#-commit-message-guide)
   - [Commit Message Format](#commit-message-format)
   - [Commit Types](#commit-types)
   - [Examples](#examples)
3. [Pull Request Description Guide](#-pull-request-description-guide)
   - [Summary](#1-dart-summary-required)
   - [Features](#2-sparkles-features-required)
   - [Files Added/Modified](#3-file_folder-files-addedmodified-required)
   - [Usage Examples](#4-wrench-usage-examples-required-for-new-features)
   - [Complete Example](#complete-example-template)

---

# 🧭 SwiftLint Guide

## 📦 1. Installation

If you don't have SwiftLint installed, install it using **Homebrew**:
```bash
brew install swiftlint
```

💡 For Apple Silicon (M1/M2/M3) Macs, SwiftLint will be installed under `/opt/homebrew/bin/swiftlint`.

Verify the installation:
```bash
swiftlint version
```

## ⚙️ 2. Xcode Build Phase Script

This project includes a Run Script Phase to automatically lint Swift code during build.
```bash
if [[ "$(uname -m)" == arm64 ]]
then
    export PATH="/opt/homebrew/bin:$PATH"
else
    export PATH="/usr/local/bin:$PATH"
fi

if command -v swiftlint >/dev/null 2>&1
then
    swiftlint
else
    echo "warning: `swiftlint` command not found - See https://github.com/realm/SwiftLint#installation for installation instructions."
fi
```

### 🧩 Explanation

- Detects if your Mac uses Apple Silicon (arm64)
- Sets the correct Homebrew path
- Runs swiftlint
- Shows a warning if SwiftLint is not installed

## 🧾 3. Configuration Rules

The rules are defined in `.swiftlint.yml`.

### Example Highlights
```yaml
disabled_rules:
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - empty_string

line_length:
  warning: 150
  error: 200
```

Full configuration can be found in `.swiftlint.yml` at the project root.

## 🚫 4. Ignoring or Disabling Rules

### Disable a rule for a specific line
```swift
let foo = "bar" // swiftlint:disable:this line_length
```

### Disable for a block of code
```swift
// swiftlint:disable line_length
func veryLongFunction() {
    // ...
}
// swiftlint:enable line_length
```

### Disable multiple rules
```swift
// swiftlint:disable line_length cyclomatic_complexity
// ... your code ...
// swiftlint:enable line_length cyclomatic_complexity
```

### Ignore an entire file
```swift
// swiftlint:disable all
```

## 📁 5. Ignored Directories

SwiftLint will not check these folders:
```yaml
excluded:
  - Carthage
  - Pods
  - SwiftLint/Common/3rdPartyLib
```

## 💬 6. Reporter Output

The output format is set to `xcode`, so warnings and errors appear directly in the Xcode Issue Navigator.

## ✅ 7. Tips

- Keep `.swiftlint.yml` in the project root.
- Run manually if needed:
```bash
  swiftlint
```
- Rebuild after editing `.swiftlint.yml` to apply new rules.
- Check full documentation: [SwiftLint on GitHub](https://github.com/realm/SwiftLint)

---

# 💬 Commit Message Guide

## Commit Message Format

### Title Format
```
<type>: <descriptive overview of changes>
```

### Optional Description
```
DESCRIPTION:
<Brief explanation of what the change does>

USAGE:
<Code example showing how to use the new feature>
```

## Commit Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring without changing functionality
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Build process or auxiliary tool changes

## Examples

### Example 1: New Feature
```
feat: add reusable Countdown component

DESCRIPTION:
This is a component that will display a countdown when called inside a view.

USAGE:
Countdown(maxCount: 5) {
    function()
}
```

### Example 2: Bug Fix
```
fix: resolve memory leak in timer cleanup

DESCRIPTION:
Fixed timer not being properly invalidated on component disposal, 
which caused memory leaks in long-running sessions.
```

### Example 3: Simple Change
```
docs: update README with installation steps
```

### Example 4: Refactoring
```
refactor: simplify authentication logic

DESCRIPTION:
Extracted token validation into separate helper function for 
better code reusability and testability.
```

---

# 📝 Pull Request Description Guide

## How to Write a Great PR Description

Follow this structure to create clear, comprehensive pull request descriptions:

---

## 1. :dart: Summary (Required)
**What to write:** A concise 1-2 sentence overview of what this PR adds/changes/fixes.

**Template:**
```
Added a new [component/feature name] that [main functionality] with [key capability].
```

**Example:**
```
Added a new reusable Countdown component that displays a customizable countdown 
timer with completion callback functionality for triggering actions when the 
countdown reaches zero.
```

---

## 2. :sparkles: Features (Required)
**What to write:** Bullet points highlighting the main capabilities and benefits.

**Format:**
- Use bold for feature names: **Feature Name**: Description
- Focus on user/developer benefits, not implementation details
- Include default values where relevant

**Template:**
```
- **[Feature Name]**: [What it does and why it's useful] (default: [value])
- **[Feature Name]**: [What it does and why it's useful]
```

**Example:**
```
- **Customizable Duration**: Set countdown start value via `maxCount` parameter (default: 5)
- **Custom Prefix Text**: Personalize countdown message via `prefixText` parameter (default: "Starting in")
- **Completion Callback**: Execute custom actions when countdown reaches zero
- **Smooth Animations**: Number transitions with easing animation
- **Memory Safe**: Proper timer cleanup to prevent memory leaks
```

---

## 3. :file_folder: Files Added/Modified (Required)
**What to write:** List of files changed with brief descriptions.

**Template:**
```
### Added
- `path/to/File.swift` - [Purpose/description]

### Modified
- `path/to/ExistingFile.swift` - [What changed]

### Deleted
- `path/to/OldFile.swift` - [Reason for deletion]
```

**Example:**
```
### Added
- `Tiny/Components/Countdown.swift` - Main countdown component
```

---

## 4. :wrench: Usage Examples (Required for new features)
**What to write:** Code snippets showing how to use the new feature.

**Guidelines:**
- Start with simplest usage
- Show 2-3 variations with different parameters
- Add comments explaining what each example demonstrates
- Use realistic function/variable names

**Template:**
```swift
// Basic usage with defaults
ComponentName() {
    // action
}

// Custom configuration
ComponentName(param1: value, param2: value) {
    // action
}

// Advanced usage
ComponentName(
    param1: value,
    param2: value,
    param3: value
) {
    // complex action
}
```

---

## Complete Example Template

```markdown
# Add Countdown Component

## :dart: Summary
Added a new reusable Countdown component that displays a customizable countdown timer with completion callback functionality.

## :sparkles: Features
- **Customizable Duration**: Set countdown start value via `maxCount` parameter (default: 5)
- **Custom Prefix Text**: Personalize countdown message via `prefixText` parameter (default: "Starting in")
- **Completion Callback**: Execute custom actions when countdown reaches zero

## :file_folder: Files Added
- `Tiny/Components/Countdown.swift` - Main countdown component

## :wrench: Usage Examples
```swift
// Basic usage
Countdown(maxCount: 5) {
    startMainFeature()
}

// Custom configuration
Countdown(maxCount: 3, prefixText: "Game starts in") {
    startGame()
}
```
```

---

## 💡 Quick Tips

### For Commits
✅ **DO:**
- Use present tense ("add feature" not "added feature")
- Keep title under 50 characters
- Add description for complex changes
- Reference issue numbers when applicable

❌ **DON'T:**
- Write vague messages like "fix bug" or "update code"
- Combine multiple unrelated changes
- Include unnecessary details in the title

### For Pull Requests
✅ **DO:**
- Write clear, scannable descriptions
- Include code examples
- Link relevant resources
- Keep it concise but complete

❌ **DON'T:**
- Write novels - be concise
- Assume context - explain clearly
- Skip code examples
- Leave placeholders unfilled
