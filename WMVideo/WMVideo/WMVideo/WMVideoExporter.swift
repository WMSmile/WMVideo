//
//  WMVideoExporter.swift
//  WMVideo
//
//  Created by wumeng on 2019/11/25.
//  Copyright © 2019 wumeng. All rights reserved.
//

import AVKit

class WMVideoExporter: NSObject {
    
    var composition: AVMutableComposition?
    var videoComposition: AVMutableVideoComposition?
    var outputUrl: String?
    
    override init() {
        super.init()
    }
    
    func exportVideo(completeHandler: @escaping (String) -> ()) {
        guard let videoComposition = videoComposition,
            let composition = composition,
            let outputUrl = outputUrl else { return }
        
        let videoSize = videoComposition.renderSize
        
        guard let assetReader = try? AVAssetReader.init(asset: composition),
            let assetWriter = try? AVAssetWriter.init(outputURL: URL.init(fileURLWithPath: outputUrl), fileType: .mov)else { return }
        
        let compressionProperties = [
            AVVideoProfileLevelKey: AVVideoProfileLevelH264MainAutoLevel,
            AVVideoAllowFrameReorderingKey: false,
            AVVideoExpectedSourceFrameRateKey: 30,
            AVVideoMaxKeyFrameIntervalKey: 30,
            AVVideoAverageBitRateKey: 3 * videoSize.height * videoSize.width
            ] as [String : Any]
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height ,
            AVVideoCompressionPropertiesKey: compressionProperties
            ] as [String : Any]
        
        let assetWriterVideoInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: outputSettings)
        assetWriterVideoInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterVideoInput) {
            assetWriter.add(assetWriterVideoInput)
        }
        
        let audioOutputSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderBitRatePerChannelKey: 28000,
            AVSampleRateKey: 22050,
            AVNumberOfChannelsKey: 1]
        
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioOutputSettings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        if assetWriter.canAdd(assetWriterAudioInput) {
            assetWriter.add(assetWriterAudioInput)
        }
        let readerVideoOutput = AVAssetReaderVideoCompositionOutput.init(videoTracks: composition.tracks(withMediaType: .video), videoSettings: nil)
        readerVideoOutput.videoComposition = videoComposition
        readerVideoOutput.alwaysCopiesSampleData = false
        if assetReader.canAdd(readerVideoOutput) {
            assetReader.add(readerVideoOutput)
        }
        
        let readerAudioOutput = AVAssetReaderAudioMixOutput.init(audioTracks: composition.tracks(withMediaType: .audio), audioSettings: nil)
        readerAudioOutput.alwaysCopiesSampleData = false
        if assetReader.canAdd(readerAudioOutput) {
            assetReader.add(readerAudioOutput)
        }
        
        assetReader.startReading()
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: CMTime.zero)
        
        var videoComplete = false
        var audioComplete = false
        
        let finishBlock = {
            assetWriter.finishWriting {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: {
                    completeHandler(outputUrl)
                })
            }
        }
        
        assetWriterVideoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "videoOutQueue")) {
            while (assetWriterVideoInput.isReadyForMoreMediaData && assetReader.status == .reading) {
                guard let sampleBuffer = readerVideoOutput.copyNextSampleBuffer() else {
                    assetWriterVideoInput.markAsFinished()
                    videoComplete = true
                    if audioComplete {
                        finishBlock()
                    }
                    return
                }
                assetWriterVideoInput.append(sampleBuffer)
            }
        }
        
        assetWriterAudioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "voiceOutQueue")) {
            while (assetWriterAudioInput.isReadyForMoreMediaData && assetReader.status == .reading) {
                guard let sampleBuffer = readerAudioOutput.copyNextSampleBuffer() else {
                    assetWriterAudioInput.markAsFinished()
                    audioComplete = true
                    if videoComplete {
                        finishBlock()
                    }
                    return
                }
                assetWriterAudioInput.append(sampleBuffer)
            }
        }
    }
    
}
