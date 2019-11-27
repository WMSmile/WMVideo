//
//  ViewController.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Get stored media files
        print(WMCameraFileTools.wm_getAllfiles())
    }

    @IBAction func recordVideoClick(_ sender: Any) {
        
        let vc = WMCameraViewController()
//        vc.inputType = .video
        vc.videoMaxLength = 20
        vc.completeBlock = { url, type in
            print("url == \(url)")
            //normal
//            if type == .video {
//                let videoUrl = URL.init(fileURLWithPath: url)
//                self.WM_FUNC_PresentPlay(videoUrl: videoUrl)
//            }
            //export
            if type == .video {
                let videoEditer = WMVideoEditor.init(videoUrl: URL.init(fileURLWithPath: url))
                videoEditer.addWaterMark(image: UIImage.init(named: "billbill")!)
                videoEditer.addAudio(audioUrl: Bundle.main.path(forResource: "孤芳自赏", ofType: "mp3")!)
                self.loadingIndicator.startAnimating()
                videoEditer.assetReaderExport(completeHandler: { url in
                    self.loadingIndicator.stopAnimating()
                    // play video
                    let videoUrl = URL.init(fileURLWithPath: url)
                    self.WM_FUNC_PresentPlay(videoUrl: videoUrl)
                   
                })
            }
            //image
            if type == .image {
                //save image to PhotosAlbum
                self.WM_FUNC_saveImage(UIImage.init(contentsOfFile: url)!)
            }
        }
        present(vc, animated: true, completion: nil)
        
    }
    
    
    
    
    
    //MARK:- save image
    func WM_FUNC_saveImage(_ image:UIImage) -> Void {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    //MARK:- play video
    func WM_FUNC_PresentPlay(videoUrl: URL) -> Void {
        
        // Create an AVPlayer, passing it the HTTP Live Streaming URL.
        let player = AVPlayer(url: videoUrl)
        // Create a new AVPlayerViewController and pass it a reference to the player.
        let controller = AVPlayerViewController()
        controller.player = player
        // Modally present the player and call the player's play() method when complete.
        present(controller, animated: true) {
            player.play()
        }
        
    }

    
    
    
    
}


