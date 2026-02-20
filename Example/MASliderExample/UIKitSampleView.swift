import SwiftUI
import UIKit

struct UIKitSampleView: UIViewControllerRepresentable {
    
    // MARK: UIViewControllerRepresentable

    typealias UIViewControllerType = ViewController

    func makeUIViewController(context: Context) -> ViewController {
        ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // ViewController is self-contained; no SwiftUI-driven props to sync.
    }
}
