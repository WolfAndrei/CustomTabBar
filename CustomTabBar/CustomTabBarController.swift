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


public protocol AnimatedTabBarTransitionDelegate: AnimatedTabBarProtocol {
//    func animateTransition(from oldIndex: Int, to newIndex: Int)
}

class AnimatedTabBar: UITabBar, AnimatedTabBarTransitionDelegate {
    
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
        willSet {
            animateTabTo(to: selectedIndex)
        }
    }
    
    var previousSelectedIndex: Int?
    
    //MARK: - Private Var
    
    /// Layers
    private let curveLayer = CAShapeLayer()
    private let circleLayer = CALayer()
    
    /// Dimensions
    private let circleRadius: CGFloat = 20
    private var circleDiameter: CGFloat {
        get {
            return circleRadius * 2
        }
    }
    
    private var tabBarHorizontalInset: CGFloat {
        get {
            return 15.0
        }
    }
    
    private var tabBarTopInset: CGFloat {
        get {
            return 0.0
        }
    }
    
    private var tabBarBottomInset: CGFloat {
        get {
            return 5.0
        }
    }
    
    private var tabBarCornerRadius: CGFloat {
        get {
            return 10.0
        }
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
        updateFrames()
        animateTabTo(to: selectedIndex)
    }
    
    //MARK: - Private methods
    
    private func setupView() {
        backgroundColor = .clear
        curveLayer.strokeColor = UIColor.lightGray.cgColor
        curveLayer.fillColor = UIColor.white.cgColor
        curveLayer.lineWidth = 1.0
        
        circleLayer.backgroundColor = UIColor.systemPink.cgColor
        
        layer.insertSublayer(curveLayer, at: 0)
        curveLayer.insertSublayer(circleLayer, at: 0)
    }
    
    private func updateFrames() {
        curveLayer.frame = bounds
        
        let xCirclePosition = selectedTabCenter - circleRadius
        circleLayer.frame = CGRect(x: xCirclePosition,
                                   y: -circleRadius,
                                   width: circleDiameter,
                                   height: circleDiameter)
        circleLayer.cornerRadius = circleRadius
    }
    
    //MARK: - Animation
    
    func bounceAnimation(to layer: CALayer) {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [1.0, 1.4, 0.9, 1.02, 1.0]
        bounceAnimation.duration = TimeInterval(0.3)
        bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
        layer.add(bounceAnimation, forKey: "bounce_animation")
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
        let path = createCurvePath(for: selectedIndex)
        CATransaction.begin()
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "path")
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
    
    func createCurvePath(for selectedIndex: Int) -> CGPath {
        let path = UIBezierPath()
        
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        let beginningOfNextTab = CGFloat(selectedIndex + 1) * sectionWidth
        
        // top left initial point
        path.move(to: CGPoint(x: tabBarHorizontalInset,
                              y: tabBarCornerRadius * 2)) // start top left
        // top left corner
        path.addArc(withCenter: CGPoint(x: tabBarCornerRadius + tabBarHorizontalInset,
                                        y: tabBarCornerRadius + tabBarTopInset),
                    radius: tabBarCornerRadius,
                    startAngle: CGFloat.pi,
                    endAngle: CGFloat.pi * 3 / 2,
                    clockwise: true)
        //top horizontal line
        path.addLine(to: CGPoint(x: (beginningOfTab + tabBarCornerRadius) + tabBarHorizontalInset,
                                 y: tabBarTopInset))
        
//---
        let smallRadius = tabBarCornerRadius / 2
        let smallDiameter = smallRadius * 2

        //left selected corner
        path.addArc(withCenter: .init(x: (beginningOfTab + smallDiameter) + tabBarHorizontalInset,
                                      y: -smallRadius + tabBarTopInset),
                    radius: smallRadius,
                    startAngle: .pi / 2,
                    endAngle: 0,
                    clockwise: false)
    
        let xCenterOfRightSelectedCornerArc = beginningOfNextTab - (smallDiameter) - tabBarHorizontalInset
        
        let xStartOfCenterArc = beginningOfTab + smallRadius + tabBarCornerRadius + tabBarHorizontalInset
        let xEndOfCenterArc = beginningOfNextTab - (smallRadius + tabBarCornerRadius + tabBarHorizontalInset)
        let centerRadiusArc = (xEndOfCenterArc - xStartOfCenterArc) / 2
        
        // center arc
        path.addArc(withCenter: .init(x: beginningOfTab + sectionWidth / 2,
                                      y: -smallRadius + tabBarTopInset),
                    radius: centerRadiusArc,
                    startAngle: .pi,
                    endAngle: 0,
                    clockwise: true)
        
        // right selected corner
        path.addArc(withCenter: .init(x: xCenterOfRightSelectedCornerArc,
                                      y: -smallRadius + tabBarTopInset),
                    radius: smallRadius,
                    startAngle: .pi,
                    endAngle: .pi / 2,
                    clockwise: false)
//---
        
        //top horizontal line
        path.addLine(to: CGPoint(x: tabBarWidth - tabBarCornerRadius - tabBarHorizontalInset,
                                 y: tabBarTopInset))
        // top right corner
        path.addArc(withCenter: CGPoint(x: tabBarWidth - tabBarCornerRadius - tabBarHorizontalInset,
                                        y: tabBarTopInset + tabBarCornerRadius),
                    radius: tabBarCornerRadius,
                    startAngle: CGFloat.pi * 3 / 2,
                    endAngle: 0,
                    clockwise: true)
        //right vertical line
        path.addLine(to: CGPoint(x: tabBarWidth - tabBarHorizontalInset,
                                 y: tabBarHeight - tabBarCornerRadius - tabBarBottomInset))
        //bottom right corner
        path.addArc(withCenter: CGPoint(x: tabBarWidth - tabBarCornerRadius - tabBarHorizontalInset,
                                        y: tabBarHeight - tabBarCornerRadius - tabBarBottomInset),
                    radius: tabBarCornerRadius,
                    startAngle: 0,
                    endAngle: CGFloat.pi / 2,
                    clockwise: true)
        //bottom horizontal line
        path.addLine(to: CGPoint(x: tabBarCornerRadius + tabBarHorizontalInset,
                                 y: tabBarHeight - tabBarBottomInset))
        
        //bottom left corner
        path.addArc(withCenter: CGPoint(x: tabBarCornerRadius + tabBarHorizontalInset,
                                        y: tabBarHeight - tabBarCornerRadius - tabBarBottomInset),
                    radius: tabBarCornerRadius,
                    startAngle: CGFloat.pi / 2,
                    endAngle: CGFloat.pi,
                    clockwise: true)
        path.close()
        
        return path.cgPath
    }
    
    
}


