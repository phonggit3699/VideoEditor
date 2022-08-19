//
//  TrimViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 08/12/2021.
//

import UIKit
import ABVideoRangeSlider
import PhotosUI
import AVFoundation
import AVKit

class TrimViewController: UIViewController {
    
    typealias UIViewControllerType = PHPickerViewController
    
    @IBOutlet weak var videoRangeSlider: ABVideoRangeSlider!
    
    @IBOutlet weak var VideoFrame: UIView!
    
    @IBOutlet weak var playBtn: UIButton!
    
    var selectedVideoUrl: URL?
    
    var startTime: Float64 = 0.0
    
    var endTime: Float64 = 0.0
    
    var player = AVPlayer()
    
    var isPlay: Bool = false
    
    var position: Float64 = 0.0
    
    var playerLayer : AVPlayerLayer?
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerLayer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // AVPlayer
        
        self.playerLayer = AVPlayerLayer(player: player)
        
        playerLayer!.videoGravity = .resizeAspect
        
        VideoFrame.layer.insertSublayer(playerLayer!, at: 0)
        
        configurePicker(type: .videos)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerLayer?.frame = VideoFrame.bounds
    }
    
    @IBAction func backAction(_ sender: Any) {
        player.pause()
        self.dismiss(animated: true)
    }

    @IBAction func playVideoAction(_ sender: Any) {
        if isPlay {
            isPlay = false
            playBtn.setImage(UIImage(named: "bigPlayBtn"), for: .normal)
            player.pause()
        }else {
            isPlay = true

            let time: CMTime = CMTimeMakeWithSeconds(self.startTime, preferredTimescale: self.player.currentTime().timescale)
            self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                        
            playBtn.setImage(UIImage(named: "bigPauseBtn"), for: .normal)
            player.play()
        }
        
    }
    
    @IBAction func exportTrimVideo(_ sender: Any) {
        guard let url = selectedVideoUrl else {
            return
        }
        
        self.exportTrimedVideo(sourceURL1: url, statTime: Double(self.startTime), endTime: Double(self.endTime))
    }
}

extension TrimViewController {
    
    func configurePicker(type: PHPickerFilter) {
        // PHPicker
        var config = PHPickerConfiguration()
        config.filter = .any(of: [type])
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let controller = PHPickerViewController(configuration: config)
        
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    func configurePickerRangeSlider(videoUrl: URL) {
        videoRangeSlider.setVideoURL(videoURL: URL(fileURLWithPath: videoUrl.path))
        videoRangeSlider.delegate = self
        videoRangeSlider.minSpace = 1.0
 
        videoRangeSlider.setStartPosition(seconds: 0)
        
        let customView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: 60,
                                              height: 30))
        customView.backgroundColor = .black
        customView.alpha = 0.5
        customView.layer.borderColor = UIColor.black.cgColor
        customView.layer.borderWidth = 1.0
        customView.layer.cornerRadius = 8.0
        videoRangeSlider.startTimeView.backgroundView = customView
        videoRangeSlider.startTimeView.marginLeft = 2.0
        videoRangeSlider.startTimeView.marginRight = 2.0
        videoRangeSlider.startTimeView.timeLabel.textColor = .white
                
        let customView2 = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: 60,
                                              height: 30))
        customView2.backgroundColor = .black
        customView2.alpha = 0.5
        customView2.layer.borderColor = UIColor.black.cgColor
        customView2.layer.borderWidth = 1.0
        customView2.layer.cornerRadius = 8.0
        
        videoRangeSlider.endTimeView.backgroundView = customView2
        videoRangeSlider.endTimeView.marginLeft = 2.0
        videoRangeSlider.endTimeView.marginRight = 2.0
        videoRangeSlider.endTimeView.timeLabel.textColor = .white

    }
    
    func configureAVPlayer(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        
        self.player.replaceCurrentItem(with: playerItem)
                
        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: self.player.currentTime().timescale), queue: .main, using: { _ in
            let currentTime: Float64 = Float64(self.player.currentTime().seconds)
            
            if self.player.currentItem?.status == .readyToPlay, let playbackDuration: Double = self.player.currentItem?.duration.seconds {
                let duration: Float64  = Float64(playbackDuration)
                if self.endTime == 0.0 {
                    self.endTime = duration
                }
            }
            
            self.videoRangeSlider.updateProgressIndicator(seconds: currentTime)
        
            if  round(currentTime) == round(self.endTime) {
                self.player.pause()
                self.isPlay = false
                self.playBtn.setImage(UIImage(named: "bigPlayBtn"), for: .normal)
                self.videoRangeSlider.updateProgressIndicator(seconds: self.endTime)
            }
            
        })

    }
    
    func exportTrimedVideo(sourceURL1: URL, statTime: Double, endTime: Double) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("videoTrim.mp4")
        try? FileManager.default.removeItem(at: fileUrl)
        
        let asset = AVAsset(url: sourceURL1 as URL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = fileUrl
        exportSession.outputFileType = .mp4
        
        let timeRange = CMTimeRange(start: CMTime(seconds: startTime, preferredTimescale: asset.duration.timescale),end: CMTime(seconds: endTime, preferredTimescale: asset.duration.timescale))
                
        exportSession.timeRange = timeRange
        
        exportSession.exportAsynchronously{
            switch exportSession.status {
            case .completed:
                self.exportVideo(videoUrl: fileUrl)
            case .failed:
                print("failed \(exportSession.error!)")
                
            case .cancelled:
                print("cancelled \(exportSession.error!)")
                
            default: break
            }
        }
    }
    
    func exportVideo(videoUrl: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges({
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .video, fileURL: videoUrl, options: nil)
                }) { (success, error) in
                    DispatchQueue.main.async {
                        if success {
                            let alert = UIAlertController(title: "Video Saved To Camera Roll", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                                
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    if let error = error {
                        print("error saving \(error)")
                    }
                }
            default:
                print("PhotoLibrary not authorized")
                break
            }
        }
    }
    
    @objc func didPlayToEnd() {
        self.player.pause()
        self.isPlay = false
        self.playBtn.setImage(UIImage(named: "bigPlayBtn"), for: .normal)
    }

}

extension TrimViewController: ABVideoRangeSliderDelegate {
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        DispatchQueue.main.async {
            self.player.pause()
            self.isPlay = false
            self.playBtn.setImage(UIImage(named: "bigPlayBtn"), for: .normal)
            self.startTime = startTime
            self.endTime = endTime
            self.videoRangeSlider.updateProgressIndicator(seconds: startTime)
        }
    }
    
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {
        DispatchQueue.main.async {
            self.position = position
        }
        
        let time: CMTime = CMTimeMakeWithSeconds(position, preferredTimescale: self.player.currentTime().timescale)
        self.player.seek(to: time, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }
    
}

extension TrimViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
   
        guard !results.isEmpty else {
            picker.dismiss(animated: true) {
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
            let itemProvider = result.itemProvider
            
            guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
                  let utType = UTType(typeIdentifier)
            else { continue }
            
            if utType.conforms(to: .movie) {
                self.getVideo(from: itemProvider, typeIdentifier: typeIdentifier, total: results.count)
            }
        }
    }

    private func getVideo(from itemProvider: NSItemProvider, typeIdentifier: String, total: Int) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
            if let error = error {
                print(error.localizedDescription)
            }
            
            guard let url = url else { return }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else { return }
            
            do {
                if FileManager.default.fileExists(atPath: targetURL.path) {
                    try FileManager.default.removeItem(at: targetURL)
                }
                
                try FileManager.default.copyItem(at: url, to: targetURL)
                
                DispatchQueue.main.async {

                    self.selectedVideoUrl = targetURL

                    self.configureAVPlayer(url: targetURL)

                    self.configurePickerRangeSlider(videoUrl: targetURL)

                    NotificationCenter.default.addObserver(self, selector: #selector(self.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

