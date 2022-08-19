//
//  MoreSettingViewController.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 17/12/2021.
//

import UIKit

class MoreSettingViewController: UIViewController {

    var setting: String = ""
    
    @IBOutlet weak var viewTitle: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var selectLanguageBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        switch setting {
        case "language":
            viewTitle.text = "LANGUAGE SETTINGS"
            textView.isHidden = true
            selectLanguageBtn.isHidden = false
        case "privacy":
            viewTitle.text = "PRIVACY POLICY"
            textView.isHidden = false
            selectLanguageBtn.isHidden = true
            textView.text = privacyPolicy
        case "about":
            viewTitle.text = "ABOUT US"
            textView.isHidden = false
            selectLanguageBtn.isHidden = true
            textView.text = aboutUs
        default:
            viewTitle.text = "SETTINGS"
        }
        
    }
    
    @IBAction func SelectEnglishLanguage(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

var privacyPolicy: String = """
GENERAL

Video Editor Music Slide has adopted this privacy policy (“Privacy Policy”) to explain how we collect, use and share information. By using or accessing our mobile applications, website or tools (“Services”), you agree to the terms of this Privacy Policy. Mathman reserves the right to modify this Privacy Policy at reasonable times, so please review it frequently. Your continued use of Services will signify your acceptance of the changes to this Privacy Policy.

Personal data

Personal data (“Personal Data”) is any information that that specifically identifies you as an individual.

We collect Personal Data to a minimal possible extent which includes only device ID and related information to a device necessary for the successful operation of our Services. We do not collect and store IP-address, age, name, etc.

Automatically Collected Information

Application may collect certain information automatically, including, but not limited to, the type of mobile device you use, your mobile devices unique device ID, the IP address of your mobile device, your mobile operating system, the type of mobile Internet browsers you use, and information about the way you use the Application.

Other information

The Other Information we process may include, but is not limited to technical information, such as information about your device, your browser type, screen resolution, device type, language, version and type of operating system, SDK version, API key, application version, geo location, levels achieved, in-app purchases.

Purpose of storing the data

Mathman may use or share data collected through the Services for purposes such as understanding or improving our Services.

Our Third Party Service Providers

We cannot provide all services necessary for the successful operation of our Apps by ourselves. We therefore share collected Information with our Providers. When using the Third Party Services, you adhere to their data processing practices.

You recognize and agree that Mathman is not liable for the Third Party Service Provider’s terms and conditions and their use of your Information.

"""

var aboutUs: String = """
Devsenior founded in 2020 by MRSONPRO, Devsenior is one of the startup companies specializing in developing applications on two operating systems iOS ...

We are a passionate group to create affecting people's lives by creating IT products that they like to use for everyday life. We like to work with new technology and demonstrate a full commitment to agile workflow for a streamlined organization.

We are product oriented, not only committed to user-friendly applications but also work with high quality code for sustainable development.
"""
