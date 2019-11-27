//
//  UIView+Extension.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit

extension UIView {
    
    func wm_removeAllSubviews() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }
    
    public var wm_x: CGFloat{
        get{
            return self.frame.origin.x
        }
        set{
            var frame = self.frame
            frame.origin.x = newValue
            self.frame = frame
        }
    }
    
    public var wm_y: CGFloat{
        get {
            return self.frame.origin.y
        }
        set {
            var frame = self.frame
            frame.origin.y = newValue
            self.frame = frame
        }
    }
    
    public var wm_width: CGFloat{
        get {
            return self.frame.size.width
        }
        set{
            var frame = self.frame
            frame.size.width = newValue
            self.frame = frame
        }
    }
    
    public var wm_height: CGFloat{
        get {
            return self.frame.size.height
        }
        set{
            var frame = self.frame
            frame.size.height = newValue
            self.frame = frame
        }
    }
    
    public var wm_right: CGFloat{
        get {
            return self.frame.origin.x + self.frame.size.width
        }
    }
    
    public var wm_bottom: CGFloat{
        get {
            return self.frame.origin.y+self.frame.size.height
        }
    }
    
    public var wm_rightX: CGFloat{
        get{
            return self.wm_x + self.wm_width
        }
        set{
            var r = self.frame
            r.origin.x = newValue - frame.size.width
            self.frame = r
        }
    }
    
    public var wm_bottomY: CGFloat{
        get{
            return self.wm_y + self.wm_height
        }
        set{
            var r = self.frame
            r.origin.y = newValue - frame.size.height
            self.frame = r
        }
    }
    
    public var wm_centerX : CGFloat{
        get{
            return self.center.x
        }
        set{
            self.center = CGPoint(x: newValue, y: self.center.y)
        }
    }
    
    public var wm_centerY : CGFloat{
        get{
            return self.center.y
        }
        set{
            self.center = CGPoint(x: self.center.x, y: newValue)
        }
    }
    
    public var wm_origin: CGPoint{
        get{
            return self.frame.origin
        }
        set{
            self.wm_x = newValue.x
            self.wm_y = newValue.y
        }
    }
    
    public var wm_size: CGSize{
        get{
            return self.frame.size
        }
        set{
            self.wm_width = newValue.width
            self.wm_height = newValue.height
        }
    }
    
}

