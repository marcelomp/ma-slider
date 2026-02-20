import SwiftUI

struct MASliderPreview: UIViewRepresentable {
    typealias UIViewType = _MASlider
    
    func makeUIView(context: Context) -> _MASlider {
        let uiView = _MASlider()
        uiView.step = 2
        uiView.numberOfSteps = 10
        uiView.thumbImage = UIImage(systemName: "person")
        uiView.stepText = "foo"
        return uiView
    }
    
    func updateUIView(
        _ uiView: _MASlider,
        context: Context
    ) {
        //
    }
}

#Preview {
    MASliderPreview()
        .border(.red)
}
