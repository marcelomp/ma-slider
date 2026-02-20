import UIKit

/// Discrete step slider; subclasses ``UIControl`` and sends ``UIControl/Event/valueChanged``. Pan or tap (with wobble) to change step; supports optional step labels and thumb image.
final public class MASliderControl: UIControl {
    private struct StepCenterPair {
        var index: Int
        var center: CGPoint
    }
    
    protocol DataSource: AnyObject {
        func slider(_ slider: MASliderControl, titleForIndex index: Int) -> NSAttributedString
    }
    
    /// Height from thumb plus label area; width is unspecified so the control fills horizontally.
    public override var intrinsicContentSize: CGSize {
        let height = kThumbSize + rectForLabels().height
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    /// Current step index (0-based); clamped to ``numberOfSteps`` - 1.
    public var step: Int {
        get { _step }
        set {
            _step = min(newValue, numberOfSteps - 1)
            updateThumb(withSelectedStep: _step)
            updateValueLabels()
        }
    }

    /// Total number of steps (minimum 2).
    public var numberOfSteps: Int {
        get { _numberOfSteps }
        set {
            _numberOfSteps = max(2, newValue)
            updateKnots()
        }
    }

    /// Color of the track and step knots.
    public var trackTintColor: UIColor {
        get { _trackTintColor }
        set {
            _trackTintColor = newValue
            trackLayer.fillColor = _trackTintColor.cgColor
            updateKnotsColor()
            setNeedsDisplay()
        }
    }

    /// Background color of the thumb.
    public var thumbTintColor: UIColor {
        get { _thumbTintColor }
        set {
            _thumbTintColor = newValue
            thumb.backgroundColor = thumbTintColor
            setNeedsDisplay()
        }
    }

    /// Optional image on the thumb (e.g. SF Symbol); rendered as template with white tint.
    public var thumbImage: UIImage? {
        didSet {
            guard let thumbImage = thumbImage else { return }
            let img = thumbImage.withRenderingMode(.alwaysTemplate)
            thumb.setImage(img, for: .normal)
            thumb.setImage(img, for: .selected)
            thumb.setImage(img, for: .highlighted)
            thumb.tintColor = .white
            setNeedsDisplay()
        }
    }

    /// Label text for unselected steps.
    public var stepText: String {
        get { _stepText }
        set {
            _stepText = newValue.isEmpty ? "" : newValue
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    /// Attributed label for unselected steps (overrides `stepText` when set).
    public var attributedStepText: NSAttributedString {
        get { _attributedStepText }
        set {
            _attributedStepText = newValue.length > 0 ? newValue : NSAttributedString(string: "")
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    /// Label text for the selected step.
    public var selectedStepText: String {
        get { _selectedStepText }
        set {
            _selectedStepText = newValue.isEmpty ? "" : newValue
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    /// Attributed label for the selected step (overrides `selectedStepText` when set).
    public var attributedSelectedStepText: NSAttributedString {
        get { _attributedSelectedStepText }
        set {
            _attributedSelectedStepText = newValue.length > 0 ? newValue : NSAttributedString(string: "")
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    /// Optional data source for custom per-step titles.
    weak var dataSource: MASliderControl.DataSource?

    // MARK: - Init

    /// Initializes a new ``MASliderControl`` instance.
    /// - Parameter frame: The frame for the control.
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initProperties()
    }

    /// Initializes a new ``MASliderControl`` instance from a NSCoder.
    /// - Parameter coder: The NSCoder to decode the control from.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initProperties()
    }

    /// Sets the current step; when `animated` is true, the thumb animates to the new position.
    /// - Parameters:
    ///   - step: The step index to set (clamped to valid range).
    ///   - animated: When true, the thumb animates to the new position.
    public func set(step: Int, animated: Bool) {
        let animations: () -> Void = { self.step = step }
        
        if animated {
            UIView.animate(
                withDuration: kAnimationSpeed,
                delay: 0,
                options: .curveEaseInOut,
                animations: animations)
        } else {
            animations()
        }
    }

    // MARK: - Setup

    /// Initializes the properties for the ``MASliderControl`` instance.
    private func initProperties() {
        trackLayer = CAShapeLayer()
        trackLayer.path = trackBezierPath().cgPath
        trackLayer.fillColor = trackTintColor.cgColor
        layer.addSublayer(trackLayer)

        knotsLayer = CALayer()
        layer.addSublayer(knotsLayer)
        knots = []

        thumb.center = CGPoint(x: kThumbSize / 2, y: rectForSlider().size.height / 2)
        thumb.layer.cornerRadius = thumb.frame.size.height / 2
        thumb.backgroundColor = thumbTintColor
        addSubview(thumb)

        valueLabels = []

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGestureRecognizer.cancelsTouchesInView = false
        thumb.addGestureRecognizer(panGestureRecognizer)

        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGestureRecognizer.cancelsTouchesInView = false
        thumb.addGestureRecognizer(tapGestureRecognizer)
        
        backgroundColor = .systemGreen
    }

    // MARK: - Geometry
    
    /// Animation speed for the thumb movement.
    private let kAnimationSpeed: CGFloat = 0.15
    /// Size of the thumb.
    private let kThumbSize: CGFloat = 44
    /// Height of the label area.
    private let kLabelAreaHeight: CGFloat = 24
    /// Size of the step knots.
    private let kKnotSize: CGFloat = 16
    /// Width of the track.
    private let kTrackWidth: CGFloat = 4

    /// Rectangle for the track.
    private func trackRect() -> CGRect {
        CGRect(
            x: kThumbSize / 2,
            y: rectForSlider().size.height / 2 - kTrackWidth / 2,
            width: rectForSlider().size.width - kThumbSize,
            height: kTrackWidth
        )
    }

    /// Bezier path for the track.
    private func trackBezierPath() -> UIBezierPath {
        UIBezierPath(rect: trackRect())
    }

    /// Rectangle for the slider.
    private func rectForSlider() -> CGRect {
        CGRect(x: 0, y: 0, width: bounds.size.width, height: kThumbSize)
    }

    /// Rectangle for the labels.
    private func rectForLabels() -> CGRect {
        CGRect(x: 0, y: kThumbSize, width: bounds.size.width, height: bounds.size.height - kThumbSize)
    }

    /// Center position for the step at the given index.
    private func centerPosition(for index: Int) -> CGPoint {
        var xPos = trackRect().size.width / CGFloat(numberOfSteps - 1) * CGFloat(index) + kThumbSize / 2
        let yPos = rectForSlider().size.height / 2

        if index == 0 {
            xPos = kThumbSize / 2
        } else if index == numberOfSteps - 1 {
            xPos = rectForSlider().size.width - kThumbSize / 2
        }

        return CGPoint(x: xPos, y: yPos)
    }

    /// Knot for the step at the given index.
    private func knot(for index: Int) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let center = centerPosition(for: index)
        let rect = CGRect(x: center.x - kKnotSize / 2, y: center.y - kKnotSize / 2, width: kKnotSize, height: kKnotSize)
        layer.path = UIBezierPath(roundedRect: rect, cornerRadius: kKnotSize / 2).cgPath
        layer.fillColor = trackTintColor.cgColor
        return layer
    }

    // MARK: - Updates
    
    /// Current step index (0-based); clamped to ``numberOfSteps`` - 1.
    private var _step: Int = 0
    
    /// Total number of steps (minimum 2).
    private var _numberOfSteps: Int = 2
    
    /// Color of the track and step knots.
    private var _trackTintColor: UIColor = .systemBlue
    
    /// Background color of the thumb.
    private var _thumbTintColor: UIColor = .systemBlue
    
    /// Label text for unselected steps.
    private var _stepText: String = ""
    
    /// Attributed label for unselected steps (overrides `stepText` when set).
    private var _attributedStepText: NSAttributedString = .init(string: "")
    
    /// Label text for the selected step.
    private var _selectedStepText: String = ""
    
    /// Attributed label for the selected step (overrides `selectedStepText` when set).
    private var _attributedSelectedStepText: NSAttributedString = .init(string: "")
    
    /// Layer for the track.
    private var trackLayer: CAShapeLayer!
    
    /// Layer for the step knots.
    private var knotsLayer: CALayer!
    
    /// Step knots.
    private var knots: [CAShapeLayer] = []
    
    /// Thumb button.
    private lazy var thumb: UIButton = {
        let size = CGSize(width: self.kThumbSize, height: self.kThumbSize)
        let thumb = UIButton(frame: CGRect(origin: .zero, size: size))
        thumb.translatesAutoresizingMaskIntoConstraints = true
        return thumb
    }()
    
    /// Value labels.
    private var valueLabels: [UILabel] = []
    
    /// Pan gesture recognizer.
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    /// Tap gesture recognizer.
    private var tapGestureRecognizer: UITapGestureRecognizer!

    /// Updates the layer for the step knots.
    private func updateKnotsLayer() {
        knotsLayer.frame = rectForSlider()
    }

    /// Updates the color of the step knots.
    private func updateKnotsColor() {
        for knot in knots {
            knot.fillColor = trackTintColor.cgColor
        }
    }

    /// Updates the step knots.
    private func updateKnots() {
        for layer in knots {
            layer.removeFromSuperlayer()
        }

        var newKnots: [CAShapeLayer] = []
        for i in 0..<numberOfSteps {
            let layer = knot(for: i)
            knotsLayer.addSublayer(layer)
            newKnots.append(layer)
        }
        knots = newKnots
        setNeedsDisplay()
    }

    /// Updates the track.
    private func updateTrack() {
        trackLayer.path = trackBezierPath().cgPath
        setNeedsDisplay()
    }

    /// Updates the thumb.
    private func updateThumb(withSelectedStep step: Int) {
        let pos = centerPosition(for: step)
        thumb.center = pos
        setNeedsDisplay()
    }

    /// Value label for the step at the given index.
    /// - Parameters:
    ///   - index: The index of the step.
    ///   - selected: Whether the step is selected.
    /// - Returns: A ``UILabel`` for the step.
    private func valueLabel(for index: Int, selected: Bool) -> UILabel {
        let labelsRect = rectForLabels()
        let xPos = labelsRect.size.width / CGFloat(numberOfSteps) * CGFloat(index)
        let yPos = labelsRect.origin.y
        let center = centerPosition(for: index)
        let origin = CGPoint(x: xPos, y: yPos)
        let size = CGSize(width: 64, height: labelsRect.size.height)
        let rect = CGRect(origin: origin, size: size)
        
        let label = UILabel(frame: rect)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 11)
        label.text = stepText
        label.textColor = .lightGray

        if attributedStepText.length > 0 {
            label.attributedText = attributedStepText
        }

        if selected {
            label.font = UIFont.boldSystemFont(ofSize: 13)
            label.text = selectedStepText
            label.textColor = .black
            if attributedSelectedStepText.length > 0 {
                label.attributedText = attributedSelectedStepText
            }
        }

        if let dataSource = dataSource {
            let attribString = dataSource.slider(self, titleForIndex: index)
            if attribString.length > 0 {
                label.attributedText = attribString
            }
        }

        label.sizeToFit()

        let frame = label.frame
        var xCenter = center.x

        if xCenter - frame.size.width / 2 < 0 {
            xCenter = frame.size.width / 2
            
        } else if xCenter + frame.size.width / 2 > labelsRect.size.width {
            xCenter = labelsRect.size.width - frame.size.width / 2
        }

        label.center = CGPoint(x: xCenter, y: label.center.y + 8)
        addSubview(label)

        return label
    }

    /// Updates the value labels.
    private func updateValueLabels() {
        for label in valueLabels {
            label.removeFromSuperview()
        }

        var newValueLabels: [UILabel] = []
        for i in 0..<numberOfSteps {
            let label = valueLabel(for: i, selected: i == step)
            newValueLabels.append(label)
        }
        valueLabels = newValueLabels
    }

    /// Distance squared between two points.
    /// - Parameters:
    ///   - from: The starting point.
    ///   - to: The ending point.
    /// - Returns: The distance squared between the two points.
    private func cgPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    /// Nearest step center to the given point.
    /// - Parameters:
    ///   - point: The point to find the nearest step center to.
    /// - Returns: A ``StepCenterPair`` containing the index and center of the nearest step.
    private func nearestStepCenter(from point: CGPoint) -> StepCenterPair {
        var distance = CGFloat.greatestFiniteMagnitude
        var index = 0
        var nearestStepCenter = centerPosition(for: index)

        for i in 0..<numberOfSteps {
            let stepCenter = centerPosition(for: i)
            let stepDistance = cgPointDistanceSquared(from: point, to: stepCenter)

            if stepDistance < distance {
                distance = stepDistance
                index = i
                nearestStepCenter = stepCenter
            }
        }

        return StepCenterPair(index: index, center: nearestStepCenter)
    }

    // MARK: - Gestures

    /// Handles the pan gesture.
    /// - Parameters:
    ///   - recognizer: The pan gesture recognizer.
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let state = recognizer.state

        if state == .began || state == .changed {
            let t = recognizer.translation(in: self)
            var center = CGPoint(x: thumb.center.x + t.x, y: thumb.center.y)

            if center.x + thumb.frame.size.width / 2 > frame.size.width {
                center = CGPoint(x: frame.size.width - thumb.frame.size.width / 2, y: center.y)
            } else if center.x - thumb.frame.size.width / 2 < 0 {
                center = CGPoint(x: thumb.frame.size.width / 2, y: center.y)
            }

            thumb.center = center
            recognizer.setTranslation(.zero, in: self)

        } else if state == .ended {
            UIView.animate(withDuration: kAnimationSpeed, delay: 0, options: .curveEaseInOut) {
                let stepCenterPair = self.nearestStepCenter(from: self.thumb.center)
                self.step = stepCenterPair.index
                
            } completion: { _ in
                self.sendActions(for: .valueChanged)
            }
        }
    }

    /// Handles the tap gesture.
    /// - Parameters:
    ///   - recognizer: The tap gesture recognizer.
    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let stepCenterPair = nearestStepCenter(from: thumb.center)
        set(step: stepCenterPair.index, animated: true)
        runWobbleAnimation {
            self.sendActions(for: .valueChanged)
        }
    }

    /// Runs the wobble animation.
    /// - Parameters:
    ///   - completion: The completion block to call when the animation is complete.
    private func runWobbleAnimation(completion: (() -> Void)? = nil) {
        let duration: TimeInterval = 0.25
        let scale: CGFloat = 1.18
        let rotation: CGFloat = .pi / 60
        UIView.animate(
            withDuration: duration * 0.4,
            delay: 0,
            options: .curveEaseOut,
            animations: {
                self.thumb.transform = CGAffineTransform(scaleX: scale, y: scale).rotated(by: -rotation)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: duration * 0.6,
                    delay: 0,
                    usingSpringWithDamping: 0.4,
                    initialSpringVelocity: 0.5,
                    options: [],
                    animations: {
                        self.thumb.transform = .identity
                    },
                    completion: { _ in
                        completion?()
                    }
                )
            }
        )
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateKnotsLayer()
        updateKnots()
        updateTrack()
        updateThumb(withSelectedStep: step)
        updateValueLabels()
    }
}
