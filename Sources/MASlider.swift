// Copyright (c) 2017 mpmarcelomp@gmail.com
// See LICENSE for license information.

import SwiftUI

/// SwiftUI wrapper for ``MASliderControl``. Bind ``step`` for two-way updates; pass ``numberOfSteps``, colors, optional ``thumbImage``, and step/selected text or attributed strings.
public struct MASlider: UIViewRepresentable {
    /// Binding to the current step index (updated when the user pans or taps).
    private let step: Binding<Int>
    /// Total number of steps (minimum 2).
    private let numberOfSteps: Int
    /// Color of the track and step knots.
    private let trackTintColor: Color
    /// Background color of the thumb.
    private let thumbTintColor: Color
    /// Optional image on the thumb (e.g. SF Symbol); rendered as template with white tint.
    private let thumbImage: UIImage?
    /// Label text for unselected steps.
    private let stepText: String?
    /// Attributed label for unselected steps (overrides `stepText` when set).
    private let attributedStepText: AttributedString?
    /// Label text for the selected step.
    private let selectedStepText: String?
    /// Attributed label for the selected step (overrides `selectedStepText` when set).
    private let attributedSelectedStepText: AttributedString?

    /// Binds ``step``; pass ``numberOfSteps`` and optional colors, thumb image, and label strings.
    /// - Parameters:
    ///   - step: Binding to the current step index (updated when the user pans or taps).
    ///   - numberOfSteps: Total number of steps (minimum 2).
    ///   - trackTintColor: Color of the track and step knots.
    ///   - thumbTintColor: Background color of the thumb.
    ///   - thumbImage: Optional image on the thumb (e.g. SF Symbol); rendered as template with white tint.
    ///   - stepText: Label text for unselected steps.
    ///   - attributedStepText: Attributed label for unselected steps (overrides `stepText` when set).
    ///   - selectedStepText: Label text for the selected step.
    ///   - attributedSelectedStepText: Attributed label for the selected step (overrides `selectedStepText` when set).
    /// - Returns: A ``MASlider`` view that wraps the ``MASliderControl`` instance.
    public init(
        step: Binding<Int>,
        numberOfSteps: Int,
        trackTintColor: Color = .blue,
        thumbTintColor: Color = .blue,
        thumbImage: UIImage? = nil,
        stepText: String? = nil,
        attributedStepText: AttributedString? = nil,
        selectedStepText: String? = nil,
        attributedSelectedStepText: AttributedString? = nil
    ) {
        self.step = step
        self.numberOfSteps = numberOfSteps
        self.trackTintColor = trackTintColor
        self.thumbTintColor = thumbTintColor
        self.thumbImage = thumbImage
        self.stepText = stepText
        self.attributedStepText = attributedStepText
        self.selectedStepText = selectedStepText
        self.attributedSelectedStepText = attributedSelectedStepText
    }
    
    // MARK: UIViewRepresentable
    
    public typealias UIViewType = MASliderControl
    
    public func makeUIView(context: Context) -> UIViewType {
        let uiView = UIViewType()
        
        uiView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        uiView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        
        uiView.step = step.wrappedValue
        uiView.numberOfSteps = numberOfSteps
        uiView.trackTintColor = UIColor(trackTintColor)
        uiView.thumbTintColor = UIColor(thumbTintColor)
        
        if let thumbImage = thumbImage {
            uiView.thumbImage = thumbImage
        }
        if let stepText = stepText {
            uiView.stepText = stepText
        }
        if let attributedStepText = attributedStepText {
            uiView.attributedStepText = NSAttributedString(attributedStepText)
        }
        if let selectedStepText = selectedStepText {
            uiView.selectedStepText = selectedStepText
        }
        if let attributedSelectedStepText = attributedSelectedStepText {
            uiView.attributedSelectedStepText = NSAttributedString(attributedSelectedStepText)
        }
        
        uiView.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        
        return uiView
    }
    
    public func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        uiView.step = step.wrappedValue
        uiView.numberOfSteps = numberOfSteps
        uiView.trackTintColor = UIColor(trackTintColor)
        uiView.thumbTintColor = UIColor(thumbTintColor)
        
        if let stepText = stepText {
            uiView.stepText = stepText
        }
        if let attributedStepText = attributedStepText {
            uiView.attributedStepText = NSAttributedString(attributedStepText)
        }
        if let selectedStepText = selectedStepText {
            uiView.selectedStepText = selectedStepText
        }
        if let attributedSelectedStepText = attributedSelectedStepText {
            uiView.attributedSelectedStepText = NSAttributedString(attributedSelectedStepText)
        }
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(step: step)
    }
}

extension MASlider {
    /// Coordinator for the ``MASlider`` view.
    /// Handles the value changed event from the ``MASliderControl`` instance.
    public final class Coordinator: NSObject {
        var stepBinding: Binding<Int>?
        
        /// Initializes the coordinator with the step binding.
        /// - Parameters:
        ///   - step: Binding to the current step index (updated when the user pans or taps).
        init(step: Binding<Int>) {
            self.stepBinding = step
        }
        
        /// Handles the value changed event from the ``MASliderControl`` instance.
        /// - Parameters:
        ///   - sender: The ``MASliderControl`` instance that sent the event.
        @objc func valueChanged(_ sender: Any) {
            guard let control = sender as? MASliderControl else { return }
            stepBinding?.wrappedValue = control.step
        }
    }
}

#Preview {
    MASlider(
        step: .constant(2),
        numberOfSteps: 3,
        trackTintColor: .orange,
        thumbTintColor: .orange,
        thumbImage: nil,
        stepText: nil,
        attributedStepText: nil,
        selectedStepText: nil,
        attributedSelectedStepText: nil)
    .border(.red)
}
