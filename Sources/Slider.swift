import SwiftUI

public struct MASliderPreview: UIViewRepresentable {
    public init() {}
    
    // MARK: UIViewRepresentable
    
    public typealias UIViewType = _MASlider
    
    public func makeUIView(context: Context) -> UIViewType {
        let uiView = _MASlider()
        uiView.step = 2
        uiView.numberOfSteps = 3
        uiView.trackTintColor = .systemBlue
        uiView.thumbTintColor = .systemRed
        uiView.thumbImage = UIImage(systemName: "person")
        uiView.stepText = "Foo"
//        uiView.attributedStepText
        uiView.selectedStepText = "Bar"
//        uiView.attributedSelectedStepText
        
        return uiView
    }
    
    public func updateUIView(
        _ uiView: UIViewType,
        context: Context
    ) {
        //
    }
}

#Preview {
    MASliderPreview()
        .border(.red)
}
