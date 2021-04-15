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
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.firstIndex(of: item)
        {
            let imageView = tabBar.subviews[index] 
            (tabBar as? AnimatedTabBar)?.animateTabTo(to: index)
            (tabBar as? AnimatedTabBar)?.bounceAnimation(to: imageView.layer)
            print((tabBar as? CustomTabBar)?.previousIndex)
            print((tabBar as? CustomTabBar)?.selectedIndex)
        }
    }
}


class CustomTabBar: UITabBar, UITabBarDelegate {
    
    lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = self.createPath(0)
        shapeLayer.strokeColor = UIColor.lightGray.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 1.0
        return shapeLayer
    }()
    
    lazy var circleLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = createCircle(0)
        shapeLayer.fillColor = UIColor.systemPink.cgColor
        shapeLayer.lineWidth = 1.0
        return shapeLayer
    }()
    
    
    override func draw(_ rect: CGRect) {
        self.layer.insertSublayer(shapeLayer, at: 0)
        shapeLayer.insertSublayer(circleLayer, at: 0)
    }
    
    
    var sectionWidth: CGFloat {
        if let count = items?.count {
            return self.bounds.width / CGFloat(count)
        } else {
            return 0
        }
    }
    
    
    override var selectedItem: UITabBarItem? {
        didSet {
            if let oldValue = oldValue,
               let index = items?.firstIndex(of: oldValue) {
                previousIndex = index
            } else {
                previousIndex = nil
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
    
    var selectedIndex: Int = 0
    var previousIndex: Int?
    
    func bounceAnimation(to layer: CALayer) {
        
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [1.0, 1.4, 0.9, 1.02, 1.0]
        bounceAnimation.duration = TimeInterval(0.3)
        bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
        layer.add(bounceAnimation, forKey: "")
    }
    
    
    func animateTabTo(to selectedIndex: Int, completion: (() -> Void)? = nil) {
        let path = createPath(selectedIndex)
        CATransaction.begin()
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "path")
        animation.toValue = path
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.duration = 0.3
        
        CATransaction.setCompletionBlock {
            self.shapeLayer.path = path
            completion?()
        }
        
        shapeLayer.add(animation, forKey: "tabChangingAnimationKey")
        CATransaction.commit()
        
        if let previousIndex = previousIndex,
           previousIndex != selectedIndex {
//        let circlePath = createCircle(selectedIndex)
        CATransaction.begin()
        let animation1 = CAKeyframeAnimation(keyPath: "position")
        animation1.path = circleTransitionPath(from: previousIndex, to: selectedIndex)
//        animation1.toValue = circlePath
        animation1.fillMode = .forwards
        animation1.isRemovedOnCompletion = false
        animation1.duration = 0.2
        
        CATransaction.setCompletionBlock {
//            self.circleLayer.path = circlePath
            completion?()
        }
        
        circleLayer.add(animation1, forKey: "")
        
        CATransaction.commit()
        }
        
    }
    
    func circleTransitionPath(from oldIndex: Int, to newIndex: Int) -> CGPath {
        
        let path = UIBezierPath()
        
        let beginningOfTab = CGFloat(oldIndex) * sectionWidth
        let beginningOfTab2 = CGFloat(newIndex) * sectionWidth
        
        
        let yCenterOfTab = bounds.height / 2 - 25
        
        let startPoint = CGPoint(x: beginningOfTab, y: yCenterOfTab)
        let endPoint = CGPoint(x: beginningOfTab2, y: yCenterOfTab)
        
        let d = abs(beginningOfTab - beginningOfTab2)
        
        let controlPoint = CGPoint(x: d , y: -bounds.height)
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        
        return path.cgPath
    }
    
    
    
    
    
    func createCircle(_ selectedIndex: Int) -> CGPath {
       
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        let xCenterOfTab = beginningOfTab + sectionWidth * 0.5
        let yCenterOfTab = bounds.height / 2
        
        let radius: CGFloat = 20.0
        
        let xStart = xCenterOfTab - radius
        let yStart = yCenterOfTab - 25
        
        let diam = radius * 2
        
        let rect = CGRect(x: xStart, y: yStart, width: diam, height: diam)
        
        let path = UIBezierPath(ovalIn: rect)
        
        return path.cgPath
    }
    
    func createPath(_ selectedIndex: Int) -> CGPath {
        let path = UIBezierPath()
        
        let height: CGFloat = bounds.height / 2
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        
        path.move(to: CGPoint(x: 0, y: 0)) // start top left
        path.addLine(to: CGPoint(x: (beginningOfTab + sectionWidth * 0.1), y: 0)) // the beginning of the trough
        
        path.addQuadCurve(to: CGPoint(x: beginningOfTab + sectionWidth * 0.3, y: -height * 0.1),
                          controlPoint: CGPoint(x: beginningOfTab + (sectionWidth * 0.3), y: 0))
        
        path.addCurve(to: CGPoint(x: beginningOfTab + sectionWidth * 0.7, y: -height * 0.1),
                      controlPoint1: CGPoint(x: beginningOfTab + sectionWidth * 0.4, y: -height * 0.6),
                      controlPoint2: CGPoint(x: (beginningOfTab + sectionWidth * 0.6), y: -height * 0.6))
        
        path.addQuadCurve(to: CGPoint(x: beginningOfTab + sectionWidth * 0.9, y: 0),
                          controlPoint: CGPoint(x: beginningOfTab + (sectionWidth * 0.7), y: 0))
        
        path.addLine(to: CGPoint(x: self.frame.width, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height))
        path.addLine(to: CGPoint(x: 0, y: self.frame.height))
        path.close()
        
        return path.cgPath
    }
    
}


public protocol AnimatedTabBarProtocol where Self: UITabBar {
    ///Currently selected item index
    var selectedIndex: Int { get set }
    ///Previously selected item index
    var previousSelectedIndex: Int? { get set }
    ///Item width
    var sectionWidth: CGFloat { get }
    ///Added sublayers for animation
    var sublayers: [CALayer] { get set }
}

public protocol AnimatedTabBarTransitionDelegate: AnimatedTabBarProtocol {
    func animateTransition(from oldIndex: Int, to newIndex: Int)
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
    
    var selectedIndex: Int = 0
    var previousSelectedIndex: Int?
    
    var sectionWidth: CGFloat {
        if let count = items?.count {
            return self.bounds.width / CGFloat(count)
        } else {
            return 0
        }
    }
    
    var sublayers: [CALayer] = []
    
    func createCurveLayer() {
        let curveLayer = CAShapeLayer()
        
        curveLayer.path = self.createPath(0)
        curveLayer.strokeColor = UIColor.lightGray.cgColor
        curveLayer.fillColor = UIColor.white.cgColor
        curveLayer.lineWidth = 1.0
        bounceAnimation(to: curveLayer)
        sublayers.append(curveLayer)
    }
    
    func createCircleLayer() {
        let circleLayer = CAShapeLayer()
        circleLayer.path = createCircle(0)
        circleLayer.fillColor = UIColor.systemPink.cgColor
        circleLayer.lineWidth = 1.0
        sublayers.append(circleLayer)
    }
    
    override func draw(_ rect: CGRect) {
        createCurveLayer()
        createCircleLayer()
        
        let curveLayer = self.sublayers[0]
        let circleLayer = self.sublayers[1]
        layer.insertSublayer(curveLayer, at: 0)
        curveLayer.insertSublayer(circleLayer, at: 0)
    }
    
    
    func animateTransition(from oldIndex: Int, to newIndex: Int) {
        //
    }
    
    
    func bounceAnimation(to layer: CALayer) {
        
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        bounceAnimation.values = [1.0, 1.4, 0.9, 1.02, 1.0]
        bounceAnimation.duration = TimeInterval(0.3)
        bounceAnimation.calculationMode = CAAnimationCalculationMode.cubic
        layer.add(bounceAnimation, forKey: "")
    }
    
    
    func animateTabTo(to selectedIndex: Int, completion: (() -> Void)? = nil) {
        
        let curveLayer = self.sublayers[0] as! CAShapeLayer
        let circleLayer = self.sublayers[1] as! CAShapeLayer
        
        let path = createPath(selectedIndex)
        CATransaction.begin()
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "path")
        animation.toValue = path
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.duration = 0.3
        
        CATransaction.setCompletionBlock {
            curveLayer.path = path
            completion?()
        }
        
        curveLayer.add(animation, forKey: "tabChangingAnimationKey")
        CATransaction.commit()
        
        if let previousIndex = previousSelectedIndex,
           previousIndex != selectedIndex {
//        let circlePath = createCircle(selectedIndex)
        CATransaction.begin()
        let animation1 = CAKeyframeAnimation(keyPath: "position")
        animation1.path = circleTransitionPath(from: previousIndex, to: selectedIndex)
//        animation1.toValue = circlePath
        animation1.fillMode = .forwards
        animation1.isRemovedOnCompletion = false
        animation1.duration = 0.2
        
        CATransaction.setCompletionBlock {
//            self.circleLayer.path = circlePath
            completion?()
        }
        
        circleLayer.add(animation1, forKey: "")
        
        CATransaction.commit()
        }
        
    }
    
    func circleTransitionPath(from oldIndex: Int, to newIndex: Int) -> CGPath {
        
        let path = UIBezierPath()
        
        let beginningOfTab = CGFloat(oldIndex) * sectionWidth
        let beginningOfTab2 = CGFloat(newIndex) * sectionWidth
        
        
        let yCenterOfTab = bounds.height / 2 - 25
        
        let startPoint = CGPoint(x: beginningOfTab, y: yCenterOfTab)
        let endPoint = CGPoint(x: beginningOfTab2, y: yCenterOfTab)
        
        let d = abs(beginningOfTab - beginningOfTab2)
        
        let controlPoint = CGPoint(x: d , y: -bounds.height)
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        
        return path.cgPath
    }
    
    
    
    
    
    func createCircle(_ selectedIndex: Int) -> CGPath {
       
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        let xCenterOfTab = beginningOfTab + sectionWidth * 0.5
        let yCenterOfTab = bounds.height / 2
        
        let radius: CGFloat = 20.0
        
        let xStart = xCenterOfTab - radius
        let yStart = yCenterOfTab - 25
        
        let diam = radius * 2
        
        let rect = CGRect(x: xStart, y: yStart, width: diam, height: diam)
        
        let path = UIBezierPath(ovalIn: rect)
        
        return path.cgPath
    }
    
    func createPath(_ selectedIndex: Int) -> CGPath {
        let path = UIBezierPath()
        
        let height: CGFloat = bounds.height / 2
        let beginningOfTab = CGFloat(selectedIndex) * sectionWidth
        
        path.move(to: CGPoint(x: 0, y: 0)) // start top left
        path.addLine(to: CGPoint(x: (beginningOfTab + sectionWidth * 0.1), y: 0)) // the beginning of the trough
        
        path.addQuadCurve(to: CGPoint(x: beginningOfTab + sectionWidth * 0.3, y: -height * 0.1),
                          controlPoint: CGPoint(x: beginningOfTab + (sectionWidth * 0.3), y: 0))
        
        path.addCurve(to: CGPoint(x: beginningOfTab + sectionWidth * 0.7, y: -height * 0.1),
                      controlPoint1: CGPoint(x: beginningOfTab + sectionWidth * 0.4, y: -height * 0.6),
                      controlPoint2: CGPoint(x: (beginningOfTab + sectionWidth * 0.6), y: -height * 0.6))
        
        path.addQuadCurve(to: CGPoint(x: beginningOfTab + sectionWidth * 0.9, y: 0),
                          controlPoint: CGPoint(x: beginningOfTab + (sectionWidth * 0.7), y: 0))
        
        path.addLine(to: CGPoint(x: self.frame.width, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height))
        path.addLine(to: CGPoint(x: 0, y: self.frame.height))
        path.close()
        
        return path.cgPath
    }
    
    
}


