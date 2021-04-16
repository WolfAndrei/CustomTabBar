//
//  CustomTabBarController.swift
//  CustomTabBar
//
//  Created by Andrei Volkau on 13.04.2021.
//

import Foundation
import UIKit

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
    }
    
}

public protocol AnimatedTabBarProtocol where Self: UITabBar {
    ///Currently selected item index
    var selectedIndex: Int { get set }
    ///Previously selected item index
    var previousSelectedIndex: Int? { get set }
    ///Item width
    var sectionWidth: CGFloat { get }
}

public protocol AnimatedTabBarTransitionDelegate: AnimatedTabBarProtocol {
//    func animateTransition(from oldIndex: Int, to newIndex: Int)
}

class AnimatedTabBar: UITabBar, AnimatedTabBarTransitionDelegate, CAAnimationDelegate {
    
    override var selectedItem: UITabBarItem? {
        didSet {
            if let oldValue = oldValue,
               let index = items?.firstIndex(of: oldValue) {
                previousSelectedIndex = index
            } else {
                previousSelectedIndex = nil
            }
        }
        willSet {
            if let newValue = newValue,
               let index = items?.firstIndex(of: newValue) {
                selectedIndex = index
            } else {
                selectedIndex = 0
            }
        }
    }
    
    //MARK: - Protocol Conformance
    
    var selectedIndex: Int = 0 {
        didSet {
            
        }
        willSet {
            animateTabTo(to: selectedIndex)
        }
    }
    var previousSelectedIndex: Int?
    
    var sectionWidth: CGFloat {
        if let count = items?.count {
            return self.bounds.width / CGFloat(count)
        } else {
            return 0
        }
    }
    
    //MARK: - Private Var
    
    
    private let circleRadius: CGFloat = 20
    private var circleDiameter: CGFloat {
        get {
            return circleRadius * 2
        }
    }
    
    private let curveLayer = CAShapeLayer()
    private let circleLayer = CALayer()
    
    private func setupView() {
        backgroundColor = .clear
        curveLayer.strokeColor = UIColor.lightGray.cgColor
        curveLayer.fillColor = UIColor.white.cgColor
        curveLayer.lineWidth = 1.0
        
        circleLayer.backgroundColor = UIColor.systemPink.cgColor
        
        layer.insertSublayer(curveLayer, at: 0)
        curveLayer.insertSublayer(circleLayer, at: 0)
    }
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func draw(_ rect: CGRect) {
        animateTabTo(to: selectedIndex)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        curveLayer.frame = bounds
        
        let x = sectionWidth * CGFloat(selectedIndex) + sectionWidth / 2 - circleRadius
        
        circleLayer.frame = .init(x: x, y: -20, width: circleDiameter, height: circleDiameter)
        circleLayer.cornerRadius = circleRadius
         
        animateTabTo(to: selectedIndex)
    }
    
    //MARK: - Animation
    
    func bounceAnimation(to layer: CALayer) {
        
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [1.0, 1.4, 0.9, 1.02, 1.0]
        bounceAnimation.duration = TimeInterval(0.3)
        bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
        layer.add(bounceAnimation, forKey: "")
    }
    
    func upAnimation(from oldIndex: Int?, to newIndex: Int) {
        
        let oldLayer = subviews[oldIndex ?? 0].layer
        let newLayer = subviews[newIndex].layer
        
        CATransaction.begin()
        let upAnimation = CABasicAnimation(keyPath: "position")
        upAnimation.toValue = [newLayer.frame.midX, -15]
        upAnimation.duration = TimeInterval(0.4)
        
        upAnimation.fillMode = .forwards
        upAnimation.isRemovedOnCompletion = false
        
        let downAnimation = CABasicAnimation(keyPath: "position")
        downAnimation.toValue = [oldLayer.frame.midX, 20]
        downAnimation.duration = TimeInterval(0.3)
        
        downAnimation.fillMode = .forwards
        downAnimation.isRemovedOnCompletion = false
        CATransaction.setCompletionBlock {
            if oldIndex != nil {
                oldLayer.position = .init(x: oldLayer.frame.midX, y: 20)
            }
            newLayer.position = .init(x: newLayer.frame.midX, y: -15)
        }
        newLayer.add(upAnimation, forKey: "")
        
        if  oldIndex != nil {
            oldLayer.add(downAnimation, forKey: "")
        }
        CATransaction.commit()
    }
    
    func animateTabTo(to selectedIndex: Int, completion: (() -> Void)? = nil) {
        let path = createPath(selectedIndex)
        CATransaction.begin()
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "path")
        
//        let animation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "path")
//        if let prevSel = previousSelectedIndex {
//            let basicPath1 = basicPath(prevSel)
//            let newBase = basicPath(selectedIndex)
//            let path = createPath(selectedIndex)
//
//            animation.values = [basicPath1, newBase, path]
//        } else {
//
//            animation.values =  [path]
//        }
//        animation.values =  [path]
        animation.toValue = path
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.duration = 0.3

        CATransaction.setCompletionBlock {
            self.curveLayer.path = path
            completion?()
        }
        
        curveLayer.add(animation, forKey: "tabChangingAnimationKey")
        CATransaction.commit()
        
        if let previousIndex = previousSelectedIndex,
           previousIndex != selectedIndex {
        let animation1 = CAKeyframeAnimation(keyPath: "position")
        animation1.path = circleTransitionPath(from: previousIndex, to: selectedIndex)
        animation1.fillMode = .forwards
        animation1.isRemovedOnCompletion = false
        animation1.duration = 0.3
        
        circleLayer.add(animation1, forKey: "")
        }
           
        if previousSelectedIndex != selectedIndex {
        upAnimation(from: previousSelectedIndex, to: selectedIndex)
        }
    }
    
    func circleTransitionPath(from oldIndex: Int, to newIndex: Int) -> CGPath {
        
        let path = UIBezierPath()
        
        let beginningOfTab = CGFloat(oldIndex + 1) * sectionWidth - sectionWidth * 0.5
        let beginningOfTab2 = CGFloat(newIndex + 1) * sectionWidth - sectionWidth * 0.5

        let yCenterOfTab: CGFloat =  0
        
        let startPoint = CGPoint(x: beginningOfTab, y: yCenterOfTab)
        let endPoint = CGPoint(x: beginningOfTab2, y: yCenterOfTab)
        
        let d = abs(beginningOfTab + beginningOfTab2)
        
        let controlPoint = CGPoint(x: d / 2,
                                   y: bounds.height)
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        
        return path.cgPath
    }
    
    
    func basicPath(_ selectedIndex: Int) -> CGPath {
        let path = UIBezierPath()
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        
        path.move(to: CGPoint(x: 10, y: self.frame.height * 0.4)) // start top left
        
        
        path.addArc(withCenter: CGPoint(x: self.frame.height * 0.2 + 10,
                                        y: 10 + self.frame.height * 0.2),
                    radius: self.frame.height * 0.2,
                    startAngle: CGFloat.pi,
                    endAngle: CGFloat.pi * 3 / 2,
                    clockwise: true)
        
        
        
        path.addLine(to: CGPoint(x: (beginningOfTab + self.frame.height * 0.2) + 10, y: 10)) // the beginning of the trough
        
        
        
        let radius = self.frame.height * 0.1
        let diameter = radius * 2
        
        
        path.addLine(to: .init(x: (beginningOfTab + diameter) + 10 + radius, y: 10))
    
        
        let beginningOfNextTab = CGFloat(selectedIndex + 1) * sectionWidth
        
        let new = beginningOfNextTab - (diameter) - 10
        
        let start = beginningOfTab + radius + self.frame.height * 0.2 + 10
        let end = beginningOfNextTab - (radius + self.frame.height * 0.2 + 10)
        
        let d = (end - start) / 2
        
//        let rad = diameter - 10
        path.addLine(to: .init(x: (beginningOfTab + sectionWidth * 0.5) + d, y: 10))
        path.addLine(to: .init(x: (new) + radius, y: 10))
        path.addLine(to: CGPoint(x: self.frame.width - self.frame.height * 0.2 - 10, y: 10))
        
        path.addArc(withCenter: CGPoint(x: self.frame.width - self.frame.height * 0.2 - 10,
                                        y: 10 + self.frame.height * 0.2),
                    radius: self.frame.height * 0.2,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: 0,
                    clockwise: true)
        

        
        
        path.addLine(to: CGPoint(x: self.frame.width - 10, y: self.frame.height * 0.6))
        
        path.addArc(withCenter: CGPoint(x: self.frame.width - self.frame.height * 0.2 - 10,
                                        y: self.frame.height * 0.6),
                    radius: self.frame.height * 0.2,
                    startAngle: 0,
                    endAngle: CGFloat.pi / 2,
                    clockwise: true)
        
        path.addLine(to: CGPoint(x: self.frame.height * 0.2 + 10, y: self.frame.height * 0.8))
        
        
        path.addArc(withCenter: CGPoint(x: self.frame.height * 0.2 + 10,
                                        y: self.frame.height * 0.6),
                    radius: self.frame.height * 0.2,
                    startAngle: CGFloat.pi / 2,
                    endAngle: CGFloat.pi,
                    clockwise: true)
        path.close()
        
        return path.cgPath
        }
    
    
    
    
    func createPath(_ selectedIndex: Int) -> CGPath {
        let path = UIBezierPath()
        
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        
        path.move(to: CGPoint(x: 10, y: self.frame.height * 0.4)) // start top left
        
        
        path.addArc(withCenter: CGPoint(x: self.frame.height * 0.2 + 10,
                                        y: 10 + self.frame.height * 0.2),
                    radius: self.frame.height * 0.2,
                    startAngle: CGFloat.pi,
                    endAngle: CGFloat.pi * 3 / 2,
                    clockwise: true)
        
        
        
        path.addLine(to: CGPoint(x: (beginningOfTab + self.frame.height * 0.2) + 10, y: 10)) // the beginning of the trough
        
        let radius = self.frame.height * 0.1
        let diameter = radius * 2
        
        path.addArc(withCenter: .init(x: (beginningOfTab + diameter) + 10,
                                      y: -radius + 10),
                    radius: radius,
                    startAngle: .pi / 2,
                    endAngle: 0,
                    clockwise: false)
    
        
        let beginningOfNextTab = CGFloat(selectedIndex + 1) * sectionWidth
        
        let new = beginningOfNextTab - (diameter) - 10
        
        let start = beginningOfTab + radius + self.frame.height * 0.2 + 10
        let end = beginningOfNextTab - (radius + self.frame.height * 0.2 + 10)
        
        let d = (end - start) / 2
        
        path.addArc(withCenter: .init(x: beginningOfTab + sectionWidth * 0.5, y: -radius + 10),
                    radius: d,
                    startAngle: .pi,
                    endAngle: 0,
                    clockwise: true)
        
        path.addArc(withCenter: .init(x: new,
                                      y: -radius + 10),
                    radius: radius,
                    startAngle: .pi,
                    endAngle: .pi / 2,
                    clockwise: false)
    
        path.addLine(to: CGPoint(x: self.frame.width - self.frame.height * 0.2 - 10, y: 10))
        
        path.addArc(withCenter: CGPoint(x: self.frame.width - self.frame.height * 0.2 - 10,
                                        y: 10 + self.frame.height * 0.2),
                    radius: self.frame.height * 0.2,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: 0,
                    clockwise: true)
        
        path.addLine(to: CGPoint(x: self.frame.width - 10, y: self.frame.height * 0.6))
        
        path.addArc(withCenter: CGPoint(x: self.frame.width - self.frame.height * 0.2 - 10,
                                        y: self.frame.height * 0.6),
                    radius: self.frame.height * 0.2,
                    startAngle: 0,
                    endAngle: CGFloat.pi / 2,
                    clockwise: true)
        
        path.addLine(to: CGPoint(x: self.frame.height * 0.2 + 10, y: self.frame.height * 0.8))
        
        
        path.addArc(withCenter: CGPoint(x: self.frame.height * 0.2 + 10,
                                        y: self.frame.height * 0.6),
                    radius: self.frame.height * 0.2,
                    startAngle: CGFloat.pi / 2,
                    endAngle: CGFloat.pi,
                    clockwise: true)
        path.close()
        
        return path.cgPath
    }
    
    
}


