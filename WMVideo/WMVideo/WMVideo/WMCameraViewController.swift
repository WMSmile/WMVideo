//
//  WMCameraViewController.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation
import Photos

enum WMCameraType {
    case video
    case image
    case imageAndVideo
}

class WMCameraViewController: UIViewController {
    
    var url: String?
    // output type
    var type: WMCameraType?
    // input tupe
    var inputType:WMCameraType = WMCameraType.imageAndVideo
    // record video max length
    var videoMaxLength: Double = 10
    
    
    var completeBlock: (String, WMCameraType) -> () = {_,_  in }
    
    let previewImageView = UIImageView()
    var videoPlayer: WMVideoPlayer!
    var controlView: WMCameraControl!
    var manager: WMCameraManger!
    
    let cameraContentView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scale: CGFloat = 16.0 / 9.0
        let contentWidth = UIScreen.main.bounds.size.width
        let contentHeight = min(scale * contentWidth, UIScreen.main.bounds.size.height)
        
        cameraContentView.backgroundColor = UIColor.black
        cameraContentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        cameraContentView.center = self.view.center
        self.view.addSubview(cameraContentView)
        
        manager = WMCameraManger(superView: cameraContentView)
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        manager.startRunning()
        manager.focusAt(cameraContentView.center)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.black
        cameraContentView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(focus(_:))))
        cameraContentView.addGestureRecognizer(UIPinchGestureRecognizer.init(target: self, action: #selector(pinch(_:))))
        
        videoPlayer = WMVideoPlayer(frame: cameraContentView.bounds)
        videoPlayer.isHidden = true
        cameraContentView.addSubview(videoPlayer)
        
        previewImageView.frame = cameraContentView.bounds
        previewImageView.backgroundColor = UIColor.black
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.isHidden = true
        cameraContentView.addSubview(previewImageView)
        
        controlView = WMCameraControl.init(frame: CGRect(x: 0, y: cameraContentView.wm_height - 150, width: self.view.wm_width, height: 150))
        controlView.delegate = self
        controlView.videoLength = self.videoMaxLength
        controlView.inputType = self.inputType
        cameraContentView.addSubview(controlView)
    }
    
    @objc func focus(_ ges: UITapGestureRecognizer) {
        let focusPoint = ges.location(in: cameraContentView)
        manager.focusAt(focusPoint)
    }
    
    @objc func pinch(_ ges: UIPinchGestureRecognizer) {
        guard ges.numberOfTouches == 2 else { return }
        if ges.state == .began {
            manager.repareForZoom()
        }
        manager.zoom(Double(ges.scale))
    }
    
}

extension WMCameraViewController: WMCameraControlDelegate {
    
    func cameraControlDidComplete() {
        dismiss(animated: true) {
            self.completeBlock(self.url!, self.type!)
        }
    }
    
    func cameraControlDidTakePhoto() {
        manager.pickImage { [weak self] (imageUrl) in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.type = .image
                self.url = imageUrl
                self.previewImageView.image = UIImage.init(contentsOfFile: imageUrl)
                self.previewImageView.isHidden = false
                self.controlView.showCompleteAnimation()
            }
        }
    }
    
    func cameraControlBeginTakeVideo() {
        manager.repareForZoom()
        manager.startRecordingVideo()
    }
    
    func cameraControlEndTakeVideo() {
        manager.endRecordingVideo { [weak self] (videoUrl) in
            guard let `self` = self else { return }
            let url = URL.init(fileURLWithPath: videoUrl)
            self.type = .video
            self.url = videoUrl
            self.videoPlayer.isHidden = false
            self.videoPlayer.videoUrl = url
            self.videoPlayer.play()
            self.controlView.showCompleteAnimation()
        }
    }
    
    func cameraControlDidChangeFocus(focus: Double) {
        let sh = Double(UIScreen.main.bounds.size.width) * 0.15
        let zoom = (focus / sh) + 1
        self.manager.zoom(zoom)
    }
    
    func cameraControlDidChangeCamera() {
        manager.changeCamera()
    }
    
    func cameraControlDidClickBack() {
        self.previewImageView.isHidden = true
        self.videoPlayer.isHidden = true
        self.videoPlayer.pause()
    }
    
    func cameraControlDidExit() {
        dismiss(animated: true, completion: nil)
    }
    
}
