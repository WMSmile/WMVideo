//
//  WMCameraManger.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation

class WMCameraManger: NSObject {
    
    let session = AVCaptureSession()
    
    /**视频输入设备*/
    var videoInput: AVCaptureDeviceInput!
    /**音频输入设备*/
    var audioInput: AVCaptureDeviceInput!
    
    /**预览图层*/
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var assetWriter: AVAssetWriter!
    /**音频写入*/
    var assetWriterAudioInput: AVAssetWriterInput!
    /**视频写入*/
    var assetWriterVideoInput: AVAssetWriterInput!
    
    /**视频输出*/
    var videoDataOut: AVCaptureVideoDataOutput!
    /**音频输出*/
    var audioDataOut: AVCaptureAudioDataOutput!
    /**照片输出*/
    var stillImageOutput: AVCaptureStillImageOutput!
    
    let focusImageView = UIImageView()
    
    var currentUrl: String!
    var showView: UIView!
    
    let videoQueue = DispatchQueue(label: "videoOutQueue")
    let voiceQueue = DispatchQueue(label: "voiceOutQueue")
    
    var isRecording: Bool = false
    var isFocusing: Bool = false
    var videoCurrentZoom: Double = 1.0
    
    let orientation = WMDeviceOrientation()
    var currentOrientation: UIInterfaceOrientation = .portrait
    
    var error: (String) -> () = {_ in }
    
    
    init(superView: UIView) {
        super.init()
        self.showView = superView
        
        setupCamera()
        setupView()
        
        // 开启手机方向监听
        orientation.startUpdates { [weak self] (orientation) in
            guard let `self` = self else { return }
            self.currentOrientation = orientation
        }
    }
    
    func staruRunning() {
        DispatchQueue.global(qos: .default).async {
            self.session.startRunning()
        }
    }
    
    // 初始化相机
    func setupCamera() {
        if (session.canSetSessionPreset(.high)) {
            session.sessionPreset = .high
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = showView.layer.bounds
        showView.layer.addSublayer(previewLayer)
        
        //输入设备
        let devicesVideo = AVCaptureDevice.devices(for: .video)
        let devicesAudio = AVCaptureDevice.devices(for: .audio)
        
        guard let firstVideoDevice = devicesVideo.first,
            let firstAudioDevice = devicesAudio.first,
            let video = try? AVCaptureDeviceInput.init(device: firstVideoDevice),
            let audio = try? AVCaptureDeviceInput.init(device: firstAudioDevice)
            else {
                error("初始化相机失败")
                return
        }
        
        videoInput = video
        audioInput = audio
        
        //添加输入源
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        //视频输出
        videoDataOut = AVCaptureVideoDataOutput()
        videoDataOut.alwaysDiscardsLateVideoFrames = true
        videoDataOut.setSampleBufferDelegate(self, queue: videoQueue)
        if session.canAddOutput(videoDataOut) {
            session.addOutput(videoDataOut)
        }
        
        //音频输出
        audioDataOut = AVCaptureAudioDataOutput()
        audioDataOut.setSampleBufferDelegate(self, queue: voiceQueue)
        if session.canAddOutput(audioDataOut) {
            session.addOutput(audioDataOut)
        }
        
        //图片输出
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }
    }
    
    func setupView() {
        focusImageView.image = UIImage.wm_imageWithName_WMCameraResource(named: "sight_video_focus")
        focusImageView.frame = CGRect(origin: .zero, size: CGSize(width: 60, height: 60))
        focusImageView.isHidden = true
        showView.addSubview(focusImageView)
    }
    
    //每次录制视频都要初始化写入
    func initializeVideoWriter() {
        let rotate = videoRotateWith(self.currentOrientation)
        
        guard let writer = try? AVAssetWriter.init(outputURL: URL.init(fileURLWithPath: currentUrl), fileType: .mov) else {
            error("无法写入视频")
            return
        }
        assetWriter = writer
        
        let scale: CGFloat = 16.0 / 9.0
        let videoWidth: CGFloat = 540
        let videoHeight = min(videoWidth * scale, UIScreen.main.bounds.size.height / UIScreen.main.bounds.size.width * videoWidth)
        
        let compressionProperties = [
            AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel,
            AVVideoAllowFrameReorderingKey: false,
            AVVideoExpectedSourceFrameRateKey: 30,
            AVVideoMaxKeyFrameIntervalKey: 30,
            AVVideoAverageBitRateKey: 3 * videoWidth * videoHeight
            ] as [String : Any]
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: videoHeight,
            AVVideoHeightKey: videoWidth,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: compressionProperties
            ] as [String : Any]
        
        assetWriterVideoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: outputSettings)
        assetWriterVideoInput.transform = CGAffineTransform.init(rotationAngle: CGFloat(rotate))
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        // 音频参数
        let audioOutputSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRatePerChannelKey: 28000,
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1]
        
        assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterAudioInput) {
            assetWriter.add(assetWriterAudioInput)
        }
    }
    

    // 拍照调用方法
    func pickImage(complete: @escaping (String) -> ()) {
        currentUrl = WMCameraFileTools.wm_createFileUrl("jpg")
        let imageOrientation = currentOrientation
        let videoConnection = stillImageOutput.connection(with: .video)
        
        stillImageOutput.captureStillImageAsynchronously(from: videoConnection!, completionHandler: { [weak self] (buffer, error) in
            
            guard let self = self,
                let buffer = buffer,
                let imageData = AVCaptureStillImageOutput
                    .jpegStillImageNSDataRepresentation(buffer),
                let originImage = UIImage.init(data: imageData)
                else {
                    return
            }
            let rotete = self.imageRotateWith(imageOrientation)
            let newImage = WMImageRotate.rotateImage(originImage, withAngle: rotete)
            
            try? newImage.jpegData(compressionQuality: 1)?.write(to: URL.init(fileURLWithPath: self.currentUrl))
            complete(self.currentUrl)
        })
    }
    
    func startRecordingVideo() {
        currentUrl = WMCameraFileTools.wm_createFileUrl("MOV")
        initializeVideoWriter()
        isRecording = true
    }
    
    func endRecordingVideo(complete: @escaping (String) -> ()) {
        if !isRecording { return }
        isRecording = false
        
        self.assetWriter.finishWriting(completionHandler: { [weak self] in
            guard let self = self else { return }
            self.assetWriter = nil
            self.assetWriterVideoInput = nil
            self.assetWriterAudioInput = nil
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: {
                complete(self.currentUrl)
            })
        })
    }
    
    func focusAt(_ point: CGPoint) {
        if isFocusing { return }
        
        self.isFocusing = true
        self.focusImageView.center = point
        self.focusImageView.isHidden = false
        self.focusImageView.alpha = 1
        self.focusImageView.transform = CGAffineTransform.init(scaleX: 1.4, y: 1.4)
        
        lockForConfiguration { [weak self] (devide) in
            guard let self = self else { return }
            let cameraPoint = self.previewLayer.captureDevicePointConverted(fromLayerPoint: point)
            
            if devide.isFocusPointOfInterestSupported {
                devide.focusPointOfInterest = cameraPoint
            }
            if devide.isFocusModeSupported(.continuousAutoFocus) {
                devide.focusMode = .continuousAutoFocus
            }
            
            if devide.isExposurePointOfInterestSupported {
                devide.exposurePointOfInterest = cameraPoint
            }
            if devide.isExposureModeSupported(.continuousAutoExposure) {
                devide.exposureMode = .continuousAutoExposure
            }
            
        }
        
        showFocusImageAnimation()
    }
    
    func showFocusImageAnimation() {
        let animation = CABasicAnimation.init(keyPath: "opacity")
        animation.fromValue = NSNumber.init(value: 1.0)
        animation.toValue = NSNumber.init(value: 0.1)
        animation.autoreverses = true
        animation.duration = 0.3
        animation.repeatCount = 2
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        animation.delegate = self
        focusImageView.layer.add(animation, forKey: nil)
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            guard let self = self else { return }
            self.focusImageView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        }
        
    }
    
    func repareForZoom() {
        videoCurrentZoom = Double(videoInput.device.videoZoomFactor)
    }
    
    func zoom(_ mulriple: Double) {
        let videoMaxZoomFactor = min(5, videoInput.device.activeFormat.videoMaxZoomFactor)
        let toZoomFactory = max(1, Double(videoCurrentZoom) * mulriple)
        let finalZoomFactory = min(toZoomFactory, Double(videoMaxZoomFactor))
        lockForConfiguration { (device) in
            device.videoZoomFactor = CGFloat(finalZoomFactory)
        }
    }
    
    // 切换摄像头
    func changeCamera() {
        if isRecording { return }
        let currentPosition = videoInput.device.position
        var toChangePosition = AVCaptureDevice.Position.front
        if currentPosition == .unspecified || currentPosition == .front {
            toChangePosition = .back
        }
        
        guard let toChangeDevice = getCameraDevice(toChangePosition),
            let toChangeDeviceInput = try? AVCaptureDeviceInput.init(device: toChangeDevice) else {
                error("切换摄像头失败")
                return
        }
        session.beginConfiguration()
        session.removeInput(videoInput)
        if session.canAddInput(toChangeDeviceInput) {
            session.addInput(toChangeDeviceInput)
            videoInput = toChangeDeviceInput
        }
        session.commitConfiguration()
    }
    
    func getCameraDevice(_ position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let cameras = AVCaptureDevice.devices(for: .video)
        return cameras.first(where: { $0.position == position })
    }
    
    func lockForConfiguration(_ closure: (AVCaptureDevice) -> ()) {
        let captureDevice = self.videoInput.device
        do {
            try captureDevice.lockForConfiguration()
            closure(captureDevice)
            captureDevice.unlockForConfiguration()
        } catch {
            
        }
    }
    
    deinit {
        session.stopRunning()
    }
}

extension WMCameraManger {
    
    func imageRotateWith(_ imageOrientation: UIInterfaceOrientation) -> Double {
        let rotate: Double
        switch imageOrientation {
        case .portraitUpsideDown:
            rotate = 180
        case .landscapeLeft:
            rotate = -90
        case .landscapeRight:
            rotate = 90
        default:
            rotate = 0
        }
        return rotate
    }
    
    func videoRotateWith(_ videoOrientation: UIInterfaceOrientation) -> Double {
        let rotate: Double
        switch videoOrientation {
        case .landscapeRight:
            rotate = .pi
        case .landscapeLeft:
            rotate = 0
        case .portraitUpsideDown:
            rotate = .pi * 1.5
        default:
            rotate = .pi * 0.5
        }
        return rotate
    }
}

extension WMCameraManger: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !isRecording {
            return
        }
        autoreleasepool {
            if output == videoDataOut { // 在收到视频信号之后再开始写入，防止视频前几帧黑屏
                if assetWriter.status != .writing {
                    let currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    assetWriter.startWriting()
                    assetWriter.startSession(atSourceTime: currentSampleTime)
                }
                if assetWriterVideoInput.isReadyForMoreMediaData {
                    assetWriterVideoInput.append(sampleBuffer)
                }
            }
            if output == audioDataOut {
                if assetWriterAudioInput.isReadyForMoreMediaData {
                    assetWriterAudioInput.append(sampleBuffer)
                }
            }
        }
    }
    
}

extension WMCameraManger: CAAnimationDelegate {
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        UIView.animate(withDuration: 0.2, animations: {
            self.focusImageView.alpha = 0
        }) { [weak self] _ in
            guard let self = self else { return }
            self.isFocusing = false
            self.focusImageView.isHidden = true
        }
    }
    
}
