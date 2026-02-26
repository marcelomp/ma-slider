// Copyright (c) 2017 mpmarcelomp@gmail.com
// See LICENSE for license information.

import SwiftUI

import MASlider

struct SwiftUISampleView: View {
    @State private var step: Int = 2
    @State private var numberOfSteps: Int = 4
    @State private var trackTintColor: Color = .red
    @State private var thumbTintColor: Color = .red
    @State private var thumbImage: UIImage? = UIImage(systemName: "lock.fill")
    @State private var stepText: String = ""
    @State private var selectedStepText: String = ""
    
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
                stepText: stepText.isEmpty ? nil : stepText,
                selectedStepText: selectedStepText.isEmpty ? nil : selectedStepText)
            
            Text("Step: \(step) of \(numberOfSteps)")
                .font(.headline)

            Stepper("Steps", value: $numberOfSteps, in: 2...10)

            ColorPicker("trackTintColor", selection: $trackTintColor)
            ColorPicker("thumbTintColor", selection: $thumbTintColor)

            TextField("Step text", text: $stepText)
                .textFieldStyle(.roundedBorder)
            TextField("Selected step text", text: $selectedStepText)
                .textFieldStyle(.roundedBorder)
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
