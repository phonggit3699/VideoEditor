//
//  SettingViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 17/12/2021.
//

import UIKit
import StoreKit

class SettingViewController: UIViewController {

    let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    let saveDefaut = UserDefaults.standard
    
    @IBOutlet weak var mannualModeBtn: UIButton!
    
    @IBOutlet weak var normalModeBtn: UIButton!
    
    @IBOutlet weak var highModeBtn: UIButton!
    
    @IBOutlet weak var mediumModeBtn: UIButton!
    
    @IBOutlet weak var noticationSwitch: UISwitch!
    
    @IBOutlet weak var lowModeBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        if saveDefaut.bool(forKey: "turnOffNoti") {
            noticationSwitch.isOn = false
        }else{
            noticationSwitch.isOn = true
        }
        
        if saveDefaut.bool(forKey: "normalMode") {
            mannualModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg2"), for: .normal)
            normalModeBtn.setBackgroundImage(UIImage(named: "pinkBgBtn2"), for: .normal)
        }else{
            normalModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg2"), for: .normal)
            mannualModeBtn.setBackgroundImage(UIImage(named: "pinkBgBtn2"), for: .normal)
        }
        
        if let solutionMode = saveDefaut.string(forKey: "solutionMode") {
            switch solutionMode {
            case "hideMode":
                highModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
                mediumModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
                lowModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
            case "mediumMode":
                highModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
                mediumModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
                lowModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
            case "lowMode":
                highModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
                mediumModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
                lowModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
            default:
                highModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
                mediumModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
                lowModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
            }
        }
        // Do any additional setup after loading the view.
    }
    @IBAction func rateUs(_ sender: Any) {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    @IBAction func shareApp(_ sender: Any) {
        // Setting description
        let firstActivityItem = "Do you want to edit video now"
        
        // Setting url
        let secondActivityItem : NSURL = NSURL(string: "https://apps.apple.com/app/id1597131339")!
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem, secondActivityItem], applicationActivities: nil)
        
        // This lines is for the popover you need to show in iPad
        activityViewController.popoverPresentationController?.sourceView = (sender as! UIButton)
        
        // This line remove the arrow of the popover to show in iPad
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.down
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 150, y: 150, width: 0, height: 0)
        
        // Pre-configuring activity items
        activityViewController.activityItemsConfiguration = [
            UIActivity.ActivityType.message
        ] as? UIActivityItemsConfigurationReading
        
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.airDrop
        ]
        
        activityViewController.isModalInPresentation = true
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true)
    }
    @IBAction func showPrivacy(_ sender: Any) {
        self.openMoreSetting(setting: "privacy")
    }
    @IBAction func showAbout(_ sender: Any) {
        self.openMoreSetting(setting: "about")
        
    }
    @IBAction func changeLanguage(_ sender: Any) {
        self.openMoreSetting(setting: "language")
    }
    
    @IBAction func switchNotify(_ sender: Any) {
        if noticationSwitch.isOn {
            saveDefaut.set(false, forKey: "turnOffNoti")
            UIApplication.shared.registerForRemoteNotifications()
        }
        else{
            saveDefaut.set(true, forKey: "turnOffNoti")
            UIApplication.shared.unregisterForRemoteNotifications()
            
        }
    }
    @IBAction func mannualModeAction(_ sender: Any) {
        normalModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg2"), for: .normal)
        mannualModeBtn.setBackgroundImage(UIImage(named: "pinkBgBtn2"), for: .normal)
        saveDefaut.set(false, forKey: "normalMode")
    }
    
    @IBAction func normalModeAction(_ sender: Any) {
        mannualModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg2"), for: .normal)
        normalModeBtn.setBackgroundImage(UIImage(named: "pinkBgBtn2"), for: .normal)
        saveDefaut.set(true, forKey: "normalMode")
    }
    
    
    @IBAction func highModeAction(_ sender: Any) {
        highModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
        mediumModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
        lowModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
        saveDefaut.set("hightMode", forKey: "solutionMode")
    }
    
    @IBAction func mediumModeAction(_ sender: Any) {
        highModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
        mediumModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
        lowModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
        saveDefaut.set("mediumMode", forKey: "solutionMode")
    }
    
    @IBAction func lowModeAction(_ sender: Any) {
        highModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
        mediumModeBtn.setBackgroundImage(UIImage(named: "grayPickerBg"), for: .normal)
        lowModeBtn.setBackgroundImage(UIImage(named: "pinkbgBtn"), for: .normal)
        saveDefaut.set("lowMode", forKey: "solutionMode")
    }
    
    func openMoreSetting(setting: String) {
        let settingVC = mainStoryboard.instantiateViewController(withIdentifier: "MoreSettingVC") as! MoreSettingViewController
        
        settingVC.setting = setting
        
        present(settingVC, animated: true, completion: nil)
    }
}
