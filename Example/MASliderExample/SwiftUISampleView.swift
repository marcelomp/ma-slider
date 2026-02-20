import SwiftUI

import MASlider

struct SwiftUISampleView: View {
    @State private var step: Int = 2
    @State private var numberOfSteps: Int = 4
    @State private var trackTintColor: Color = .red
    @State private var thumbTintColor: Color = .red
    @State private var thumbImage: UIImage? = UIImage(systemName: "lock.fill")
    @State private var stepText: String? = nil
    @State private var attributedStepText: AttributedString? = nil
    @State private var selectedStepText: String? = nil
    @State private var attributedSelectedStepText: AttributedString? = nil
    
    var body: some View {
        VStack {
            Text("MASlider (SwiftUI)")
                .font(.system(.largeTitle, design: .monospaced, weight: .bold))

            MASlider(
                step: $step,
                numberOfSteps: numberOfSteps,
                trackTintColor: trackTintColor,
                thumbTintColor: thumbTintColor,
                thumbImage: thumbImage,
                stepText: stepText,
                attributedStepText: attributedStepText,
                selectedStepText: selectedStepText,
                attributedSelectedStepText: attributedSelectedStepText)
            
            Text("Step: \(step) of \(numberOfSteps)")
                .font(.headline)

            Stepper("Steps", value: $numberOfSteps, in: 2...10)

            ColorPicker("trackTintColor", selection: $trackTintColor)
            ColorPicker("thumbTintColor", selection: $thumbTintColor)
        }
        .padding()
        .onChange(of: numberOfSteps) { _, newCount in
            step = min(step, newCount - 1)
        }
    }
}

#Preview {
    SwiftUISampleView()
}
