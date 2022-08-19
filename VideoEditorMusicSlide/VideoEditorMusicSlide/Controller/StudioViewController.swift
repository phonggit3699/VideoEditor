//
//  StudioViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 15/12/2021.
//

import UIKit
import Photos
import PhotosUI
import AVKit
import AVFoundation

class StudioViewController: UIViewController {
    
    typealias UIViewControllerType = PHPickerViewController

    var tabName: [String] = ["My works", "My drafts"]
    
    var works: [String] = ["work1", "work1", "work1", "work1", "work1", "work1", "work1", "work1"]
    
    var drafts:[String] = ["draft1", "draft1", "draft1", "draft1", "draft1", "draft1", "draft1", "draft1"]
    
    var tab: String = "My works"
    
    var photos: PHFetchResult<PHAsset>!
    
    @IBOutlet weak var tabCollection: UICollectionView!
    
    @IBOutlet weak var studioCollection: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tabCollection.delegate = self
        tabCollection.dataSource = self
        tabCollection.register(UINib(nibName: TabMusicCLVCell.className, bundle: nil), forCellWithReuseIdentifier: TabMusicCLVCell.className)
   
        studioCollection.delegate = self
        studioCollection.dataSource = self
        studioCollection.register(UINib(nibName: StudioCLVCell.className, bundle: nil), forCellWithReuseIdentifier: StudioCLVCell.className)
        getAssetFromPhoto()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
    }

    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection! {
        let albumName = "VideoEditorMusicSlide"
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        fetchOptions.fetchLimit = 30
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject!
        }
        
        return nil
    }
    
    func getAssetFromPhoto() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        options.fetchLimit = 30
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                if let assetCollection = self.fetchAssetCollectionForAlbum() {
                    self.photos = PHAsset.fetchKeyAssets(in: assetCollection, options: options)
                    print(self.photos.count)
                }
                else{
                    return
                }
                DispatchQueue.main.async {
                    self.studioCollection.reloadData() // reload your collectionView
                }
                
            }else {
                print("not authorized")
            }
        }
       
    }
}

extension StudioViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.studioCollection  {
            switch tab {
            case "My works":
                if photos !== nil && photos.count > 0 {
                    return photos.count
                }else {
                    return 0
                }
                
            case "My drafts":
                if photos !== nil && photos.count > 0 {
                    return photos.count
                }else {
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
       
        
        if collectionView == self.studioCollection {
            let cell = studioCollection.dequeueReusableCell(withReuseIdentifier: StudioCLVCell.className, for: indexPath) as! StudioCLVCell
            let asset = photos!.object(at: indexPath.row)
       
        
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: cell.imageVideo.frame.width, height: 145), contentMode: PHImageContentMode.aspectFit , options: nil) { (image, userInfo) -> Void in
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd-MM-yyyy hh:mm:ss"
                
                if let date = asset.creationDate {
                    cell.timeLabel.text =  dateFormatter.string(from: date)
                }
                cell.imageVideo.image = image
                
                cell.durationLB.text = String(format: "%02d:%02d",Int((asset.duration / 60)),Int(asset.duration) % 60)
            
            }
            if self.tab == "My works" {
                cell.tab = "My works"
                cell.centerImage.image = UIImage(named: "grayPlay")
            }
            else{
                cell.tab = "My drafts"
                cell.centerImage.image = UIImage(named: "sEditBtn")
            }
            return cell
        }else {
            let cell = tabCollection.dequeueReusableCell(withReuseIdentifier: TabMusicCLVCell.className, for: indexPath) as! TabMusicCLVCell
            if indexPath.row == 0 {
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
        

        
        if collectionView == self.studioCollection {
            let asset = photos!.object(at: indexPath.row)
           
            if asset.mediaType != PHAssetMediaType.video {
                print("Not a valid video media type")
                return
            }
            
            PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { avAsset, _, _ in
                let assetPhong = avAsset as! AVURLAsset
                
                DispatchQueue.main.async {
                    if self.tab == "My works" {
                        let player = AVPlayer(url: assetPhong.url)
                        let playerViewController = AVPlayerViewController()
                        playerViewController.player = player
                        player.play()
                        self.present(playerViewController, animated: true, completion: nil)
                    }
                    else {
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        
                        let editorVC = mainStoryboard.instantiateViewController(withIdentifier: "EditorVC") as! EditorViewController
                        editorVC.tab = "Filters"
                        
                        editorVC.fileURL = assetPhong.url
                        
                        self.present(editorVC, animated: true, completion: nil)
                    }
                    
                }
            }
            
        }else {

            self.tab = tabName[indexPath.row]
            self.studioCollection.reloadData()
            let resetCell = collectionView.cellForItem(at: [0, 0]) as! TabMusicCLVCell
            resetCell.TabNameLabel.textColor = UIColor.white
            resetCell.tabLine.image = nil
            let cell = collectionView.cellForItem(at: indexPath) as! TabMusicCLVCell
            cell.TabNameLabel.textColor = UIColor(named: "tab")
            cell.tabLine.image = UIImage(named: "Line 1")
        
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView == self.studioCollection {
            
            print("")
            
        }else {
            let cell = collectionView.cellForItem(at: indexPath) as! TabMusicCLVCell
            cell.TabNameLabel.textColor = UIColor.white
            cell.tabLine.image = nil
        
        }
    }
    
}

extension StudioViewController: UICollectionViewDelegateFlowLayout {
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
        if collectionView == self.studioCollection {
            if UIDevice.current.userInterfaceIdiom == .pad{
                return CGSize(width: 160, height: 170)
            }
            else if UIScreen.main.bounds.width < 376 {
                return CGSize(width: 140, height: 170)
            }else{
                return CGSize(width: 160, height: 170)
            }
        }else {
            if UIDevice.current.userInterfaceIdiom == .pad{
                return CGSize(width: 116, height: 40)
            }
            else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
                return CGSize(width: 116, height: 40)
            }else{
                return CGSize(width: 116, height: 40)
            }
        }
        
    }
}
