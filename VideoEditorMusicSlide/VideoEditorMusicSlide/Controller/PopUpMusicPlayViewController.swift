//
//  PopUpMusicPlayViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 25/11/2021.
//

import UIKit
import ALProgressView
import AVFoundation
import MediaPlayer


class PopUpMusicPlayViewController: UIViewController {
    
    var mediaItem: [MPMediaItem] = []
    
    var soundName: String = ""
    
    var player = MPMusicPlayerController.systemMusicPlayer
    
    var audioPlayer = AVAudioPlayer()
    
    var startTime: Double = 0.0
    
    var endTime: Double = 0.0
    
    var durationTime: Double = 0.0
    
    var urlAuido: URL?
    
    @IBOutlet weak var currentTimeLB: UILabel!
    var isPlay: Bool = false

    @IBOutlet weak var processSpinner: UIActivityIndicatorView!
    @IBOutlet weak var startTimeLb: UILabel!
    
    @IBOutlet weak var durationTimeLB: UILabel!
    var customTimer: Timer?
    
    @IBOutlet weak var soundNameLb: UILabel!
    @IBOutlet weak var endTimeLb: UILabel!
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var backgroundImg: UIImageView!
    
    @IBOutlet weak var timeProgressBar: ALProgressBar!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        processSpinner.stopAnimating()
        timeProgressBar.startColor = UIColor(named: "progressbarColor") ?? UIColor.purple
        timeProgressBar.endColor = UIColor(named: "progressbarColor") ?? UIColor.purple
        timeProgressBar.grooveColor = UIColor.gray
 
        if self.mediaItem.count > 0 {
            let mediaCollection = MPMediaItemCollection(items: mediaItem)
            
            customTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            
            self.soundNameLb.text = mediaItem[0].title
            
            player.setQueue(with: mediaCollection)
            
            player.play()
            
            if let playbackDuration: TimeInterval = player.nowPlayingItem?.playbackDuration {
                durationTimeLB.text = getCurrentTime(value: playbackDuration)
                self.endTime = Double(playbackDuration)
                self.durationTime = Double(playbackDuration)
            }
        }else{
            
            if soundName != "" {
                self.soundNameLb.text = soundName
            }
            
            if let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") {
                self.urlAuido =  url
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
                    audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
                    
                    self.endTime = Double(audioPlayer.duration)
                    
                    durationTimeLB.text = getCurrentTime(value: audioPlayer.duration)
                    
                    self.durationTime = Double(audioPlayer.duration)
                    
                    customTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
                    
                    audioPlayer.play()
                    
                    playBtn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    
                } catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    @IBAction func BackBtn(_ sender: Any) {
        
        if self.mediaItem.count > 0 {
            player.stop()
            if endTime > startTime && (endTime - startTime) < durationTime {
                processSpinner.startAnimating()
                startTrimAudio()
            }else{
                dismiss(animated: true, completion: nil)
            }
            
        }
        else{
            audioPlayer.stop()
            if endTime > startTime && (endTime - startTime) < durationTime {
                processSpinner.startAnimating()
                guard let url = self.urlAuido else {return}
                self.trimAudio(sourceURL: url, startTime: self.startTime, stopTime: self.endTime) { urlTrimAudio in
                    DispatchQueue.main.async {
                        self.processSpinner.stopAnimating()
                        let alert = UIAlertController(title: "Trim audio success", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                            UserDefaults.standard.set(urlTrimAudio, forKey: "audioTrimmed")
                            NotificationCenter.default.post(name: NSNotification.Name("doneTrimAudio"), object: nil)
                            self.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                  
                } failure: { error in
                    print(error ?? "")
                }

            }else {
                dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    @IBAction func playMusicAction(_ sender: Any) {
        if isPlay == false {
            isPlay = true
            playBtn.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            customTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            
            if self.mediaItem.count > 0 {
                player.play()
            }
            else{
                audioPlayer.play()
            }
           
        }else {
            isPlay = false
            customTimer?.invalidate()
            customTimer = nil
            playBtn.setImage(UIImage(systemName: "play.fill"), for: .normal)

            if self.mediaItem.count > 0 {
                player.pause()
            }
            else{
                audioPlayer.pause()
            }
            
        }
    }
    
    @IBAction func selectStartTime(_ sender: Any) {
        startTimeLb.text = currentTimeLB.text
        if self.mediaItem.count > 0 {
            startTime = self.player.currentPlaybackTime
        }
        else {
            startTime = self.audioPlayer.currentTime
        }
        endTimeLb.text = durationTimeLB.text
    }
    @IBAction func selectEndTime(_ sender: Any) {
      
        if self.mediaItem.count > 0 {
            endTime = self.player.currentPlaybackTime
        }
        else {
            endTime = self.audioPlayer.currentTime
        }
        endTimeLb.text = currentTimeLB.text
        if endTime - startTime < 10.0 {
            let alert = UIAlertController(title: "Error", message: "Range too short", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
              
            }))
            self.present(alert, animated: true, completion: nil)
        }else{
            endTimeLb.text = currentTimeLB.text
            endTime = durationTime
        }
        
    }
}

extension PopUpMusicPlayViewController {
    
    @objc func updateTimer() {
        
        if self.mediaItem.count > 0 {
            if let playbackDuration: TimeInterval = player.nowPlayingItem?.playbackDuration {
                let progress = player.currentPlaybackTime / playbackDuration
                timeProgressBar.setProgress(Float(progress), animated: true, completion: nil)
            }
        
            currentTimeLB.text = getCurrentTime(value: player.currentPlaybackTime)
        }else {
            
            let progress = self.audioPlayer.currentTime / self.audioPlayer.duration
            timeProgressBar.setProgress(Float(progress), animated: true, completion: nil)
            currentTimeLB.text = getCurrentTime(value: self.audioPlayer.currentTime)
        }
    }
    
    func getCurrentTime(value: TimeInterval) -> String {
        return "\(Int(value / 60)):\(Int(value.truncatingRemainder(dividingBy: 60)) <= 9 ? "0" : "")\(Int(value.truncatingRemainder(dividingBy: 60)))"
    }
    
    func deleteFile(_ filePath:URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
    
    func startTrimAudio(){
        let item: MPMediaItem = mediaItem[0]
        let pathURL: URL? = item.value(forProperty: MPMediaItemPropertyAssetURL) as? URL
        if pathURL == nil {
            print("Picking Error")
            return
        }
        
        // get file extension andmime type
        let str = pathURL!.absoluteString
        let str2 = str.replacingOccurrences( of : "ipod-library://item/item", with: "")
        let arr = str2.components(separatedBy: "?")
        var mimeType = arr[0]
        mimeType = mimeType.replacingOccurrences( of : ".", with: "")
        
        // Export the ipod library as .mp3 file to local directory for remote upload
        let exportSession = AVAssetExportSession(asset: AVAsset(url: pathURL!), presetName: AVAssetExportPresetAppleM4A)
        exportSession?.shouldOptimizeForNetworkUse = true
        exportSession?.outputFileType = .m4a
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("copyMusic.m4a")
        try? FileManager.default.removeItem(at: fileUrl)
        
        exportSession?.outputURL = fileUrl
        exportSession?.exportAsynchronously(completionHandler: { () -> Void in
            
            if exportSession!.status == AVAssetExportSession.Status.completed  {
                DispatchQueue.main.async {
                    self.trimAudio(sourceURL: fileUrl, startTime: self.startTime, stopTime: self.endTime) { urlTrimAudio in
                        DispatchQueue.main.async {
                            self.processSpinner.stopAnimating()
                            let alert = UIAlertController(title: "Trim audio success", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                                UserDefaults.standard.set(urlTrimAudio, forKey: "audioTrimmed")
                                NotificationCenter.default.post(name: NSNotification.Name("doneTrimAudio"), object: nil)
                                self.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    } failure: { error in
                        print(error ?? "")
                    }

                }
            }
            
            if exportSession!.status == .failed {
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "Get URL fail", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                        
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
        }
        )
    }
    
    func trimAudio(sourceURL: URL, startTime: Double, stopTime: Double, success: @escaping ((URL) -> Void), failure: @escaping ((String?) -> Void)) {
        /// Asset
        let asset = AVAsset(url: sourceURL)
//        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
//        print("video length: \(length) seconds")
        
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith:asset)
        
        if compatiblePresets.contains(AVAssetExportPresetMediumQuality) {
            
            //Create Directory path for Save
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            var outputURL = documentDirectory.appendingPathComponent("TrimAudio")
            do {
                try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true, attributes: nil)
                outputURL = outputURL.appendingPathComponent("\(sourceURL.lastPathComponent).m4a")
            }catch let error {
                failure(error.localizedDescription)
            }
            
            //Remove existing file
            self.deleteFile(outputURL)
            
            //export the audio to as per your requirement conversion
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else{return}
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileType.m4a
            
            let range: CMTimeRange = CMTimeRangeFromTimeToTime(start: CMTimeMakeWithSeconds(startTime, preferredTimescale: asset.duration.timescale), end: CMTimeMakeWithSeconds(stopTime, preferredTimescale: asset.duration.timescale))
            exportSession.timeRange = range
            
            exportSession.exportAsynchronously(completionHandler: {
                switch exportSession.status {
                case .completed:
                    success(outputURL)
                    
                case .failed:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                    
                case .cancelled:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                    
                default:
                    if let _error = exportSession.error?.localizedDescription {
                        failure(_error)
                    }
                }
            })
        }
    }
}
