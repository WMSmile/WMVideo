//
//  Timer+coustom.swift
//  帮家师傅
//
//  Created by apple on 2017/6/5.
//  Copyright © 2017年 帮家科技. All rights reserved.
//

import Foundation

extension Timer {
    
    ///   创建dispatch timer
    ///
    /// - Parameters:
    ///   - interval: float类型不能小于0.001
    ///   - finishCallback: 回调
   static func wm_createDispatchTimer(_ interval:Float,_ finishCallback:@escaping () -> Void) -> Void {
        
        guard interval>=0.001 else {
            //未满足
            return;
        }
        let deadlineTime = DispatchTime.now() + .microseconds(Int(interval * 1000.0))
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: finishCallback)
    }
    
    /// 创建timer blcok
    ///
    /// - Parameters:
    ///   - timeInterval: 间隔
    ///   - finishCallback: 回调
    ///   - repeats: 重复
    static func wm_scheduledTimer(timeInterval: TimeInterval, repeats: Bool, finishCallback:@escaping (() -> Void)) -> Timer {
        return Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(wm_blockInvoke(timer:)), userInfo: finishCallback, repeats: repeats);
    }
    @objc static func wm_blockInvoke(timer:Timer)->Void
    {
        let block:()->Void =  timer.userInfo as! () -> Void;
        block()
    }
    
}








