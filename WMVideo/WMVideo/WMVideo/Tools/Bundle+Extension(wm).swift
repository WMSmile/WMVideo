//
//  Bundle+Extension.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit

extension Bundle{
    
    /// get bundle
    ///
    /// - Returns: Bundle
    class func wm_videoBundle() -> Bundle{
        var bundle:Bundle = Bundle.init(for: WMCameraViewController.self)
        let url:URL = bundle.url(forResource: "WMCameraResource", withExtension: "bundle")!
        bundle = Bundle.init(url: url)!
        return bundle
    }
    
    
}
