// Copyright (c) 2017 mpmarcelomp@gmail.com
// See LICENSE for license information.

import UIKit

/// Discrete step slider; subclasses ``UIControl`` and sends ``UIControl/Event/valueChanged``.
/// Pan or tap to change step; supports optional step labels, thumb image, and full VoiceOver accessibility.
final public class MASliderControl: UIControl {

    // MARK: - Types

    private struct StepCenterPair {
        var index: Int
        var center: CGPoint
    }

    public protocol DataSource: AnyObject {
        func slider(_ slider: MASliderControl, titleForIndex index: Int) -> NSAttributedString
    }

    private struct DirtyFlags: OptionSet {
        let rawValue: UInt8
        static let track      = DirtyFlags(rawValue: 1 << 0)
        static let knots      = DirtyFlags(rawValue: 1 << 1)
        static let thumb      = DirtyFlags(rawValue: 1 << 2)
        static let labels     = DirtyFlags(rawValue: 1 << 3)
        static let knotColors = DirtyFlags(rawValue: 1 << 4)
        static let thumbColor = DirtyFlags(rawValue: 1 << 5)
        static let geometry: DirtyFlags = [.track, .knots, .thumb, .labels]
        static let all: DirtyFlags = [.track, .knots, .thumb, .labels, .knotColors, .thumbColor]
    }

    private enum Layout {
        static let thumbSize: CGFloat = 44
        static let knotSize: CGFloat = 16
        static let trackHeight: CGFloat = 4
        static let labelTopPadding: CGFloat = 8
        static let animationDuration: TimeInterval = 0.15
        static let springDamping: CGFloat = 0.7
        static let labelFont: UIFont = .systemFont(ofSize: 11)
        static let selectedLabelFont: UIFont = .boldSystemFont(ofSize: 13)
    }

    // MARK: - Public properties

    /// Height from thumb plus label area; width is unspecified so the control fills horizontally.
    public override var intrinsicContentSize: CGSize {
        var height = Layout.thumbSize
        if hasLabels {
            height = valueLabels.map { $0.frame.maxY }.max() ?? Layout.thumbSize
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    /// Current step index (0-based); clamped to ``numberOfSteps`` - 1.
    public var step: Int {
        get { _step }
        set {
            let clamped = min(max(newValue, 0), numberOfSteps - 1)
            guard clamped != _step else { return }
            _step = clamped
            dirty.insert([.thumb, .labels])
            setNeedsLayout()
        }
    }

    /// Total number of steps (minimum 2).
    public var numberOfSteps: Int {
        get { _numberOfSteps }
        set {
            let clamped = max(2, newValue)
            guard clamped != _numberOfSteps else { return }
            _numberOfSteps = clamped
            _step = min(_step, _numberOfSteps - 1)
            dirty.insert(.geometry)
            setNeedsLayout()
        }
    }

    /// Color of the track and step knots.
    public var trackTintColor: UIColor {
        get { _trackTintColor }
        set {
            _trackTintColor = newValue
            dirty.insert([.track, .knotColors])
            setNeedsLayout()
        }
    }

    /// Background color of the thumb.
    public var thumbTintColor: UIColor {
        get { _thumbTintColor }
        set {
            _thumbTintColor = newValue
            dirty.insert(.thumbColor)
            setNeedsLayout()
        }
    }

    /// Optional image on the thumb (e.g. SF Symbol); rendered as template with white tint.
    public var thumbImage: UIImage? {
        didSet {
            if let img = thumbImage?.withRenderingMode(.alwaysTemplate) {
                thumbImageView.image = img
                thumbImageView.isHidden = false
            } else {
                thumbImageView.image = nil
                thumbImageView.isHidden = true
            }
        }
    }

    /// Label text for unselected steps.
    public var stepText: String {
        get { _stepText }
        set {
            _stepText = newValue
            dirty.insert(.labels)
            setNeedsLayout()
        }
    }

    /// Attributed label for unselected steps (overrides `stepText` when set).
    public var attributedStepText: NSAttributedString {
        get { _attributedStepText }
        set {
            _attributedStepText = newValue
            dirty.insert(.labels)
            setNeedsLayout()
        }
    }

    /// Label text for the selected step.
    public var selectedStepText: String {
        get { _selectedStepText }
        set {
            _selectedStepText = newValue
            dirty.insert(.labels)
            setNeedsLayout()
        }
    }

    /// Attributed label for the selected step (overrides `selectedStepText` when set).
    public var attributedSelectedStepText: NSAttributedString {
        get { _attributedSelectedStepText }
        set {
            _attributedSelectedStepText = newValue
            dirty.insert(.labels)
            setNeedsLayout()
        }
    }

    /// Optional data source for custom per-step titles.
    public weak var dataSource: MASliderControl.DataSource?

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    /// Sets the current step; when `animated` is true, the thumb animates to the new position.
    public func set(step: Int, animated: Bool) {
        if animated {
            UIView.animate(
                withDuration: Layout.animationDuration,
                delay: 0,
                usingSpringWithDamping: Layout.springDamping,
                initialSpringVelocity: 0,
                options: [],
                animations: { self.step = step; self.layoutIfNeeded() }
            )
        } else {
            self.step = step
        }
    }

    // MARK: - Private state

    private var _step: Int = 0
    private var _numberOfSteps: Int = 2
    private var _trackTintColor: UIColor = .systemBlue
    private var _thumbTintColor: UIColor = .systemBlue
    private var _stepText: String = ""
    private var _attributedStepText: NSAttributedString = .init(string: "")
    private var _selectedStepText: String = ""
    private var _attributedSelectedStepText: NSAttributedString = .init(string: "")

    private var dirty: DirtyFlags = .all

    // MARK: - Sublayers & subviews (non-optional)

    private let trackLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        return l
    }()

    private let knotsContainerLayer = CALayer()

    private var knotLayers: [CAShapeLayer] = []

    private let thumbView: UIView = {
        let v = UIView(frame: CGRect(origin: .zero, size: CGSize(width: Layout.thumbSize, height: Layout.thumbSize)))
        v.layer.cornerRadius = Layout.thumbSize / 2
        v.clipsToBounds = true
        return v
    }()

    private let thumbImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        iv.isHidden = true
        return iv
    }()

    private var valueLabels: [UILabel] = []

    private lazy var panGesture: UIPanGestureRecognizer = {
        let g = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        g.cancelsTouchesInView = false
        return g
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let g = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        return g
    }()

    // MARK: - Setup

    private func commonInit() {
        backgroundColor = .clear

        layer.addSublayer(trackLayer)
        layer.addSublayer(knotsContainerLayer)

        thumbView.backgroundColor = _thumbTintColor
        thumbImageView.frame = thumbView.bounds.insetBy(dx: 8, dy: 8)
        thumbImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        thumbView.addSubview(thumbImageView)
        addSubview(thumbView)

        thumbView.addGestureRecognizer(panGesture)
        tapGesture.require(toFail: panGesture)
        addGestureRecognizer(tapGesture)

        // Accessibility
        isAccessibilityElement = true
        accessibilityTraits = .adjustable
        updateAccessibilityValue()
    }

    // MARK: - Geometry helpers

    private var hasLabels: Bool {
        !_stepText.isEmpty || !_selectedStepText.isEmpty ||
        _attributedStepText.length > 0 || _attributedSelectedStepText.length > 0 ||
        dataSource != nil
    }

    private var sliderRect: CGRect {
        CGRect(x: 0, y: 0, width: bounds.width, height: Layout.thumbSize)
    }

    private var labelsRect: CGRect {
        CGRect(x: 0, y: Layout.thumbSize, width: bounds.width, height: bounds.height - Layout.thumbSize)
    }

    private func trackRect() -> CGRect {
        CGRect(
            x: Layout.thumbSize / 2,
            y: sliderRect.height / 2 - Layout.trackHeight / 2,
            width: sliderRect.width - Layout.thumbSize,
            height: Layout.trackHeight
        )
    }

    private func centerPosition(for index: Int) -> CGPoint {
        guard numberOfSteps > 1 else { return CGPoint(x: Layout.thumbSize / 2, y: sliderRect.height / 2) }

        let tr = trackRect()
        let xPos = tr.minX + tr.width * CGFloat(index) / CGFloat(numberOfSteps - 1)
        return CGPoint(x: xPos, y: sliderRect.height / 2)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let flags = dirty
        dirty = []

        if flags.contains(.track) {
            layoutTrack()
        }

        if flags.contains(.knots) {
            reconcileKnots()
            layoutKnots()
        }

        if flags.contains(.knotColors) {
            updateKnotColors()
        }

        if flags.contains(.thumb) {
            layoutThumb()
        }

        if flags.contains(.thumbColor) {
            thumbView.backgroundColor = _thumbTintColor
        }

        if flags.contains(.labels) {
            reconcileLabels()
            layoutLabels()
            invalidateIntrinsicContentSize()
        }

        updateAccessibilityValue()
    }

    private func layoutTrack() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.path = UIBezierPath(rect: trackRect()).cgPath
        trackLayer.fillColor = _trackTintColor.cgColor
        CATransaction.commit()
    }

    // MARK: - Knot reconciliation

    private func reconcileKnots() {
        let current = knotLayers.count
        let target = numberOfSteps

        if current < target {
            for _ in current..<target {
                let l = CAShapeLayer()
                knotsContainerLayer.addSublayer(l)
                knotLayers.append(l)
            }
        } else if current > target {
            for i in stride(from: current - 1, through: target, by: -1) {
                knotLayers[i].removeFromSuperlayer()
            }
            knotLayers.removeLast(current - target)
        }
    }

    private func layoutKnots() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        knotsContainerLayer.frame = sliderRect
        for (i, knot) in knotLayers.enumerated() {
            let center = centerPosition(for: i)
            let rect = CGRect(
                x: center.x - Layout.knotSize / 2,
                y: center.y - Layout.knotSize / 2,
                width: Layout.knotSize,
                height: Layout.knotSize
            )
            knot.path = UIBezierPath(roundedRect: rect, cornerRadius: Layout.knotSize / 2).cgPath
            knot.fillColor = _trackTintColor.cgColor
        }
        CATransaction.commit()
    }

    private func updateKnotColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for knot in knotLayers {
            knot.fillColor = _trackTintColor.cgColor
        }
        CATransaction.commit()
    }

    // MARK: - Thumb layout

    private func layoutThumb() {
        let pos = centerPosition(for: _step)
        thumbView.center = pos
    }

    // MARK: - Label reconciliation

    private func reconcileLabels() {
        let current = valueLabels.count
        let target = hasLabels ? numberOfSteps : 0

        if current < target {
            for _ in current..<target {
                let label = UILabel()
                label.textAlignment = .center
                addSubview(label)
                valueLabels.append(label)
            }
        } else if current > target {
            for i in stride(from: current - 1, through: target, by: -1) {
                valueLabels[i].removeFromSuperview()
            }
            valueLabels.removeLast(current - target)
        }
    }

    private func layoutLabels() {
        guard hasLabels else { return }

        for (i, label) in valueLabels.enumerated() {
            let selected = (i == _step)

            // Set content
            if let ds = dataSource {
                let attrib = ds.slider(self, titleForIndex: i)
                if attrib.length > 0 {
                    label.attributedText = attrib
                } else {
                    applyDefaultText(to: label, selected: selected)
                }
            } else {
                applyDefaultText(to: label, selected: selected)
            }

            label.sizeToFit()

            // Position
            let center = centerPosition(for: i)
            var xCenter = center.x
            let halfWidth = label.frame.width / 2

            if xCenter - halfWidth < 0 {
                xCenter = halfWidth
            } else if xCenter + halfWidth > bounds.width {
                xCenter = bounds.width - halfWidth
            }

            label.center = CGPoint(x: xCenter, y: Layout.thumbSize + Layout.labelTopPadding + label.frame.height / 2)
        }
    }

    private func applyDefaultText(to label: UILabel, selected: Bool) {
        if selected {
            label.font = Layout.selectedLabelFont
            label.textColor = .label
            if _attributedSelectedStepText.length > 0 {
                label.attributedText = _attributedSelectedStepText
            } else {
                label.attributedText = nil
                label.text = _selectedStepText
            }
        } else {
            label.font = Layout.labelFont
            label.textColor = .secondaryLabel
            if _attributedStepText.length > 0 {
                label.attributedText = _attributedStepText
            } else {
                label.attributedText = nil
                label.text = _stepText
            }
        }
    }

    // MARK: - Gestures

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let state = recognizer.state

        if state == .began || state == .changed {
            let t = recognizer.translation(in: self)
            var center = CGPoint(x: thumbView.center.x + t.x, y: thumbView.center.y)

            let halfThumb = Layout.thumbSize / 2
            center.x = min(max(center.x, halfThumb), bounds.width - halfThumb)

            thumbView.center = center
            recognizer.setTranslation(.zero, in: self)

        } else if state == .ended {
            let nearest = nearestStepCenter(from: thumbView.center)
            _step = nearest.index
            dirty.insert(.labels)

            UIView.animate(
                withDuration: Layout.animationDuration,
                delay: 0,
                usingSpringWithDamping: Layout.springDamping,
                initialSpringVelocity: 0,
                options: []
            ) {
                self.thumbView.center = nearest.center
                self.layoutLabels()
            } completion: { _ in
                self.updateAccessibilityValue()
                self.sendActions(for: .valueChanged)
            }
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self)
        let nearest = nearestStepCenter(from: location)

        guard nearest.index != _step else { return }

        _step = nearest.index
        dirty.insert(.labels)

        UIView.animate(
            withDuration: Layout.animationDuration,
            delay: 0,
            usingSpringWithDamping: Layout.springDamping,
            initialSpringVelocity: 0,
            options: []
        ) {
            self.thumbView.center = nearest.center
            self.layoutLabels()
        } completion: { _ in
            self.updateAccessibilityValue()
            self.sendActions(for: .valueChanged)
        }
    }

    // MARK: - Nearest step

    private func nearestStepCenter(from point: CGPoint) -> StepCenterPair {
        var bestDistance = CGFloat.greatestFiniteMagnitude
        var bestIndex = 0
        var bestCenter = centerPosition(for: 0)

        for i in 0..<numberOfSteps {
            let c = centerPosition(for: i)
            let dx = point.x - c.x
            let dy = point.y - c.y
            let dist = dx * dx + dy * dy
            if dist < bestDistance {
                bestDistance = dist
                bestIndex = i
                bestCenter = c
            }
        }

        return StepCenterPair(index: bestIndex, center: bestCenter)
    }

    // MARK: - Accessibility

    private func updateAccessibilityValue() {
        accessibilityValue = "Step \(_step + 1) of \(numberOfSteps)"
    }

    public override func accessibilityIncrement() {
        guard _step < numberOfSteps - 1 else { return }
        set(step: _step + 1, animated: true)
        sendActions(for: .valueChanged)
    }

    public override func accessibilityDecrement() {
        guard _step > 0 else { return }
        set(step: _step - 1, animated: true)
        sendActions(for: .valueChanged)
    }

    // MARK: - Trait changes

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            dirty.insert(.labels)
            setNeedsLayout()
        }
    }
}
