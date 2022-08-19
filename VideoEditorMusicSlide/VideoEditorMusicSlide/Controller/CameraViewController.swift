//
//  CameraViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 22/11/2021.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer
import Photos
import PhotosUI
import MobileCoreServices

public enum CameraPosition {
    case front
    case rear
}

public enum OutputType {
    case photo
    case video
}

enum CameraControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
}

class CameraViewController: UIViewController {
    
    typealias UIViewControllerType = PHPickerViewController
    
    var solutions: [String] = ["Resolution", "1920x1080", "1280 x 720", "864 x 480"]
    
    var tabName: [String] = ["My Tracks", "My Music", "History"]
    
    var soundName: [String] = ["At the Submit", "Flies Away", "Frozen Lake", "NightLife", "ITE They Parted", "Life Is Jorney"]
    
    var storeSoundName: [String] = ["At the Submit", "Flies Away", "Frozen Lake", "NightLife", "ITE They Parted", "Life Is Jorney"]
    
    @IBOutlet weak var MusicTable: UITableView!
    @IBOutlet weak var MusicView: UIView!
    
    var filters: [String] = ["noneFilterImg", "Rosy", "Mono", "Sepia Tone", "Bloom", "Invert"]
    
    var tab: String = ""
    
    var selectedMusicTab: Int = 0
    
    var videoRecordingStarted: Bool = false
    
    var videoUrl: URL?
    
    var defautPreset: AVCaptureSession.Preset = AVCaptureSession.Preset.high
    
    private let dataOutputQueue = DispatchQueue(label: "VideoDataQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    private let filterRenderers: [FilterRenderer] = [RosyCIRenderer(), MonoCIRenderer(), SpeiaToneCIRenderer(), BloomCIRenderer(), InvertCIRenderer()]
    
    private var videoFilter: FilterRenderer?
    
    var filteringEnabled: Bool = false
    
    var currentVideoDimensions: CMVideoDimensions?
    
    var assetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    
    var isWriting: Bool = false
    
    var currentSampleTime: CMTime?
    
    var mediaItems: [MPMediaItem] = []
    
    var selectFilterIndex: Int = -1
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var audioDevice: AVCaptureDevice?
    
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var flashMode: AVCaptureDevice.FlashMode = AVCaptureDevice.FlashMode.off
    
    var videoOutput: AVCaptureVideoDataOutput?
    var audioOuput: AVCaptureAudioDataOutput?
    var audioInput: AVCaptureDeviceInput?
    var outputType: OutputType?
    
    var assetWriter: AVAssetWriter?
    var audioAssetInput: AVAssetWriterInput?
    
    private var renderingEnabled = true
    
    var isVideoMode: Bool = false
    
    var assetCollection: PHAssetCollection?
    
    // for counting time record video
    private weak var displayLink: CADisplayLink?
    private var startTime: CFTimeInterval?
    private var elapsed: CFTimeInterval = 0
    private var priorElapsed: CFTimeInterval = 0
    //
    @IBOutlet weak var searchText: CustomPaddingTextField!
    @IBOutlet weak var flashBtn: UIButton!
    @IBOutlet weak var StackMusicBtn: UIStackView!
    @IBOutlet weak var switchPhotoVideoModeBtn: UIButton!
    @IBOutlet weak var filterBtn: UIButton!
    @IBOutlet weak var musicBtn: UIButton!
    @IBOutlet weak var libraryBtn: UIButton!
    @IBOutlet weak var navBarStackVIew: UIStackView!
    @IBOutlet weak var timeVideoRecord: UILabel!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var musicBtn2: UIButton!
    @IBOutlet weak var musicBtn1: UIButton!
    @IBOutlet weak var StackButton: UIStackView!
    @IBOutlet weak var TabMusicCollection: UICollectionView!
    @IBOutlet weak var resolutionTable: UITableView!
    @IBOutlet weak var FilterEffectCollection: UICollectionView!
    @IBOutlet weak var cameraFrame: PreviewMetalView!
    @IBOutlet weak var closeFilterEffectBtn: UIButton!
    @IBOutlet weak var ImageLabel: UIImageView!
    
    var photos: PHFetchResult<PHAsset>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        resolutionTable.layer.cornerRadius = 6
        resolutionTable.separatorStyle = .none
        
        resolutionTable.delegate = self
        resolutionTable.dataSource = self
        
        resolutionTable.register(UINib(nibName: ResolutionTBVCell.className, bundle: nil), forCellReuseIdentifier: ResolutionTBVCell.className)
        
        MusicTable.delegate = self
        MusicTable.dataSource = self
        MusicTable.separatorStyle = .none
        
        MusicTable.register(UINib(nibName: MusicCLVCell.className, bundle: nil), forCellReuseIdentifier: MusicCLVCell.className)
        
        resolutionTable.isHidden = true
        
        searchText.delegate = self
        
        FilterEffectCollection.isHidden = true
        FilterEffectCollection.delegate = self
        FilterEffectCollection.dataSource = self
        
        FilterEffectCollection.register(UINib(nibName: FilterEffectCLVCell.className, bundle: nil), forCellWithReuseIdentifier: FilterEffectCLVCell.className)
        
        TabMusicCollection.delegate = self
        TabMusicCollection.dataSource = self
        TabMusicCollection.register(UINib(nibName: TabMusicCLVCell.className, bundle: nil), forCellWithReuseIdentifier: TabMusicCLVCell.className)
        
        ImageLabel.image = nil
        
        MusicView.isHidden = true
        
        MusicView.layer.cornerRadius = 20
        
        StackMusicBtn.isHidden = true
        closeFilterEffectBtn.isHidden = true
        
        musicBtn1.isHidden = true
        musicBtn2.isHidden = true
        
        timeVideoRecord.isHidden = true
        
        Check()
        
        registerNotification()
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.createAblum()
                self.getAssetFromPhoto()
            }
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataOutputQueue.async {
            self.renderingEnabled = false
            self.captureSession.stopRunning()
        }
    }
    
    
    @IBAction func CloseMusicAction(_ sender: Any) {
        StackButton.isHidden = false
        MusicView.isHidden = true
        StackMusicBtn.isHidden = true
    }
    
    @IBAction func CloseFilterEffectAction(_ sender: Any) {
        FilterEffectCollection.isHidden = true
        closeFilterEffectBtn.isHidden = true
        ImageLabel.image = nil
    }
    
    @IBAction func TakePicAction(_ sender: Any) {
        resolutionTable.isHidden = true
        
        if isVideoMode {
            self.outputType = .video
        }else{
            self.outputType = .photo
        }
    
        if self.outputType == .photo {
            self.flashScreen()
            self.captureImage()
        }
        else {
            if videoRecordingStarted {
                videoRecordingStarted = false
                timeVideoRecord.isHidden = true
                recordBtn.setImage(UIImage(named: "takePicBtn"), for: .normal)
                stopDisplayLink()
                elapsed = 0
                priorElapsed = 0
                updateUI()
                
                libraryBtn.isHidden = false
                musicBtn.isHidden = false
                switchPhotoVideoModeBtn.isHidden = false
                filterBtn.isHidden = false
                recordBtn.isHidden = false
                StackButton.backgroundColor = UIColor(named: "bgColor2")
                navBarStackVIew.isHidden = false
                
                self.stopRecording()
            } else if !videoRecordingStarted {
                
                videoRecordingStarted = true
                timeVideoRecord.isHidden = false
                libraryBtn.isHidden = true
                musicBtn.isHidden = true
                switchPhotoVideoModeBtn.isHidden = true
                filterBtn.isHidden = true
                navBarStackVIew.isHidden = true
                recordBtn.isHidden = false
                StackButton.backgroundColor = UIColor.clear
                recordBtn.setImage(UIImage(named: "pauseRCBtn"), for: .normal)
                if displayLink == nil {
                    startDisplayLink()
                }
                
                self.recordVideo()
            }
        }
    }
    
    @IBAction func searchMusic(_ sender: Any) {
        if let text = searchText.text {
            if text != ""{
                soundName = storeSoundName.filter{ $0.lowercased().contains(text.trimmingCharacters(in: .whitespaces).lowercased()) }
                
                MusicTable.reloadData()
            }else {
                soundName = storeSoundName
                MusicTable.reloadData()
                
            }
        }

    }
    @IBAction func ResolutionAction(_ sender: Any) {
        if resolutionTable.isHidden {
            resolutionTable.isHidden = false
        }else{
            resolutionTable.isHidden = true
        }
    }
    @IBAction func BackAction(_ sender: Any) {
        captureSession.stopRunning()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func OpenMusic(_ sender: Any) {
        StackButton.isHidden = true
        MusicView.isHidden = false
        StackMusicBtn.isHidden = false
        
    }
    
    @IBAction func OpenLibrary(_ sender: Any) {
        if FilterEffectCollection.isHidden {
            tab = "library"
            ImageLabel.image = UIImage(named: "hlbBtn")
            FilterEffectCollection.isHidden = false
            closeFilterEffectBtn.isHidden = false
            FilterEffectCollection.reloadData()
        }
        
    }
    
    @IBAction func SwitchPhotoVideoAction(_ sender: Any) {
        if isVideoMode {
            isVideoMode = false
            switchPhotoVideoModeBtn.setImage(UIImage(named: "switchVideoBtn"), for: .normal)
        }else{
            isVideoMode = true
            switchPhotoVideoModeBtn.setImage(UIImage(named: "switchCamBtn"), for: .normal)
            
//            switchVideoBtn
        }
    }
    
    @IBAction func OpenFilter(_ sender: Any) {
        if FilterEffectCollection.isHidden {
            tab = "filter"
            ImageLabel.image = UIImage(named: "hflBtn")
            FilterEffectCollection.isHidden = false
            closeFilterEffectBtn.isHidden = false
            FilterEffectCollection.reloadData()
        }
    }
    
    @IBAction func MusicBtn1Action(_ sender: Any) {
        switch selectedMusicTab {
        case 0:
            print("btn1.1")
        case 1:
            print("btn1.2")
        case 2:
            UserDefaults.standard.set(nil, forKey: "saveHistory")
            soundName.removeAll()
            MusicTable.reloadData()
        default:
            print("btn1.0")
        }
    }
    
    @IBAction func MusicBtn2Action(_ sender: Any) {
        if selectedMusicTab == 0 {
            print("btn2")
        }
        
    }
    
    @IBAction func toggleFlash(_ sender: Any) {
        try? rearCamera?.lockForConfiguration()
        if flashMode == .on {
            flashBtn.setImage(UIImage(named: "thunder"), for: .normal)
            flashMode = .off
            rearCamera?.torchMode = .off
            rearCamera?.unlockForConfiguration()
            
        } else {
            flashBtn.setImage(UIImage(named: "offFlash"), for: .normal)
            
            flashMode = .on
            rearCamera?.torchMode = .on
            rearCamera?.unlockForConfiguration()
        }
    }
    
    
    @IBAction func toggleCamera(_ sender: Any) {
        do {
            try switchCameras()
        } catch {
            print(error.localizedDescription)
        }
    }
   
    @IBAction func openEditor(_ sender: Any) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        let editorVC = mainStoryboard.instantiateViewController(withIdentifier: "EditorVC")
        
        present(editorVC, animated: true, completion: nil)
    }
}


extension CameraViewController {
    
    func getAssetFromPhoto() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.fetchLimit = 30
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.photos = PHAsset.fetchAssets(with: options)
               
                DispatchQueue.main.async {
                    self.FilterEffectCollection.reloadData() // reload your collectionView
                }
                
            }else {
                print("not authorized")
            }
        }
       
    }

    
    func startDisplayLink() {
        startTime = CACurrentMediaTime()
        let displayLink = CADisplayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }
    func stopDisplayLink() {
        displayLink?.invalidate()
    }
    
    @objc func handleDisplayLink(_ displayLink: CADisplayLink) {
        guard let startTime = startTime else { return }
        elapsed = CACurrentMediaTime() - startTime
        updateUI()
    }
    
    func flashScreen() {
        let flashView = UIView(frame: self.cameraFrame.frame)
        self.cameraFrame.addSubview(flashView)
        flashView.backgroundColor = .black
        flashView.layer.opacity = 1
        UIView.animate(withDuration: 0.25, animations: {
            flashView.layer.opacity = 0
        }, completion: { _ in
            flashView.removeFromSuperview()
        })
    }
    

    func updateUI()  {
        let totalElapsed = elapsed + priorElapsed
        
        let hundredths = Int((totalElapsed * 100).rounded())
        let (minutes, hundredthsOfSeconds) = hundredths.quotientAndRemainder(dividingBy: 60 * 100)
        let (seconds, milliseconds) = hundredthsOfSeconds.quotientAndRemainder(dividingBy: 100)
        
        timeVideoRecord.text = "\(String(minutes)):\(String(format: "%02d", seconds)):\(String(format: "%02d", milliseconds))"
    }
    
    fileprivate func registerNotification() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: NSNotification.Name(rawValue: "App is going background"), object: nil)
        
        
        notificationCenter.addObserver(self,
                                               selector: #selector(willEnterForground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(backToCam), name: NSNotification.Name(rawValue: "backToCam"), object: nil)
    }
    
    
    @objc
    func willEnterForground(notification: NSNotification) {
        dataOutputQueue.async {
            self.captureSession.startRunning()
            self.renderingEnabled = true
        }
    }
    
    @objc func backToCam() {
        dataOutputQueue.async {
            self.captureSession.startRunning()
            self.renderingEnabled = true
        }
    }
    
    @objc func appMovedToBackground() {
        if videoRecordingStarted {
            videoRecordingStarted = false
            self.stopRecording()
        }
        dataOutputQueue.async {
            self.renderingEnabled = false
            if let videoFilter = self.videoFilter {
                videoFilter.reset()
            }
            self.captureSession.stopRunning()
            self.cameraFrame.pixelBuffer = nil
            self.cameraFrame.flushTextureCache()
        }
    }
    
    func Check() {
        var isAuthorizedVideo: Bool = false
        var isAuthorizedAudio: Bool = false
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorizedVideo = true
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    isAuthorizedVideo = true
                }else{
                    isAuthorizedVideo = false
                }
            }
            break
        case .denied:
            isAuthorizedVideo = false
            let alert = UIAlertController(title: "Access denied", message: "Can't record video", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        default:
            break
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            isAuthorizedAudio = true
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { status in
                if status {
                    isAuthorizedAudio = true
                }else{
                    isAuthorizedAudio = false
                }
            }
            break
        case .denied:
            isAuthorizedAudio = false
            let alert = UIAlertController(title: "Access denied", message: "Can't record video", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        default:
            break
        }
        
        if isAuthorizedAudio == true && isAuthorizedVideo == true {
            self.setup()
        }
    }
    
  
    
    func configureCaptureDevices() throws{
        let session = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualWideCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        
        let cameras = (session.devices.compactMap{$0})
        
        for camera in cameras {
            if camera.position == .front {
                self.frontCamera = camera
                    
            }
            if camera.position == .back {
                self.rearCamera = camera
                try camera.lockForConfiguration()
                camera.focusMode = .continuousAutoFocus
                camera.unlockForConfiguration()
                
               
            }
        }
        self.audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
        
        
    }
    
    //Configure inputs with capture session
    //only allows one camera-based input per capture session at a time.
    func configureDeviceInputs() throws {
        
        if let rearCamera = self.rearCamera {
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                self.currentCameraPosition = .rear
            } else {
                throw CameraControllerError.inputsAreInvalid
            }
        }
        
        else if let frontCamera = self.frontCamera {
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            } else {
                throw CameraControllerError.inputsAreInvalid
            }
        }
        
        else {
            throw CameraControllerError.noCamerasAvailable
        }
        
        if let audioDevice = self.audioDevice {
            self.audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(self.audioInput!) {
                captureSession.addInput(self.audioInput!)
            } else {
                throw CameraControllerError.inputsAreInvalid
            }
        }
    }
    
    //Configure outputs with capture session
    func configurePhotoOutput(){
        
        self.photoOutput = AVCapturePhotoOutput()
        self.photoOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg ])], completionHandler: nil)
        if captureSession.canAddOutput(self.photoOutput!) {
            captureSession.addOutput(self.photoOutput!)
        }
        self.outputType = .photo
        
    }
    
    func configureOutput(){
    
        self.videoOutput = AVCaptureVideoDataOutput()
        
        if captureSession.canAddOutput(self.videoOutput!) {
            captureSession.addOutput(self.videoOutput!)
            self.videoOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            self.videoOutput?.setSampleBufferDelegate(self, queue: dataOutputQueue)
        }
        
        self.audioOuput = AVCaptureAudioDataOutput()
        if captureSession.canAddOutput(self.audioOuput!) {
            captureSession.addOutput(self.audioOuput!)
            audioOuput!.setSampleBufferDelegate(self, queue: dataOutputQueue)
        }
        
        self.cameraFrame.rotation = .rotate90Degrees
    }
    
    func changePreset(){
        captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(self.defautPreset) {
            captureSession.sessionPreset = self.defautPreset
        }else{
            captureSession.sessionPreset = AVCaptureSession.Preset.high
        }
        captureSession.commitConfiguration()
    }
    
    func configureAvAssetWriter() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("video.mp4")
        try? FileManager.default.removeItem(at: fileUrl)
        
        do{
            self.videoUrl = fileUrl
            
            let audioSettings = audioOuput?.recommendedAudioSettingsForAssetWriter(writingTo: .mp4)
            
            let videoSettings = videoOutput!.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
            
            self.assetWriter = try AVAssetWriter(outputURL: fileUrl, fileType: .mp4)
            
            let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            
            switch currentCameraPosition {
            case .front:
                var transform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
                transform = transform.rotated(by: CGFloat(Double.pi/2))
                videoInput.transform = transform
                
            case .rear:
                videoInput.transform = CGAffineTransform.init(rotationAngle: .pi / 2)
            case .none:
                print("none")
            }
            videoInput.expectsMediaDataInRealTime = true
            
            audioAssetInput = AVAssetWriterInput(mediaType: .audio,
                                                     outputSettings: audioSettings)
       
            audioAssetInput!.expectsMediaDataInRealTime = true
            
            
            let sourcePixelBufferAttributesDictionary = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_32BGRA),
                String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
                String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height)
            ] as [String : Any]
            
            assetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput,
                                                                               sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)

            if assetWriter!.canAdd(videoInput) {
                assetWriter!.add(videoInput)
            }
            if assetWriter!.canAdd(audioAssetInput!){
                assetWriter!.add(audioAssetInput!)
            }
        }
        catch{
            print(error.localizedDescription)
        }
        
    }
    
    func setup() {
        DispatchQueue(label: "setup").async { [self] in
            do {
                captureSession.beginConfiguration()
                try self.configureCaptureDevices()
                try self.configureDeviceInputs()
                self.configurePhotoOutput()
                self.configureOutput()
//                self.configureAvAssetWriter()
                captureSession.commitConfiguration()
                captureSession.startRunning()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func switchCameras() throws {
        
        let inputs = captureSession.inputs
        
        captureSession.beginConfiguration()
        
        func switchToFrontCamera() throws {
            
            cameraFrame.mirroring = true
            guard let rearCameraInput = self.rearCameraInput, inputs.contains(rearCameraInput),let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
            captureSession.removeInput(rearCameraInput)
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                self.currentCameraPosition = .front
            }
            else { throw CameraControllerError.invalidOperation }
        }
        
        func switchToRearCamera() throws {
            cameraFrame.mirroring = false
            guard let frontCameraInput = self.frontCameraInput, inputs.contains(frontCameraInput), let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            captureSession.removeInput(frontCameraInput)
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            if captureSession.canAddInput(rearCameraInput!) {
                captureSession.addInput(rearCameraInput!)
                self.currentCameraPosition = .rear
            }
            
            else { throw CameraControllerError.invalidOperation }
        }
        
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
            captureSession.commitConfiguration()
            
        case .rear:
          
            try switchToFrontCamera()
            captureSession.commitConfiguration()
        case .none:
            print("none")
        }
        
    }
    
    func captureImage() {
        let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
        photoSettings.flashMode = self.flashMode
        
        self.photoOutput!.capturePhoto(with: photoSettings, delegate: self)
    }
    
    func recordVideo() {

        configureAvAssetWriter()
        if assetWriter?.startWriting() != true {
            print("Error writing: \(assetWriter?.error?.localizedDescription ?? "")")
        }
        assetWriter?.startSession(atSourceTime: currentSampleTime!)
        
        isWriting = true

    }
    
    func stopRecording() {
        self.isWriting = false
        assetWriterPixelBufferInput = nil
        
        assetWriter?.finishWriting {
            if let url = self.videoUrl {
                self.saveImageAndVideoToLibrary(url: url)
            }
        }
        
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
    
    func getDurationTimeMusic(name: String,_ com: @escaping (String) -> Void){
        if let url = Bundle.main.url(forResource: name, withExtension: "mp3") {
            let audioAsset = AVURLAsset.init(url: url, options: nil)

            audioAsset.loadValuesAsynchronously(forKeys: ["duration"]) {
                var error: NSError? = nil
                let status = audioAsset.statusOfValue(forKey: "duration", error: &error)
                switch status {
                case .loaded: // Sucessfully loaded. Continue processing.
                    let duration = audioAsset.duration
                    let durationInSeconds = CMTimeGetSeconds(duration)
                    let stringTime: String = self.getCurrentTime(value: durationInSeconds)
                    com(stringTime)
                    break
                case .failed:
                    com("00:00")
                    break // Handle error
                case .cancelled:
                    com("00:00")
                    break // Terminate processing
                default:
                    com("00:00")
                    break // Handle all other cases
                }
            }
        }
    }
    
    func getCurrentTime(value: TimeInterval) -> String {
        return "\(Int(value / 60)):\(Int(value.truncatingRemainder(dividingBy: 60)) <= 9 ? "0" : "")\(Int(value.truncatingRemainder(dividingBy: 60)))"
    }
    
}



extension CameraViewController: AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)!
        self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
        self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        
        processVideo(sampleBuffer: sampleBuffer)
        
        if connection.audioChannels.count > 0 {
            if audioAssetInput?.isReadyForMoreMediaData == true {
                audioAssetInput?.append(sampleBuffer)
            }
        }
    
    }
    
    func processVideo(sampleBuffer: CMSampleBuffer) {
        if !renderingEnabled {
            return
        }
        
        guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
                return
        }
        
        var finalVideoPixelBuffer = videoPixelBuffer
        if let filter = videoFilter {
            if !filter.isPrepared {
               
                filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
            }
            
            // Send the pixel buffer through the filter
            guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
                print("Unable to filter video buffer")
                return
            }
            
            finalVideoPixelBuffer = filteredBuffer
            
           
        }
        
        if self.isWriting {
            if self.assetWriterPixelBufferInput?.assetWriterInput.isReadyForMoreMediaData == true {
            
                let success = self.assetWriterPixelBufferInput?.append(finalVideoPixelBuffer, withPresentationTime: self.currentSampleTime!)
    

                if success == false {
                    print("Pixel Buffer failed")
                }
            
            }
        
        }
        
        cameraFrame.pixelBuffer = finalVideoPixelBuffer
    }

    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoPixelBuffer = photo.pixelBuffer else {
            print("Error occurred while capturing photo: Missing pixel buffer (\(String(describing: error)))")
            return
        }
        
        var photoFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: photoPixelBuffer,
                                                     formatDescriptionOut: &photoFormatDescription)
        
        DispatchQueue(label: "processing").async {
            var finalPixelBuffer = photoPixelBuffer
            if let filter = self.videoFilter {
                if !filter.isPrepared {
                    if let unwrappedPhotoFormatDescription = photoFormatDescription {
                        filter.prepare(with: unwrappedPhotoFormatDescription, outputRetainedBufferCountHint: 2)
                    }
                }
                
                guard let filteredPixelBuffer = filter.render(pixelBuffer: finalPixelBuffer) else {
                    print("Unable to filter photo buffer")
                    return
                }
                finalPixelBuffer = filteredPixelBuffer
            }
            
            let metadataAttachments: CFDictionary = photo.metadata as CFDictionary
            
            guard let jpegData = self.jpegData(withPixelBuffer: finalPixelBuffer, attachments: metadataAttachments) else {
                print("Unable to create JPEG photo")
                return
            }
            
            
            // Save JPEG to photo library
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    PHPhotoLibrary.shared().performChanges({
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: jpegData, options: nil)
                    }, completionHandler: { _, error in
                        if let error = error {
                            print("Error occurred while saving photo to photo library: \(error)")
                        }
                    })
                }
            }
        }
    }
    
    func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?) -> Data? {
        let ciContext = CIContext()
        let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
        
        if  currentCameraPosition == .front {
            let transform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            renderedCIImage.transformed(by: transform)
        }
        
        guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
            print("Failed to create CGImage")
            return nil
        }
        
        guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
            print("Create CFData error!")
            return nil
        }
        
        guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            print("Create CGImageDestination error!")
            return nil
        }
        
        CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
        if CGImageDestinationFinalize(cgImageDestination) {
            return data as Data
        }
        print("Finalizing CGImageDestination error!")
        return nil
    }
}

extension CameraViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.FilterEffectCollection  {
            switch tab {
            case "filter":
                return filters.count
            case "library":
                if photos !== nil && photos.count > 0 {
                    return photos.count
                }else{
                    return 0
                }
                
            default:
                return 0
            }
        }else{
            return tabName.count
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        if collectionView == self.FilterEffectCollection {
            let cell = FilterEffectCollection.dequeueReusableCell(withReuseIdentifier: FilterEffectCLVCell.className, for: indexPath) as! FilterEffectCLVCell
            
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.clear.cgColor
            
            
            
            switch tab {
            case "filter":
                if indexPath.row == selectFilterIndex {
                    cell.layer.borderWidth = 1
                    cell.layer.borderColor = UIColor.white.cgColor
                }
                cell.imageFilter.image = UIImage(named: filters[indexPath.row])
                if indexPath.row == 0 {
                    cell.nameFilter.text = "None"
                }else{
                    cell.nameFilter.text = filters[indexPath.row]
                }

            case "library":
                let asset = photos!.object(at: indexPath.row)
           
                PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 63, height: 63), contentMode: PHImageContentMode.aspectFit , options: nil) { (image, userInfo) -> Void in
                    cell.imageFilter.image = image
                }
                cell.nameFilter.text = ""
            default:
                cell.imageFilter.image = nil
                cell.nameFilter.text = ""
            }
            
            return cell
        }else {
            let cell = TabMusicCollection.dequeueReusableCell(withReuseIdentifier: TabMusicCLVCell.className, for: indexPath) as! TabMusicCLVCell
            if selectedMusicTab == indexPath.row {
                cell.TabNameLabel.textColor = UIColor(named: "tab")
                cell.tabLine.image = UIImage(named: "Line 1")
            }else {
                cell.TabNameLabel.textColor = UIColor.white
                cell.tabLine.image = nil
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
        
        let sounds: [String] = ["At the Submit", "Flies Away", "Frozen Lake", "NightLife", "ITE They Parted", "Life Is Jorney"]
        
        if collectionView == self.FilterEffectCollection {
            
            let cell = collectionView.cellForItem(at: indexPath) as! FilterEffectCLVCell
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.white.cgColor
            
            if tab == "filter" {
                if indexPath.row == 0 {
                    filteringEnabled = false
                    selectFilterIndex = -1
                }else {
                    filteringEnabled = true
                    
                    selectFilterIndex = indexPath.row
                }
                dataOutputQueue.async { [self] in
                    if filteringEnabled {
                        self.videoFilter = self.filterRenderers[indexPath.row - 1]
                        
                    } else {
                        if let filter = self.videoFilter {
                            filter.reset()
                        }
                        self.videoFilter = nil
                    }
                }
            }else if tab == "library"{
                let asset = photos!.object(at: indexPath.row)
               
                if asset.mediaType == PHAssetMediaType.video {
                    print("Not a valid video media type")
                    
                    PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
                        DispatchQueue.main.async {
                            let assetPhong = avAsset as! AVURLAsset
                            let player = AVPlayer(url: assetPhong.url)
                            let playerViewController = AVPlayerViewController()
                            playerViewController.modalPresentationStyle = .overFullScreen
                            playerViewController.player = player
                            player.play()
                            self.present(playerViewController, animated: true, completion: nil)
                        }
                    }
                    
                }
            }
            
        }else {
            selectedMusicTab = indexPath.row
            if let resetCell = collectionView.cellForItem(at: [0, 0]) as? TabMusicCLVCell {
                resetCell.TabNameLabel.textColor = UIColor.white
                resetCell.tabLine.image = nil
            }
            let cell = collectionView.cellForItem(at: indexPath) as! TabMusicCLVCell
            cell.TabNameLabel.textColor = UIColor(named: "tab")
            cell.tabLine.image = UIImage(named: "Line 1")
            
            switch indexPath.row {
            case 0:
                musicBtn1.setImage(nil, for: .normal)
                musicBtn2.setImage(nil, for: .normal)
                musicBtn1.isHidden = true
                musicBtn2.isHidden = true
                soundName = sounds
                storeSoundName = sounds
                MusicTable.reloadData()
            case 1:
                musicBtn1.setImage(nil, for: .normal)
                musicBtn2.setImage(nil, for: .normal)
                musicBtn1.isHidden = true
                musicBtn2.isHidden = true
                soundName.removeAll()
                storeSoundName.removeAll()
                if let mediaItems = MPMediaQuery.songs().items {
                    
                    self.mediaItems =  mediaItems
                    
                    mediaItems.forEach { item in
                        soundName.append("\(item.title!).mp3")
                        storeSoundName.append("\(item.title!).mp3")
                    }
                   
                    MusicTable.reloadData()
                    
                }else{
                    soundName.removeAll()
                    storeSoundName.removeAll()
                    MusicTable.reloadData()
                }
                
            case 2:
                soundName.removeAll()
                storeSoundName.removeAll()
                if let historyMusics: [String] = UserDefaults.standard.stringArray(forKey: "saveHistory"){
                    self.soundName = historyMusics
                    self.storeSoundName = historyMusics
                    MusicTable.reloadData()
                }else {
                    MusicTable.reloadData()
                }
                musicBtn1.setImage(UIImage(named: "clearBtn"), for: .normal)
                musicBtn2.setImage(nil, for: .normal)
                musicBtn1.isHidden = false
                musicBtn2.isHidden = true
            default:
                musicBtn1.setImage(nil, for: .normal)
                musicBtn2.setImage(nil, for: .normal)
                musicBtn1.isHidden = true
                musicBtn2.isHidden = true
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if collectionView == self.FilterEffectCollection {
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


extension CameraViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CameraViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.FilterEffectCollection {
            if UIDevice.current.userInterfaceIdiom == .pad{
                return CGSize(width: 75, height: 95)
            }
            else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
                return CGSize(width: 75, height: 95)
            }else{
                return CGSize(width: 75, height: 95)
            }
        }else {
            if UIDevice.current.userInterfaceIdiom == .pad{
                return CGSize(width: 100, height: 40)
            }
            else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
                return CGSize(width: 100, height: 40)
            }else{
                return CGSize(width: 100, height: 40)
            }
        }
        
    }
}

extension CameraViewController: UITableViewDelegate, UITableViewDataSource  {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.resolutionTable {
            return solutions.count
        }else {
            return soundName.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.resolutionTable {
            let cell = resolutionTable.dequeueReusableCell(withIdentifier: ResolutionTBVCell.className, for: indexPath) as! ResolutionTBVCell
            cell.resolutionLabel.text = solutions[indexPath.row]
            return cell
        }else {
            let cell = MusicTable.dequeueReusableCell(withIdentifier: MusicCLVCell.className, for: indexPath) as! MusicCLVCell
            if selectedMusicTab == 0 {
                self.getDurationTimeMusic(name: soundName[indexPath.row]) { time in
                    DispatchQueue.main.async {
                        cell.timeLb.text = time
                    }
                }
            }else {
                cell.timeLb.text = ""
            }
            cell.musicNameLb.text = soundName[indexPath.row]
           
            return cell
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        resolutionTable.isHidden = true
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        
        if tableView == self.resolutionTable {
            switch indexPath.row {
            case 0:
                resolutionTable.isHidden = true
            case 1:
                self.defautPreset = .hd1920x1080
                changePreset()
                
            case 2:
                self.defautPreset = .hd1280x720
                changePreset()
                
            case 3:
                self.defautPreset = .vga640x480
                changePreset()
                
            default:
                self.defautPreset = .high
                changePreset()
            }

        }else {
            let popup = mainStoryboard.instantiateViewController(withIdentifier: "PopUpMusicVC")
            as! PopUpMusicPlayViewController
            if selectedMusicTab < 2 {
                
                let defaults = UserDefaults.standard
                
                var arrMusic: [String] = []
                
                if let historyMusics: [String] = defaults.stringArray(forKey: "saveHistory"){
                    arrMusic = historyMusics
                    
                    arrMusic.insert(self.soundName[indexPath.row], at: 0)
                    defaults.set(arrMusic, forKey: "saveHistory")
                    
                }else{
                    arrMusic.append(self.soundName[indexPath.row])
                    defaults.set(arrMusic, forKey: "saveHistory")
                }
            }
        
            if selectedMusicTab == 1 {
                
                
                popup.soundName = self.soundName[indexPath.row]
                
                popup.mediaItem = [mediaItems[indexPath.row]]
                
                present(popup, animated: true, completion: nil)
            }else if selectedMusicTab == 0 {
                
                popup.soundName = self.soundName[indexPath.row]
                present(popup, animated: true, completion: nil)
            }
            
        }
    }
}

extension CameraViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        dismiss(animated: true, completion: nil)
        
        guard !results.isEmpty else {
            return
        }
        
        for result in results {
            let itemProvider = result.itemProvider
            
            guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
                  let utType = UTType(typeIdentifier)
            else { continue }
            
            if utType.conforms(to: .movie) {
                self.getVideo(from: itemProvider, typeIdentifier: typeIdentifier)
            }
          
        }
    }

    
    
    private func getVideo(from itemProvider: NSItemProvider, typeIdentifier: String) {
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
                    let player = AVPlayer(url: targetURL)
                    let playerController = AVPlayerViewController()
                    playerController.player = player
                    self.present(playerController, animated: true) {
                        player.play()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeLeft
        case .landscapeRight: self = .landscapeRight
        default: return nil
        }
    }
}

extension PreviewMetalView.Rotation {
    init?(with interfaceOrientation: UIInterfaceOrientation, videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) {
        /*
         Calculate the rotation between the videoOrientation and the interfaceOrientation.
         The direction of the rotation depends upon the camera position.
         */
        switch videoOrientation {
        case .portrait:
            switch interfaceOrientation {
            case .landscapeRight:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .landscapeLeft:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .portrait:
                self = .rotate0Degrees
                
            case .portraitUpsideDown:
                self = .rotate180Degrees
                
            default: return nil
            }
        case .portraitUpsideDown:
            switch interfaceOrientation {
            case .landscapeRight:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .landscapeLeft:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .portrait:
                self = .rotate180Degrees
                
            case .portraitUpsideDown:
                self = .rotate0Degrees
                
            default: return nil
            }
            
        case .landscapeRight:
            switch interfaceOrientation {
            case .landscapeRight:
                self = .rotate0Degrees
                
            case .landscapeLeft:
                self = .rotate180Degrees
                
            case .portrait:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            case .portraitUpsideDown:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            default: return nil
            }
            
        case .landscapeLeft:
            switch interfaceOrientation {
            case .landscapeLeft:
                self = .rotate0Degrees
                
            case .landscapeRight:
                self = .rotate180Degrees
                
            case .portrait:
                if cameraPosition == .front {
                    self = .rotate90Degrees
                } else {
                    self = .rotate270Degrees
                }
                
            case .portraitUpsideDown:
                if cameraPosition == .front {
                    self = .rotate270Degrees
                } else {
                    self = .rotate90Degrees
                }
                
            default: return nil
            }
        @unknown default:
            fatalError("Unknown orientation.")
        }
    }
}
