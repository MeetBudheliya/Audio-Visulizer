//
//  SwiftSiriWaveformView.swift
//  AudioVisulizer
//
//  Created by Meet Budheliya on 08/03/24.
//
//
import UIKit
import AVKit

class WaveformView: UIView {
    
    // Constants
    let primaryLineWidth: CGFloat = 3
    let frequency: CGFloat = 100
    var waveColor: UIColor = .black
    
    var phaseShift:CGFloat = -0.15
    var phase:CGFloat = 0.0
    var pulseValue: CGFloat = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    var timer: Timer?
    var amplitude: CGFloat {
        return bounds.height * 0.1 // Adjust the multiplier as needed
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidChangeFrame), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func viewDidChangeFrame() {
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setAllowsAntialiasing(true)
        
        let maxAmplitude = amplitude
        let normedAmplitude = (1.5 * pulseValue - 0.5)
        let multiplier = min(1.0, (pulseValue / 3.0 * 2.0) + (1.0 / 3.0))
        waveColor.withAlphaComponent(multiplier * waveColor.cgColor.alpha).set()
        
        drawWave(maxAmplitude: maxAmplitude, normedAmplitude: normedAmplitude)
    }
    
    //MARK: - Methods
    func drawWave(maxAmplitude: CGFloat, normedAmplitude: CGFloat) {
        let path = UIBezierPath()
        
        let startPoint = CGPoint(x: 0, y: bounds.height / 2.0)
        path.move(to: startPoint)
        
        let density: CGFloat = 2 // Adjust the density as needed
        
        for x in stride(from: startPoint.x, to: bounds.width, by: density) {
            let scaling = -pow(1 / bounds.width * (x - bounds.width / 2), 2) + 1
            let y = scaling * maxAmplitude * normedAmplitude * sin(2 * .pi * frequency * (x / bounds.width) + self.phase) + bounds.height / 2.0
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.lineWidth = primaryLineWidth
        path.stroke()
        
        self.phase += self.phaseShift
    }
}
