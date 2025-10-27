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
