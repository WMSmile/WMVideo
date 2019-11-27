//
//  WMVideoTools.swift
//  AVPlayerExample
//
//  Created by wumeng on 2019/11/21.
//  Copyright © 2019 Wu Meng. All rights reserved.
//

import UIKit
import AVFoundation

class WMVideoTools: NSObject {
    /// compressVideo
    ///
    /// - Parameters:
    ///   - presetName: AVAssetExportPresetLowQuality
    ///   - inputURL: input url
    ///   - completionHandler: (URL)->())
    ///
    class func compressVideoWithQuality(presetName: String, inputURL:URL,outputFileType:AVFileType = AVFileType.mp4, completionHandler:@escaping (_ outputUrl: URL?) -> ()) {
        let videoFilePath = NSTemporaryDirectory().appendingFormat("/compressVideo.mp4")
        if FileManager.default.fileExists(atPath: videoFilePath) {
            do {
                try FileManager.default.removeItem(atPath: videoFilePath)
            } catch  {
                fatalError("Unable to delete file: \(error) : \(#function).")
            }
        }
        let savePathUrl =  URL(fileURLWithPath: videoFilePath)
        let sourceAsset = AVURLAsset(url: inputURL, options: nil)
        let assetExport: AVAssetExportSession = AVAssetExportSession(asset: sourceAsset, presetName: presetName)!
        assetExport.outputFileType = outputFileType
        assetExport.outputURL = savePathUrl
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.exportAsynchronously { () -> Void in
            switch assetExport.status {
            case AVAssetExportSessionStatus.completed:
                DispatchQueue.main.async {
                    print("successfully exported at \(savePathUrl.path))")
                    completionHandler(savePathUrl)
                }
            case  AVAssetExportSessionStatus.failed:
                print("failed \(String(describing: assetExport.error))")
                DispatchQueue.main.async {
                    print("successfully exported at \(savePathUrl.path))")
                    completionHandler(nil)
                }
            case AVAssetExportSessionStatus.cancelled:
                print("cancelled \(String(describing: assetExport.error))")
                completionHandler(nil)
            default:
                print("complete")
                completionHandler(nil)
            }
        }
        
    }
    
    
}
