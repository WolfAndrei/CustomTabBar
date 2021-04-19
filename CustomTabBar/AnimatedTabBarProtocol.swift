//
//  AnimatedTabBarProtocol.swift
//  CustomTabBar
//
//  Created by Andrei Volkau on 19.04.2021.
//

import UIKit

public protocol AnimatedTabBarProtocol where Self: UITabBar {
    ///Currently selected item index
    var selectedIndex: Int { get set }
    ///Previously selected item index
    var previousSelectedIndex: Int? { get set }
    ///Item width
    var sectionWidth: CGFloat { get }
    ///Center of tab
    var selectedTabCenter: CGFloat { get }
    ///Tabbar height
    var tabBarHeight: CGFloat { get }
    ///Tabbar width
    var tabBarWidth: CGFloat { get }
}

extension AnimatedTabBarProtocol {
    
    var sectionWidth: CGFloat {
        if let count = items?.count {
            return self.bounds.width / CGFloat(count)
        } else {
            return 0
        }
    }
    
    var selectedTabCenter: CGFloat {
        get {
            sectionWidth * CGFloat(selectedIndex) + sectionWidth / 2
        }
    }
    
    var tabBarHeight: CGFloat {
        get {
            self.frame.height
        }
    }
    
    var tabBarWidth: CGFloat {
        get {
            self.frame.width
        }
    }
}
