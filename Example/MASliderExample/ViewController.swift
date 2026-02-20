import UIKit
import MASlider

final class ViewController: UIViewController {

    // MARK: - State

    private var step: Int = 2
    private var numberOfSteps: Int = 4
    private var trackTintColor: UIColor = .systemRed
    private var thumbTintColor: UIColor = .systemRed
    private var thumbImage: UIImage? = UIImage(systemName: "lock.fill")

    // MARK: - Subviews

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
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

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(slider)
        stackView.addArrangedSubview(stepLabel)
        stackView.addArrangedSubview(stepsRow)
        stackView.addArrangedSubview(trackColorRow)
        stackView.addArrangedSubview(thumbColorRow)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),
            slider.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
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
}
