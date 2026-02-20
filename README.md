# MASlider

A discrete step-based slider for iOS. Use it from UIKit via `MASliderControl` or from SwiftUI via the `MASlider` view.

## Features

- Step-based discrete slider with configurable `numberOfSteps` and `step`
- Track and thumb colors: `trackTintColor`, `thumbTintColor`
- Optional thumb image (e.g. SF Symbol) via `thumbImage`
- Step labels: `stepText` / `selectedStepText` or `attributedStepText` / `attributedSelectedStepText`
- Optional `DataSource` for custom per-step titles
- Pan and tap (with wobble animation) to change step
- UIKit: `MASliderControl` subclasses `UIControl`
- SwiftUI: `MASlider` view with `Binding<Int>` for `step`

## UIControl and methods to update

The UIKit type is **`MASliderControl`**, a subclass of `UIControl`.

- **Observe value changes:** Use `addTarget(_:action:for:)` with `.valueChanged` (and optionally other events) to react when the user changes the step.
- **Update programmatically:** Set `step` or call `set(step:animated:)`; set `numberOfSteps`, `trackTintColor`, `thumbTintColor`, `thumbImage`, and the step/selected text or attributed text properties as needed.

## Requirements

iOS 15.0 or later.

## Installation

### Swift Package Manager

Add the package to your project (Xcode: File > Add Package Dependencies) or in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mpmarcelomp/MASlider", from: "0.1.0"),
]
```

## Documentation

Build the DocC documentation with `swift package generate-documentation` (requires the Swift-DocC plugin), or use Xcode’s Product > Build Documentation.

## Author

mpmarcelomp@gmail.com

## License

MASlider is available under the MIT license. See the LICENSE file for more info.
