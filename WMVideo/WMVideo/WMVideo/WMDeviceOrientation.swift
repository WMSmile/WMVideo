//
//  WMDeviceOrientation.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit
import CoreMotion

class WMDeviceOrientation {
    
    typealias DevideUpdateClocure = (UIInterfaceOrientation) -> ()
    
    let motionManager = CMMotionManager()
    var closure: DevideUpdateClocure = {_ in }
    let sensitive = 0.77
    
    init() {
        motionManager.deviceMotionUpdateInterval = 0.5
    }
    
    func startUpdates(_ closure: @escaping DevideUpdateClocure) {
        self.closure = closure
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: (OperationQueue.current)!) { (motion, _) in
                self.deviceMotion(motion)
            }
        }
    }
    
    func deviceMotion(_ motion: CMDeviceMotion?) {
        guard let motion = motion else {
            self.closure(.unknown)
            return
        }
        let x = motion.gravity.x
        let y = motion.gravity.y
        
        if y < 0 && fabs(y) > sensitive {
            self.closure(.portrait)
        } else if y > sensitive {
            self.closure(.portraitUpsideDown)
        }
        
        if x < 0 && fabs(x) > sensitive {
            self.closure(.landscapeLeft)
        } else if x > sensitive {
            self.closure(.landscapeRight)
        }
    }
    
}
