// Copyright (c) 2017 mpmarcelomp@gmail.com
// See LICENSE for license information.

import UIKit
import MASlider

final class ViewController: UIViewController {

    // MARK: - State

    private var step: Int = 2
    private var numberOfSteps: Int = 4
    private var trackTintColor: UIColor = .systemRed
    private var thumbTintColor: UIColor = .systemRed
    private var thumbImage: UIImage? = UIImage(systemName: "lock.fill")
    private var stepText: String = ""
    private var selectedStepText: String = ""

    // MARK: - Subviews

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.contentInsetAdjustmentBehavior = .automatic
        sv.preservesSuperviewLayoutMargins = true
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.isLayoutMarginsRelativeArrangement = true
        sv.directionalLayoutMargins = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        sv.axis = .vertical
        sv.spacing = 16
        sv.alignment = .fill
        return sv
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.text = "MASlider (UIKit)"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textAlignment = .center
        return l
    }()

    private lazy var slider: MASliderControl = {
        let s = MASliderControl()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.setContentHuggingPriority(.defaultHigh, for: .vertical)
        s.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return s
    }()

    private lazy var stepLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textAlignment = .center
        return l
    }()

    private lazy var stepsStepper: UIStepper = {
        let s = UIStepper()
        s.minimumValue = 2
        s.maximumValue = 10
        s.stepValue = 1
        s.value = Double(numberOfSteps)
        s.addTarget(self, action: #selector(stepperValueChanged), for: .valueChanged)
        return s
    }()

    private lazy var stepsLabel: UILabel = {
        let l = UILabel()
        l.text = "Steps"
        l.font = .systemFont(ofSize: 17)
        return l
    }()

    private lazy var trackColorWell: UIColorWell = {
        let w = UIColorWell()
        w.supportsAlpha = false
        w.selectedColor = trackTintColor
        w.addTarget(self, action: #selector(trackColorChanged), for: .valueChanged)
        return w
    }()

    private lazy var thumbColorWell: UIColorWell = {
        let w = UIColorWell()
        w.supportsAlpha = false
        w.selectedColor = thumbTintColor
        w.addTarget(self, action: #selector(thumbColorChanged), for: .valueChanged)
        return w
    }()

    private lazy var stepTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Step text"
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 17)
        tf.addTarget(self, action: #selector(stepTextChanged), for: .editingChanged)
        return tf
    }()

    private lazy var selectedStepTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Selected step text"
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 17)
        tf.addTarget(self, action: #selector(selectedStepTextChanged), for: .editingChanged)
        return tf
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        configureSlider()
        updateStepLabel()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        let stepsRow = UIStackView(arrangedSubviews: [stepsLabel, stepsStepper])
        stepsRow.axis = .horizontal
        stepsRow.spacing = 12
        stepsRow.alignment = .center

        let trackColorRow = UIStackView(arrangedSubviews: [labelWithText("Track color"), trackColorWell])
        trackColorRow.axis = .horizontal
        trackColorRow.spacing = 12
        trackColorRow.alignment = .center

        let thumbColorRow = UIStackView(arrangedSubviews: [labelWithText("Thumb color"), thumbColorWell])
        thumbColorRow.axis = .horizontal
        thumbColorRow.spacing = 12
        thumbColorRow.alignment = .center

        let stepTextRow = UIStackView(arrangedSubviews: [labelWithText("Step text"), stepTextField])
        stepTextRow.axis = .horizontal
        stepTextRow.spacing = 12
        stepTextRow.alignment = .center

        let selectedStepTextRow = UIStackView(arrangedSubviews: [labelWithText("Selected text"), selectedStepTextField])
        selectedStepTextRow.axis = .horizontal
        selectedStepTextRow.spacing = 12
        selectedStepTextRow.alignment = .center

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(stepLabel)
        stackView.addArrangedSubview(stepsRow)
        stackView.addArrangedSubview(trackColorRow)
        stackView.addArrangedSubview(thumbColorRow)
        stackView.addArrangedSubview(stepTextRow)
        stackView.addArrangedSubview(selectedStepTextRow)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
        ])
    }

    private func labelWithText(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 17)
        return l
    }

    private func configureSlider() {
        slider.step = step
        slider.numberOfSteps = numberOfSteps
        slider.trackTintColor = trackTintColor
        slider.thumbTintColor = thumbTintColor
        if let thumbImage = thumbImage {
            slider.thumbImage = thumbImage
        }
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
    }

    private func updateStepLabel() {
        stepLabel.text = "Step: \(step) of \(numberOfSteps)"
    }

    // MARK: - Actions

    @objc private func sliderValueChanged() {
        step = slider.step
        updateStepLabel()
    }

    @objc private func stepperValueChanged() {
        let newCount = Int(stepsStepper.value)
        numberOfSteps = newCount
        step = min(step, numberOfSteps - 1)
        slider.numberOfSteps = numberOfSteps
        slider.step = step
        updateStepLabel()
    }

    @objc private func trackColorChanged() {
        guard let color = trackColorWell.selectedColor else { return }
        trackTintColor = color
        slider.trackTintColor = color
    }

    @objc private func thumbColorChanged() {
        guard let color = thumbColorWell.selectedColor else { return }
        thumbTintColor = color
        slider.thumbTintColor = color
    }

    @objc private func stepTextChanged() {
        stepText = stepTextField.text ?? ""
        slider.stepText = stepText
    }

    @objc private func selectedStepTextChanged() {
        selectedStepText = selectedStepTextField.text ?? ""
        slider.selectedStepText = selectedStepText
    }
}
