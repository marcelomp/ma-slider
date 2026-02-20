//
//  _MASlider.swift
//  MASlider
//
//  Swift translation of MASlider (Objective-C).
//

import UIKit

private let kAnimationSpeed: CGFloat = 0.15
private let kThumbSize: CGFloat = 44
private let kKnotSize: CGFloat = 16
private let kTrackWidth: CGFloat = 4

private struct StepCenterPair {
    var index: Int
    var center: CGPoint
}

protocol MASliderDataSource: AnyObject {
    func slider(_ slider: _MASlider, titleForIndex index: Int) -> NSAttributedString
}

final public class _MASlider: UIControl {
    public var step: Int {
        get { _step }
        set {
            _step = newValue > (numberOfSteps - 1) ? (numberOfSteps - 1) : newValue
            updateThumb(withSelectedStep: _step)
            updateValueLabels()
        }
    }

    public var numberOfSteps: Int {
        get { _numberOfSteps }
        set {
            _numberOfSteps = max(2, newValue)
            updateKnots()
        }
    }

    public var trackTintColor: UIColor {
        get { _trackTintColor ?? .lightGray }
        set {
            _trackTintColor = newValue
            trackLayer.fillColor = _trackTintColor?.cgColor
            updateKnotsColor()
            setNeedsDisplay()
        }
    }

    public var thumbTintColor: UIColor {
        get { _thumbTintColor ?? .lightGray }
        set {
            _thumbTintColor = newValue
            thumb.backgroundColor = thumbTintColor
            setNeedsDisplay()
        }
    }

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

    public var stepText: String {
        get { _stepText }
        set {
            _stepText = newValue.isEmpty ? "" : newValue
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    public var attributedStepText: NSAttributedString {
        get { _attributedStepText }
        set {
            _attributedStepText = newValue.length > 0 ? newValue : NSAttributedString(string: "")
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    public var selectedStepText: String {
        get { _selectedStepText }
        set {
            _selectedStepText = newValue.isEmpty ? "" : newValue
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    public var attributedSelectedStepText: NSAttributedString {
        get { _attributedSelectedStepText }
        set {
            _attributedSelectedStepText = newValue.length > 0 ? newValue : NSAttributedString(string: "")
            updateValueLabels()
            setNeedsDisplay()
        }
    }

    weak var dataSource: MASliderDataSource?

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        initProperties()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        initProperties()
    }

    public func set(step: Int, animated: Bool) {
        let animations: () -> Void = { self.step = step }
        if animated {
            UIView.animate(withDuration: kAnimationSpeed, delay: 0, options: .curveEaseInOut, animations: animations)
        } else {
            animations()
        }
    }

    // MARK: - Setup

    private func initProperties() {
        trackLayer = CAShapeLayer()
        trackLayer.path = trackBezierPath().cgPath
        trackLayer.fillColor = trackTintColor.cgColor
        layer.addSublayer(trackLayer)

        knotsLayer = CALayer()
        layer.addSublayer(knotsLayer)
        knots = []

        thumb = UIButton(frame: CGRect(x: 0, y: 0, width: kThumbSize, height: kThumbSize))
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
    }

    // MARK: - Geometry

    private func trackRect() -> CGRect {
        CGRect(
            x: kThumbSize / 2,
            y: rectForSlider().size.height / 2 - kTrackWidth / 2,
            width: rectForSlider().size.width - kThumbSize,
            height: kTrackWidth
        )
    }

    private func trackBezierPath() -> UIBezierPath {
        UIBezierPath(rect: trackRect())
    }

    private func rectForSlider() -> CGRect {
        CGRect(x: 0, y: 0, width: bounds.size.width, height: kThumbSize)
    }

    private func rectForLabels() -> CGRect {
        CGRect(x: 0, y: kThumbSize, width: bounds.size.width, height: bounds.size.height - kThumbSize)
    }

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

    private func knot(for index: Int) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let center = centerPosition(for: index)
        let rect = CGRect(x: center.x - kKnotSize / 2, y: center.y - kKnotSize / 2, width: kKnotSize, height: kKnotSize)
        layer.path = UIBezierPath(roundedRect: rect, cornerRadius: kKnotSize / 2).cgPath
        layer.fillColor = trackTintColor.cgColor
        return layer
    }

    // MARK: - Updates
    
    // MARK: - Private backing and subviews

    private var _step: Int = 0
    private var _numberOfSteps: Int = 2
    private var _trackTintColor: UIColor?
    private var _thumbTintColor: UIColor?
    private var _stepText: String = ""
    private var _attributedStepText: NSAttributedString = NSAttributedString(string: "")
    private var _selectedStepText: String = ""
    private var _attributedSelectedStepText: NSAttributedString = NSAttributedString(string: "")

    private var trackLayer: CAShapeLayer!
    private var knotsLayer: CALayer!
    private var knots: [CAShapeLayer] = []
    private var thumb: UIButton!
    private var valueLabels: [UILabel] = []
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!

    private func updateKnotsLayer() {
        knotsLayer.frame = rectForSlider()
    }

    private func updateKnotsColor() {
        for knot in knots {
            knot.fillColor = trackTintColor.cgColor
        }
    }

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

    private func updateTrack() {
        trackLayer.path = trackBezierPath().cgPath
        setNeedsDisplay()
    }

    private func updateThumb(withSelectedStep step: Int) {
        let pos = centerPosition(for: step)
        thumb.center = pos
        setNeedsDisplay()
    }

    private func valueLabel(for index: Int, selected: Bool) -> UILabel {
        let labelsRect = rectForLabels()
        let xPos = labelsRect.size.width / CGFloat(numberOfSteps) * CGFloat(index)
        let center = centerPosition(for: index)
        let label = UILabel(frame: CGRect(x: xPos, y: labelsRect.origin.y, width: 64, height: labelsRect.size.height))
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

        if xCenter - frame.size.width / 2 < 0 { xCenter = frame.size.width / 2 }
        else if xCenter + frame.size.width / 2 > labelsRect.size.width {
            xCenter = labelsRect.size.width - frame.size.width / 2
        }

        label.center = CGPoint(x: xCenter, y: label.center.y + 8)
        addSubview(label)

        return label
    }

    private func updateValueLabels() {
        for label in valueLabels {
            label.removeFromSuperview()
        }

        var newValueLabels: [UILabel] = []
        for i in 0..<numberOfSteps {
            newValueLabels.append(valueLabel(for: i, selected: i == step))
        }
        valueLabels = newValueLabels
    }

    private func cgPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

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

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        // Tap target only; no behavior in original ObjC implementation.
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

import SwiftUI

#Preview {
    MASliderPreview()
        .border(.red)
}
