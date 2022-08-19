//
//  EffectViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 23/11/2021.
//

import UIKit
import MTTransitions
import MetalPetal

class EffectViewController: UIViewController {
    
    @IBOutlet weak var previewEffect: MTIImageView!
    
    var tabName: [MTTransition.Effect] = MTTransition.Effect.allCases
    
    var tab: MTTransition.Effect = .none
    
    var indexPathTab: IndexPath = [0, 0]
    
    var index: Int = 1
    
    var fromImage: MTIImage!
    
    var toImage: MTIImage!
    
    @IBOutlet weak var tabCollectionview: UICollectionView!
    
    @IBOutlet weak var scrollRightTabBtn: UIButton!
    
    @IBOutlet weak var scrollLeftTabBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSubviews()
        
        previewEffect.backgroundColor = UIColor.clear
    
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollLeftTabBtn.isHidden = true
            scrollRightTabBtn.isHidden  = true
        }
        else{
            scrollLeftTabBtn.isHidden = true
        }
        
        tabCollectionview.delegate = self
        tabCollectionview.dataSource = self
        tabCollectionview.register(UINib(nibName: TabMusicCLVCell.className, bundle: nil), forCellWithReuseIdentifier: TabMusicCLVCell.className)
    }
    
    @IBAction func scrollRightTabAction(_ sender: Any) {
        let indexPath: IndexPath = [0, tabName.count - 1]
        
        tabCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        self.scrollRightTabBtn.isHidden = true
        
        self.scrollLeftTabBtn.isHidden = false
    }
    
    @IBAction func scrollLeftTabAction(_ sender: Any) {
        let indexPath: IndexPath = [0, 0]
        
        tabCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        self.scrollLeftTabBtn.isHidden = true
        
        self.scrollRightTabBtn.isHidden = false
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension EffectViewController {
    func configureSubviews() {
    
        func loadImage(named: String) -> MTIImage {
            let imageUrl = Bundle.main.url(forResource: named, withExtension: "jpg")!
            return MTIImage(contentsOf: imageUrl, options: [.SRGB: false])!.oriented(.downMirrored)
        }
        
        fromImage = loadImage(named: "wallpaper01")
        toImage = loadImage(named: "wallpaper02")
        
        previewEffect.image = toImage.oriented(.downMirrored)
    }
    
    func doTransition() {
        let transition = tab.transition
        transition.duration = 2.0
        transition.transition(from: fromImage, to: toImage, updater: { [weak self] image in
            self?.previewEffect.image = image
        }, completion: nil)
    
    }
}

extension EffectViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return tabName.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        
        let cell = tabCollectionview.dequeueReusableCell(withReuseIdentifier: TabMusicCLVCell.className, for: indexPath) as! TabMusicCLVCell
        if indexPath.row == 0  && self.tab == MTTransition.Effect.none {
            cell.TabNameLabel.textColor = UIColor(named: "tab")
            cell.tabLine.image = UIImage(named: "shortLine")
        }else {
            cell.TabNameLabel.textColor = UIColor.white
            cell.tabLine.image = nil
        }
        
        cell.TabNameLabel.text = "\(tabName[indexPath.row])"
        
        
        return cell
        
        
    }
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        return UICollectionReusableView()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.tab = tabName[indexPath.row]
        if let resetCell = collectionView.cellForItem(at: [0, 0]) as? TabMusicCLVCell {
            resetCell.TabNameLabel.textColor = UIColor.white
            resetCell.tabLine.image = nil
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! TabMusicCLVCell
        cell.TabNameLabel.textColor = UIColor(named: "tab")
        cell.tabLine.image = UIImage(named: "shortLine")
        
        doTransition()
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if let cell = collectionView.cellForItem(at: indexPath) as? TabMusicCLVCell {
            cell.TabNameLabel.textColor = UIColor.white
            cell.tabLine.image = nil
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == self.tabCollectionview {
            if indexPath.row == tabName.count - 1 {
                
                self.scrollRightTabBtn.isHidden = false
                
                self.scrollLeftTabBtn.isHidden = true
                
            }
            if indexPath.row == 0 {
                self.scrollRightTabBtn.isHidden = true
                
                self.scrollLeftTabBtn.isHidden = false
            }
        }
    }
    
}

extension EffectViewController: UICollectionViewDelegateFlowLayout {
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
        
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        label.text = "\(tabName[indexPath.row])"
        
        label.font =  UIFont(name: "OpenSans-ExtraBold", size: 14.0)
        label.numberOfLines = 0
        label.sizeToFit()
        
        if UIDevice.current.userInterfaceIdiom == .pad{
            return CGSize(width: label.frame.width + 15, height: 40)
        }
        else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
            return CGSize(width: label.frame.width + 15, height: 40)
        }else{
            return CGSize(width: label.frame.width + 15, height: 40)
        }
        
    }
}
