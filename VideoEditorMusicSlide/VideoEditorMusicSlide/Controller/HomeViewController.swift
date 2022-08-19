//
//  HomeViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 22/11/2021.
//

import UIKit

class HomeViewController: UIViewController {
    
    var imageNames: [String] = ["cameraBtn", "effectsBtn", "trimBtn", "studioBtn"]
    
    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

    @IBOutlet weak var ImageShow: UIImageView!
    
    @IBOutlet weak var selectLanguageBtn: UIButton!
    
    @IBOutlet weak var functionCollection: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Setup corner
        ImageShow.layer.cornerRadius = 15
        
        if UIDevice.current.userInterfaceIdiom == .pad{
            NSLayoutConstraint(item: ImageShow!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 400).isActive = true
            
        }
        else{
            NSLayoutConstraint(item: ImageShow!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: 181).isActive = true
        }
        
        functionCollection.delegate = self
        functionCollection.dataSource = self
    
        functionCollection.register(UINib(nibName: FunctionCLVCell.className, bundle: nil), forCellWithReuseIdentifier: FunctionCLVCell.className)
        
        ImageShow.image = UIImage(named: "ex")
    }
   
    
    @IBAction func openSetting(_ sender: Any) {
        let settingVC = mainStoryboard.instantiateViewController(withIdentifier: "SettingVC")
        
        present(settingVC, animated: true, completion: nil)
    }
    @IBAction func OpenEditorController(_ sender: Any) {
        let editorVC = mainStoryboard.instantiateViewController(withIdentifier: "EditorVC")
        
        present(editorVC, animated: true, completion: nil)
    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = functionCollection.dequeueReusableCell(withReuseIdentifier: FunctionCLVCell.className, for: indexPath) as! FunctionCLVCell
        
        cell.imageFunction.image = UIImage(named: imageNames[indexPath.row])
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        return UICollectionReusableView()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            let cameraVC = mainStoryboard.instantiateViewController(withIdentifier: "CameraVC")
            
            present(cameraVC, animated: true, completion: nil)
        case 1:
            let effectVC = mainStoryboard.instantiateViewController(withIdentifier: "EffectVC")
            
            present(effectVC, animated: true, completion: nil)
        case 2:
            let trimVC = mainStoryboard.instantiateViewController(withIdentifier: "TrimVC")
            
            present(trimVC, animated: true, completion: nil)
        case 3:
            let studioVC = mainStoryboard.instantiateViewController(withIdentifier: "StudioVC")
            
            present(studioVC, animated: true, completion: nil)
        default:
            dismiss(animated: true)
            
        }
    
    }
    
}


extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.userInterfaceIdiom == .pad{
            if UIScreen.main.bounds.width > 1000 {
                return CGSize(width: 200, height: 95)
            }
            return CGSize(width: 166, height: 95)
        }
        else if UIScreen.main.bounds.width > 375 && UIScreen.main.bounds.width < 415 {
            return CGSize(width: 184, height: 95)
        }else{
            return CGSize(width: 166, height: 95)
        }
    }
}
