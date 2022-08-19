//
//  EditorViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 29/11/2021.
//

import UIKit
import ALProgressView
import PhotosUI
import MetalPetal
import MTTransitions
import Photos
import AVFoundation
import AVKit
import MediaPlayer

class EditorViewController: UIViewController {
    
    typealias UIViewControllerType = PHPickerViewController
    
    var listImagePicked: [UIImage] = []
    
    var tabName: [String] = [""]
    
    var settings: [String] = ["setting1", "setting2", "setting3"]
    
    var tab: String = ""
    
    var filterImg: [UIImage] = [UIImage(systemName: "xmark.circle")!]
    
    var stickers: [UIImage] = [UIImage(systemName: "xmark.circle")!]
    
    var sounds: [String] = ["", "", "At the Submit", "Flies Away", "Frozen Lake", "NightLife", "ITE They Parted", "Life Is Jorney"]
    
    var effects: [MTTransition.Effect] = MTTransition.Effect.allCases
    
    var filterNames = ["None" ,"Luminance", "Chrome","Fade","Instant","Noir","Process","Tonal","Transfer","SepiaTone","ColorClamp","ColorMonochrome" ,"ColorPosterize", "MedianFilter", "NoiseReduction"]
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    var isEnd: Bool = false
    
    var fileURL: URL?
    
    var player = AVPlayer()
    
    var customTimer: Timer?
    
    private var movieMaker: MTMovieMaker?
    
    var fromImage: MTIImage!
    
    var toImage: MTIImage!
    
    var pickedEffects: [MTTransition.Effect] = []
    
    var effect: MTTransition.Effect = .none
    
    var isPlay: Bool = false
    
    var isViewEditor: Bool = false
    
    private let videoTransition = MTVideoTransition()
    
    private var exporter: MTVideoExporter?
    
    var indexImageWillAddEffect: Int = 0
    
    var selectMusic: String = ""
    
    var playerLayer : AVPlayerLayer?
    
    var isEditVideo: Bool = false
    
    var assetCollection: PHAssetCollection?
    
    var selectPosition: Int = -1
    
    var selectSticker: UIImage?
    
    var thumImg: UIImage?
    
    var selectFilter: String = ""
    
    @IBOutlet weak var processSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var nextBtn: UIButton!
    
    @IBOutlet weak var tabEditorCollection: UICollectionView!
    
    @IBOutlet weak var previewEffectView: MTIImageView!
    
    @IBOutlet weak var leftNavButton: UIButton!
    
    @IBOutlet weak var labelSpinner: UILabel!
    
    @IBOutlet weak var navLabel: UILabel!
    
    @IBOutlet weak var stackButtonSelectMedia: UIStackView!
    @IBOutlet weak var textInput: UITextField!
    
    @IBOutlet weak var VideoFrame: UIView!
    
    @IBOutlet weak var timeLineVideo: ALProgressBar!
    
    @IBOutlet weak var currentTimeLB: UILabel!
    
    @IBOutlet weak var durationTimeLB: UILabel!
    
    @IBOutlet weak var playBtn: UIButton!
    
    @IBOutlet weak var editConllection: UICollectionView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBAction func BackBtn(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("backToCam"), object: nil)
        player.pause()
        filterImg.removeAll()
        stickers.removeAll()
        pickedEffects.removeAll()
        listImagePicked.removeAll()
        effects.removeAll()
        assetCollection = nil
        playerLayer = nil
        selectSticker = nil
        thumImg = nil
        movieMaker = nil
        filterNames.removeAll()
        sounds.removeAll()
        fileURL =  nil
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        
        VideoFrame.addGestureRecognizer(tap)
        
        // AVPlayer
        self.playerLayer = AVPlayerLayer(player: player)
        
        playerLayer!.videoGravity = .resizeAspect
        
        VideoFrame.layer.insertSublayer(playerLayer!, at: 0)
        
        timeLineVideo.startColor = UIColor(named: "progressbarColor") ?? UIColor.purple
        timeLineVideo.endColor = UIColor(named: "progressbarColor") ?? UIColor.purple
        timeLineVideo.grooveColor = UIColor.gray
        hideUI()
        
        textInput.delegate = self
        editConllection.delegate = self
        editConllection.dataSource = self
        
        tabEditorCollection.delegate = self
        tabEditorCollection.dataSource = self
        
        editConllection.register(UINib(nibName: FilterEffectCLVCell.className, bundle: nil), forCellWithReuseIdentifier: FilterEffectCLVCell.className)
        
        tabEditorCollection.register(UINib(nibName: TabMusicCLVCell.className, bundle: nil), forCellWithReuseIdentifier: TabMusicCLVCell.className)
        
        textInput.isHidden = true
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.createAblum()
            }
        }
        
        loadImageFromStorage()
        
        if let url = self.fileURL {
            self.processSpinner.startAnimating()
            self.setupForEditVideo(url: url)
            
            DispatchQueue.main.async {
                if let thumImg = self.generateThumbnail(path: url) {
                    CIFilterNames.indices.forEach {[weak self] index in
                        let image = self?.convertImageToBW(filterName: CIFilterNames[index], image: thumImg)
                        self?.filterImg.append(image!)
                    }
                    DispatchQueue.main.async {
                        self.processSpinner.stopAnimating()
                        self.editConllection.reloadData()
                    }
                }
            }
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(doneTrimAudio), name: NSNotification.Name(rawValue: "doneTrimAudio"), object: nil)
    }
    
    @objc func doneTrimAudio() {
        if listImagePicked.count > 0 && listImagePicked.count - 1 == pickedEffects.count {
            if let audioTrimmedURL: URL = UserDefaults.standard.url(forKey: "audioTrimmed"){
                self.createVideo(audioUrl: audioTrimmedURL)
                self.indexImageWillAddEffect = 0
                UserDefaults.standard.set(nil, forKey: "audioTrimmed")
            }
            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerLayer?.frame = VideoFrame.bounds
    }
    
    
    @IBAction func nextStepAction(_ sender: Any) {
        
        if selectFilter != "" {
            self.player.pause()
            playBtn.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
            leftNavButton.isEnabled = false
            self.nextBtn.isHidden = true
            guard let fileURL = self.fileURL else {
                print("url nil")
                return
                
            }
            addfiltertoVideo(strfiltername: selectFilter, strUrl: fileURL) { newUrl, error in
                if let err = error {
                    print(err)
                    return
                }
                
                guard let fileURL = newUrl else { return }
                
                self.fileURL = newUrl
                let playerItem = AVPlayerItem(url: fileURL)
                self.player.replaceCurrentItem(with: playerItem)
                self.updateTime()
                self.player.play()
                DispatchQueue.main.async {
                    self.spinner.isHidden = true
                    self.spinner.stopAnimating()
                    self.leftNavButton.isEnabled = true
                    self.textInput.isHidden = true
                    self.textInput.text = ""
                    self.selectFilter = ""
                }
            }
            return
        }
        
        // function for add sticker or text
        if selectPosition > -1 {
            self.player.pause()
            playBtn.isHidden = true
            spinner.isHidden = false
            spinner.startAnimating()
            leftNavButton.isEnabled = false
            self.nextBtn.isHidden = true
            guard let fileURL = self.fileURL else {
                print("url nil")
                return
                
            }
            
            addStickerorTexttoVideo(videoUrl: fileURL, watermarkText: self.textInput.text ?? "", stickerImg: self.selectSticker ?? nil, position: selectPosition) { newUrl, error in
                if let err = error {
                    print(err)
                    return
                }
                
                guard let fileURL = newUrl else { return }
                
                self.fileURL = newUrl
                let playerItem = AVPlayerItem(url: fileURL)
                self.player.replaceCurrentItem(with: playerItem)
                self.updateTime()
                self.player.play()
                DispatchQueue.main.async {
                    self.textInput.text = ""
                    self.selectSticker = nil
                    self.spinner.isHidden = true
                    self.spinner.stopAnimating()
                    self.leftNavButton.isEnabled = true
                    self.textInput.isHidden = true
                    self.textInput.text = ""
                    self.selectPosition = -1
                }
            }
            return
        }
        
        // add music
        if tab == "Musics" {
            var audioUrl: URL?
            
            if selectMusic != "" {
                audioUrl = Bundle.main.url(forResource: selectMusic, withExtension: "mp3")
            }
            else {
                audioUrl = nil
            }
            
            self.createVideo(audioUrl: audioUrl)
            self.indexImageWillAddEffect = 0
            return
        }
        
        // add effect
        if tab == "Effects" {
            if listImagePicked.count > 0 {
                
                if  indexImageWillAddEffect == listImagePicked.count - 2 {
                    pickedEffects.append(effect)
                    nextBtn.setTitle("ADD MUSIC", for: .normal)
                    tab = "Musics"
                    tabName = ["Musics"]
                    editConllection.reloadData()
                    tabEditorCollection.reloadData()
                }
                
                if indexImageWillAddEffect <  listImagePicked.count - 2 {
                    indexImageWillAddEffect += 1
                    configureSubviews()
                    pickedEffects.append(effect)
                    nextBtn.setTitle("ADD EFFECT \(indexImageWillAddEffect)/\(listImagePicked.count - 1)", for: .normal)
                }
            }
            return
        }
        
    }
    
    @IBAction func exportVideo(_ sender: Any) {
        
        if isViewEditor {
            exportVideo()
        }
        else {
            let cameraVC = mainStoryboard.instantiateViewController(withIdentifier: "CameraVC")
            
            present(cameraVC, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func selectImages(_ sender: Any) {
        self.tab = "Effects"
        tabName = ["Effects"]
        tabEditorCollection.reloadData()
        editConllection.reloadData()
        configurePicker(type: .images)
    }
    
    
    @IBAction func selectVideo(_ sender: Any) {
        self.tab = "Filters"
        editConllection.reloadData()
        configurePicker(type: .videos)
    }
    
    @IBAction func playMusicAction(_ sender: Any) {
        
        if isEnd == true {
            isPlay = true
            isEnd = false
            playBtn.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.playBtn.isHidden = true
            }
            player.seek(to: .zero)
            player.play()
        }else if isPlay == false {
            isPlay = true
            playBtn.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.playBtn.isHidden = true
            }
            player.play()
        }
        else {
            isPlay = false
            playBtn.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.playBtn.isHidden = true
            }
            player.pause()
        }
    }
}

/// Extension
extension EditorViewController {
    
    func configureSubviews() {
        
        let fImage: CGImage = listImagePicked[indexImageWillAddEffect].cgImage!
        
        let tImage: CGImage = listImagePicked[indexImageWillAddEffect + 1].cgImage!
        
        
        fromImage =  MTIImage(cgImage: fImage, options: [.SRGB: false]).oriented(.downMirrored)
        
        toImage =  MTIImage(cgImage: tImage, options: [.SRGB: false]).oriented(.downMirrored)
        
        
        
        previewEffectView.image = toImage.oriented(.downMirrored)
    }
    
    func hideUI() {
        self.processSpinner.stopAnimating()
        nextBtn.isHidden = true
        previewEffectView.isHidden = true
        editConllection.isHidden = true
        tabEditorCollection.isHidden = true
        VideoFrame.isHidden = true
        currentTimeLB.isHidden = true
        durationTimeLB.isHidden = true
        timeLineVideo.isHidden = true
        playBtn.isHidden = true
        
    }
    
    func showUI() {
        nextBtn.isHidden = false
        if listImagePicked.count > 0 {
            nextBtn.setTitle("ADD EFFECT 0/\(listImagePicked.count - 1)", for: .normal)
        }
        previewEffectView.isHidden = false
        editConllection.isHidden = false
        tabEditorCollection.isHidden = false
        stackButtonSelectMedia.isHidden = true
        navLabel.text = "SLIDESHOW"
        leftNavButton.setImage(UIImage(named: "exportBtn"), for: .normal)
        isViewEditor = true
        leftNavButton.isEnabled = false
        
    }
    
    func showVideoEditorDone() {
        nextBtn.isHidden = true
        previewEffectView.isHidden = true
        editConllection.isHidden = true
        tabEditorCollection.isHidden = true
        VideoFrame.isHidden = false
        currentTimeLB.isHidden = false
        durationTimeLB.isHidden = false
        timeLineVideo.isHidden = false
        spinner.startAnimating()
    }
    
    func configurePicker(type: PHPickerFilter) {
        // PHPicker
        var config = PHPickerConfiguration()
        config.filter = type == .images ? .images : .videos
        config.selectionLimit = type == .images ? 0 : 1
        config.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: config)
        
        controller.delegate = self
        
        if type == .videos {
            self.isEditVideo = true
        }else {
            self.isEditVideo = false
        }
        
        present(controller, animated: true, completion: nil)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        playBtn.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.playBtn.isHidden = true
        }
    }
    
    func updateTime() {
        self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0, preferredTimescale: 1), queue: .main, using: { _ in
            self.currentTimeLB.text = self.formatTime(seconds: self.player.currentTime().seconds)
            if self.player.currentItem?.status == .readyToPlay, let playbackDuration: Double = self.player.currentItem?.duration.seconds{
                self.durationTimeLB.text = self.formatTime(seconds: playbackDuration)
                
                let progress = self.player.currentTime().seconds / playbackDuration
                
                self.timeLineVideo.setProgress(Float(progress), animated: false, completion: nil)
                if self.player.currentTime().seconds == playbackDuration {
                    self.isPlay = false
                    self.playBtn.setBackgroundImage(UIImage(systemName: "play.fill"), for: .normal)
                    self.isEnd = true
                }
            }
        })
    }
    
    func formatTime(seconds: Double) -> String {
        let result = timeDivider(seconds: seconds)
        let hoursString = "\(result.hours)"
        var minutesString = "\(result.minutes)"
        var secondsString = "\(result.seconds)"
        
        if minutesString.count == 1 {
            minutesString = "0\(result.minutes)"
        }
        if secondsString.count == 1 {
            secondsString = "0\(result.seconds)"
        }
        
        var time = "\(hoursString):"
        if result.hours >= 1 {
            time.append("\(minutesString):\(secondsString)")
        }
        else {
            time = "\(minutesString):\(secondsString)"
        }
        return time
    }
    
    func timeDivider(seconds: Double) -> (hours: Int, minutes: Int, seconds: Int) {
        guard !(seconds.isNaN || seconds.isInfinite) else {
            return (0,0,0)
        }
        let secs: Int = Int(seconds)
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        return (hours, minutes, seconds)
    }
    
    private func registerNotifications() {
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handlePlayToEndTime),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    @objc private func handlePlayToEndTime() {
        player.seek(to: .zero)
        player.play()
    }
    
    func settingUIForEditVideo() {
        tabName = ["Filters", "Stickers", "Texts"]
        tab = "Filters"
        navLabel.text = "EDITOR VIDEO"
        nextBtn.isHidden = true
        previewEffectView.isHidden = true
        editConllection.isHidden = false
        tabEditorCollection.isHidden = false
        stackButtonSelectMedia.isHidden = true
        VideoFrame.isHidden = false
        currentTimeLB.isHidden = false
        durationTimeLB.isHidden = false
        leftNavButton.setImage(UIImage(named: "exportBtn"), for: .normal)
        timeLineVideo.isHidden = false
        isViewEditor = true
        tabEditorCollection.reloadData()
        editConllection.reloadData()
        UpdateUIVideoFrame()
        leftNavButton.isEnabled = false
    }
    
    
    func UpdateUIVideoFrame() {
        self.leftNavButton.isEnabled = true
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
        self.labelSpinner.isHidden = true
        isPlay = true
        
        playBtn.isHidden = false
        
        
        playBtn.setBackgroundImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.playBtn.isHidden = true
        }
        
    }
    
    func loadImageFromStorage(){
        var isNil = false
        var index = 1
        while isNil == false {
            if let imageUrl = Bundle.main.url(forResource: "sticker\(index)", withExtension: "png") {
                self.stickers.append(UIImage(contentsOfFile: imageUrl.path)!)
                index += 1
            }else{
                isNil = true
            }
        }
    }
    
    func setupForEditVideo(url: URL) {
        self.fileURL = url
        let playerItem = AVPlayerItem(url: url)
        self.player.replaceCurrentItem(with: playerItem)
        self.updateTime()
        self.settingUIForEditVideo()
        self.player.play()
    }
}

extension EditorViewController {
    
    func addfiltertoVideo(strfiltername : String, strUrl : URL,  _ com: @escaping ((URL?, String?) -> Void)) {
        
        //FilterName
        let filter = CIFilter(name:strfiltername)
        //Asset
        let asset = AVAsset(url: strUrl)
        
        //Create Directory path for Save
        //Create Directory path for Save
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("addFilterVideo.mp4")
        try? FileManager.default.removeItem(at: fileUrl)
        
        //AVVideoComposition
        let composition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
            
            // Clamp to avoid blurring transparent pixels at the image edges
            let source = request.sourceImage.clampedToExtent()
            filter?.setValue(source, forKey: kCIInputImageKey)
            
            // Crop the blurred output to the bounds of the original image
            let output = filter?.outputImage!.cropped(to: request.sourceImage.extent)
            
            // Provide the filter output to the composition
            request.finish(with: output!, context: nil)
            
        })
        
        //export the video to as per your requirement conversion
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else { return }
        exportSession.outputFileType = AVFileType.mov
        exportSession.outputURL = fileUrl
        exportSession.videoComposition = composition
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status {
            case .completed:
                com(fileUrl, nil)
                
            case .failed:
                com(nil, exportSession.error?.localizedDescription)
                
            case .cancelled:
                com(nil, exportSession.error?.localizedDescription)
                
            default:
                com(nil, exportSession.error?.localizedDescription)
            }
        })
    }
    
    func generateThumbnail(path: URL) -> UIImage? {
        // getting image from video
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func convertImageToBW(filterName : String ,image:UIImage) -> UIImage {
        
        let filter = CIFilter(name: filterName)
        
        // convert UIImage to CIImage and set as input
        let ciInput = CIImage(image: image)
        filter?.setValue(ciInput, forKey: "inputImage")
        
        // get output CIImage, render as CGImage first to retain proper UIImage scale
        let ciOutput = filter?.outputImage
        let ciContext = CIContext()
        let cgImage = ciContext.createCGImage(ciOutput!, from: (ciOutput?.extent)!)
        
        return UIImage(cgImage: cgImage!)
    }
    
    func addStickerorTexttoVideo(videoUrl: URL, watermarkText text : String, stickerImg: UIImage?, position : Int,  _ com: @escaping ((URL?, String?) -> Void)) {
        
        let asset = AVURLAsset.init(url: videoUrl)
        
        let composition = AVMutableComposition.init()
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let clipVideoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]
        
        // Rotate to potrait
        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)
        let videoTransform:CGAffineTransform = clipVideoTrack.preferredTransform
        
        
        //fix orientation
        var videoAssetOrientation  = UIImage.Orientation.up
        
        print(videoAssetOrientation)
        
        var isVideoAssetPortrait  = false
        
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation = UIImage.Orientation.right
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation =  UIImage.Orientation.left
            isVideoAssetPortrait = true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation =  UIImage.Orientation.up
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation = UIImage.Orientation.down;
        }
        
        
        transformer.setTransform(clipVideoTrack.preferredTransform, at: CMTime.zero)
        transformer.setOpacity(0.0, at: asset.duration)
        
        //adjust the render size if neccessary
        var naturalSize: CGSize
        if(isVideoAssetPortrait){
            naturalSize = CGSize(width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.width)
        } else {
            naturalSize = clipVideoTrack.naturalSize;
        }
        
        var renderWidth: CGFloat!
        var renderHeight: CGFloat!
        
        renderWidth = naturalSize.width
        renderHeight = naturalSize.height
        
        let parentlayer = CALayer()
        let videoLayer = CALayer()
        let watermarkLayer = CALayer()
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderScale = 1.0
        
        parentlayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        videoLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        parentlayer.addSublayer(videoLayer)
        
        if stickerImg != nil {
            let stickerView:UIView = UIView.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize))
            let sticker:UIImageView = UIImageView.init()
            sticker.image = stickerImg
            sticker.contentMode = .scaleAspectFit
            let stickerWidth = renderWidth / 6
            let stickerX = renderWidth * CGFloat(5 * (position % 3)) / 12
            let stickerY = (renderHeight - ( renderHeight * CGFloat(position / 3) / 3)) - 150
            sticker.frame = CGRect(x:stickerX, y: stickerY, width: stickerWidth, height: stickerWidth)
            stickerView.addSubview(sticker)
            watermarkLayer.contents = stickerView.asImage().cgImage
            watermarkLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
            parentlayer.addSublayer(watermarkLayer)
        }
        
        if text != "" {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.font = UIFont(name: "OpenSans-Bold", size: 100.0) ?? UIFont.systemFont(ofSize: 100.0)
            
            if position % 3 == 0 {
                textLayer.alignmentMode = CATextLayerAlignmentMode.left
            } else if position % 3 == 1 {
                textLayer.alignmentMode = CATextLayerAlignmentMode.center
            } else {
                textLayer.alignmentMode = CATextLayerAlignmentMode.right
            }
            
            let textWidth = renderWidth / 5
            let textX = renderWidth * CGFloat(5 * (position % 3)) / 12
            let textY = renderHeight * CGFloat(position / 3) / 3
            textLayer.frame = CGRect(x: textX , y: textY + 20, width: textWidth, height: 50)
            textLayer.opacity = 0.6
            parentlayer.addSublayer(textLayer)
        }
        
        //Create Directory path for Save
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("addWatermarkVideo.mp4")
        try? FileManager.default.removeItem(at: fileUrl)
        
        // Add watermark to video
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentlayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30))
        
        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]
        
        let exporter = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputFileType = AVFileType.mov
        exporter?.outputURL = fileUrl
        exporter?.videoComposition = videoComposition
        
        exporter!.exportAsynchronously(completionHandler: {() -> Void in
            
            switch exporter!.status {
            case .completed :
                com(fileUrl, nil)
            case .failed:
                if let _error = exporter?.error?.localizedDescription {
                    com(nil,_error)
                }
            case .cancelled:
                if let _error = exporter?.error?.localizedDescription {
                    com(nil,_error)
                }
            default:
                if let _error = exporter?.error?.localizedDescription {
                    com(nil,_error)
                }
            }
        })
    }
    
    func doTransition() {
        let transition = effect.transition
        transition.duration = 2.0
        transition.transition(from: fromImage, to: toImage, updater: { [weak self] image in
            self?.previewEffectView.image = image
        }, completion: nil)
        
    }
    
    private func createVideo(audioUrl: URL?) {
        
        if listImagePicked.count == 0 {
            let alert = UIAlertController(title: "Picture empty", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                
            }))
            self.present(alert, animated: true, completion: nil)
            return
        }
    
        if pickedEffects.count < listImagePicked.count - 1 {
            let alert = UIAlertController(title: "Effect not match", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                
            }))
            self.present(alert, animated: true, completion: nil)
    
            return
        }
        
        showVideoEditorDone()
        
        let path = NSTemporaryDirectory().appending("SlideShow.mp4")
        let fileUrl = URL(fileURLWithPath: path)
        
        movieMaker = MTMovieMaker(outputURL: fileUrl)
        
        do {
            
            try movieMaker?.createVideo(with: listImagePicked, effects: self.pickedEffects, frameDuration: 2, transitionDuration: 1, audioURL: audioUrl, completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let url):
                    
                    self.fileURL = url
                    let playerItem = AVPlayerItem(url: url)
                    self.player.replaceCurrentItem(with: playerItem)
                    self.updateTime()
                    self.UpdateUIVideoFrame()
                    self.player.play()
                    print("create success")
                    
                case .failure(let error):
                    print(error)
                }
            })
        } catch {
            
            print(error)
        }
    }
    
    func exportVideo() {
        guard let fileURL = self.fileURL else { return }
        
        saveImageAndVideoToLibrary(url: fileURL)
    }
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
        let albumName = "VideoEditorMusicSlide"
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject!
        }
        
        return nil
    }
    
    
    func createAblum() {
        let albumName = "VideoEditorMusicSlide"
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }) { success, _ in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum()
            }
        }
    }
    
    func saveImageAndVideoToLibrary(url: URL) {
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                
                guard let assetCollectionPhong = self.assetCollection else{
                    return
                }
                
                PHPhotoLibrary.shared().performChanges({
                    let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    let assetPlaceholder = assetChangeRequest?.placeholderForCreatedAsset
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetCollectionPhong)
                    albumChangeRequest?.addAssets([assetPlaceholder] as NSFastEnumeration)
                }, completionHandler: { success, error in
                    
                    DispatchQueue.main.async {
                        if success {
                            let alert = UIAlertController(title: "Video Saved To Camera Roll", message: nil, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                                self.leftNavButton.isEnabled = false
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    if let error = error {
                        print("Error occurred while saving photo to photo library: \(error)")
                    }
                })
            default:
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "PhotoLibrary not authorized", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                        
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
                break
            }
        }
    }
    
    private func exportVideoFromVideoTransition(_ result: MTVideoTransitionResult) {
        exporter = try? MTVideoExporter(transitionResult: result)
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("video.mp4")
        exporter?.export(to: fileUrl, completion: { error in
            if let error = error {
                print("Export error:\(error)")
            } else {
                self.fileURL = fileUrl
            }
        })
    }
    
}

extension EditorViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        if self.isEditVideo == false {
            if results.count == 1 {
                let alert = UIAlertController(title: "Notification", message: "Please select greater than two images", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in
                    
                }))
                picker.present(alert, animated: true, completion: nil)
                return
            }
        }
        
        picker.dismiss(animated: true, completion: nil)
        
        self.processSpinner.startAnimating()
        
        self.stackButtonSelectMedia.isHidden = true
        
        guard !results.isEmpty else {
            self.stackButtonSelectMedia.isHidden = false
            self.processSpinner.stopAnimating()
            return
        }
        
        listImagePicked.removeAll()
        
        for result in results {
            let itemProvider = result.itemProvider
            
            guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
                  let utType = UTType(typeIdentifier)
            else { continue }
            
            if utType.conforms(to: .image) {
                self.getPhoto(from: itemProvider, total: results.count)
            } else if utType.conforms(to: .movie) {
                self.getVideo(from: itemProvider, typeIdentifier: typeIdentifier, total: results.count)
            }
        }
    }
    
    private func getPhoto(from itemProvider: NSItemProvider, total: Int) {
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        let img = self.reSize(image: image)
                        self.listImagePicked.append(img)
                        
                        if self.listImagePicked.count == total {
                            self.processSpinner.stopAnimating()
                            self.configureSubviews()
                            self.showUI()
                        }
                    }
                }
                
            }
        }
    }
    
    func reSize(image: UIImage) -> UIImage{
        let actualHeight:CGFloat = image.size.height
        let actualWidth:CGFloat = image.size.width
        let imgRatio:CGFloat = actualWidth/actualHeight
        let maxWidth:CGFloat = 1920.0
        let resizedHeight:CGFloat = maxWidth/imgRatio
        
        let rect:CGRect = CGRect(x: 0, y: 0, width: maxWidth, height: resizedHeight)
        UIGraphicsBeginImageContext(rect.size)
        image.draw(in: rect)
        let img: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        let imageData: Data = img.jpegData(compressionQuality: 0)!
        
        UIGraphicsEndImageContext()
        
        return UIImage(data: imageData)!
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
                    self.setupForEditVideo(url: targetURL)
                    if let thumImg = self.generateThumbnail(path: targetURL) {
                        CIFilterNames.indices.forEach {[weak self] index in
                            let image = self?.convertImageToBW(filterName: CIFilterNames[index], image: thumImg)
                            self?.filterImg.append(image!)
                        }
                        self.processSpinner.stopAnimating()
                        self.editConllection.reloadData()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension EditorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == editConllection {
            switch tab {
            case "Effects":
                return effects.count
            case "Musics":
                return sounds.count
            case "Setting":
                return settings.count
            case "Filters":
                return filterNames.count
            case "Stickers":
                return stickers.count
            case "Texts":
                return 1
            default:
                return 0
            }
            
        }
        else {
            return tabName.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        if collectionView == editConllection {
            let cell = editConllection.dequeueReusableCell(withReuseIdentifier: FilterEffectCLVCell.className, for: indexPath) as! FilterEffectCLVCell
            
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.clear.cgColor
            
            switch tab {
            case "Effects":
                
                if indexPath.row == 0 {
                    cell.nameFilter.text = "None"
                    cell.imageFilter.image = UIImage(named: "noneFilterImg")
                }else{
                    cell.nameFilter.text = "\(effects[indexPath.row])"
                    cell.imageFilter.image = UIImage(named: "effectImg")
                }
                
            case "Filters":
                
                if indexPath.row == 0 {
                    cell.nameFilter.text = "None"
                    cell.imageFilter.image = UIImage(named: "noneFilterImg")
                }else{
                    cell.nameFilter.text = self.filterNames[indexPath.row]
                    if filterImg.count == filterNames.count {
                        cell.imageFilter.image = filterImg[indexPath.row]
                    }
                }
            case "Musics":
                
                if indexPath.row == 0 {
                    cell.nameFilter.text = "None"
                    cell.imageFilter.image = UIImage(named: "noneFilterImg")
                }
                else if indexPath.row == 1 {
                    cell.nameFilter.text = "My Musics"
                    cell.imageFilter.image = UIImage(systemName: "music.note.list")
                }
                else{
                    cell.nameFilter.text = self.sounds[indexPath.row]
                    cell.imageFilter.image = UIImage(named: "musicIcon")
                }
            case "Setting":
                cell.imageFilter.image = UIImage(named: settings[indexPath.row])
                cell.nameFilter.text = ""
            case "Stickers":
                if indexPath.row == 0 {
                    cell.nameFilter.text = "None"
                    cell.imageFilter.image = UIImage(named: "noneFilterImg")
                }else{
                    cell.imageFilter.image = stickers[indexPath.row]
                    cell.nameFilter.text = ""
                }
            case "Texts":
                cell.nameFilter.text = "Close"
                cell.imageFilter.image = stickers[0]
            default:
                cell.imageFilter.image = nil
                cell.nameFilter.text = ""
            }
            
            return cell
        }else {
            let cell = tabEditorCollection.dequeueReusableCell(withReuseIdentifier: TabMusicCLVCell.className, for: indexPath) as! TabMusicCLVCell
            
            cell.TabNameLabel.textColor = UIColor.white
            cell.tabLine.image = nil
            
            if tab == tabName[indexPath.row] {
                cell.TabNameLabel.textColor = UIColor(named: "tab")
                cell.tabLine.image = UIImage(named: "shortLine")
            }
            
            cell.TabNameLabel.text = tabName[indexPath.row]
            
            return cell
        }
        
    }
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        return UICollectionReusableView()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let positionItems = ["BottomLeft", "BottomCenter", "BottomRight", "CenterLeft", "Center", "CenterRight", "TopLeft", "TopCenter", "TopRight"]
        
        if collectionView == editConllection {
            
            if let resetCell = collectionView.cellForItem(at: [0, 0]) as? FilterEffectCLVCell {
                resetCell.layer.borderWidth = 1
                resetCell.layer.borderColor = UIColor.clear.cgColor
            }
            
            let cell = collectionView.cellForItem(at: indexPath) as! FilterEffectCLVCell
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.white.cgColor
            
            switch tab {
            case "Effects":
                effect = effects[indexPath.row]
                doTransition()
            case "Musics":
                
                //TODO: Picking music from music library
                if indexPath.row == 1 {
                    let pickerController = MPMediaPickerController(mediaTypes: .music)
                    pickerController.allowsPickingMultipleItems = false
                    pickerController.delegate = self
                    pickerController.modalPresentationStyle = .overFullScreen
                    self.present(pickerController, animated: true)
                }
                
                if indexPath.row > 1 {
                    
                    self.selectMusic = self.sounds[indexPath.row]
                    
                    let popup = mainStoryboard.instantiateViewController(withIdentifier: "PopUpMusicVC")
                    as! PopUpMusicPlayViewController
                    
                    popup.soundName = self.sounds[indexPath.row]
                    
                    present(popup, animated: true, completion: nil)
                }
            case "Filters":
                if indexPath.row > 0 {
                    self.selectFilter = CIFilterNames[indexPath.row]
                    self.nextBtn.setTitle("ADD FILTER", for: .normal)
                    self.nextBtn.isHidden = false
                }else{
                    self.nextBtn.isHidden = true
                }
            case "Stickers":
                if indexPath.row > 0 {
                    
                    self.tabName = positionItems
                    self.selectSticker = stickers[indexPath.row]
                    tabEditorCollection.reloadData()
                }else{
                    self.nextBtn.isHidden = true
                    self.tabName = ["Filters", "Stickers", "Texts"]
                    tabEditorCollection.reloadData()
                }
            case "Texts":
                self.tabName = ["Filters", "Stickers", "Texts"]
                self.nextBtn.isHidden = true
                self.textInput.isHidden = true
                self.textInput.text = ""
                tabEditorCollection.reloadData()
            default:
                print("none")
            }
            
        }else {
            if tabName[indexPath.row] == "Stickers" || tabName[indexPath.row] == "Stickers" || tabName[indexPath.row] == "Texts" || tabName[indexPath.row] == "Filters" ||
                tabName[indexPath.row] == "Settings" {
                tab =  tabName[indexPath.row]
                if tab == "Texts" {
                    self.textInput.isHidden = false
                    self.textInput.becomeFirstResponder()
                }
                editConllection.reloadData()
            }else{
                self.selectPosition = indexPath.row
                if tab == "Stickers" {
                    nextBtn.setTitle("ADD STICKER", for: .normal)
                }else if tab == "Texts" {
                    nextBtn.setTitle("ADD TEXT", for: .normal)
                }
                
                self.nextBtn.isHidden = false
            }
            
            let cell = collectionView.cellForItem(at: indexPath) as! TabMusicCLVCell
            
            tabName.indices.forEach { index in
                if let resetCell = collectionView.cellForItem(at: [0, index]) as? TabMusicCLVCell {
                    resetCell.TabNameLabel.textColor = UIColor.white
                    resetCell.tabLine.image = nil
                }
            }
            
            cell.TabNameLabel.textColor = UIColor(named: "tab")
            cell.tabLine.image = UIImage(named: "shortLine")
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView == editConllection {
            guard let cell = collectionView.cellForItem(at: indexPath) as? FilterEffectCLVCell else {
                return
            }
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.clear.cgColor
        }else {
            
            let cell = collectionView.cellForItem(at: indexPath) as! TabMusicCLVCell
            cell.TabNameLabel.textColor = UIColor.white
            cell.tabLine.image = nil
            
        }
    }
    
}

extension EditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let positionItems = ["BottomLeft", "BottomCenter", "BottomRight", "CenterLeft", "Center", "CenterRight", "TopLeft", "TopCenter", "TopRight"]
        if textField.text != "" {
            self.tabName = positionItems
            self.tabEditorCollection.reloadData()
        }
        textField.resignFirstResponder()
        return true
    }
}

extension EditorViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == editConllection {
            
            if UIDevice.current.userInterfaceIdiom == .pad{
                return CGSize(width: 100, height: 95)
            }
            else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
                return CGSize(width: 100, height: 95)
            }else{
                return CGSize(width: 100, height: 95)
            }
        }else {
            if UIDevice.current.userInterfaceIdiom == .pad{
                return CGSize(width: 126, height: 40)
            }
            else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
                return CGSize(width: 126, height: 40)
            }else{
                return CGSize(width: 126, height: 40)
            }
        }
        
    }
}

extension EditorViewController: MPMediaPickerControllerDelegate {
    // MPMediaPickerController Delegate methods
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        self.dismiss(animated: true, completion: nil)
        
        self.nextBtn.isHidden = true
        
        self.processSpinner.startAnimating()
        
        DispatchQueue.main.async {
            let popup = self.mainStoryboard.instantiateViewController(withIdentifier: "PopUpMusicVC")
            as! PopUpMusicPlayViewController
            
//            popup.soundName =
            
            popup.mediaItem = [mediaItemCollection.items[0]]
            
            self.present(popup, animated: true) {
                self.processSpinner.stopAnimating()
            }
        }
        
    }
}
