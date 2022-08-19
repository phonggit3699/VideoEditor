//
//  StudioCLVCell.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 16/12/2021.
//

import UIKit

class StudioCLVCell: UICollectionViewCell {
    
    var tab: String = ""
    
    @IBOutlet weak var centerImage: UIImageView!
    
    @IBOutlet weak var imageVideo: UIImageView!
    
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var optionBtn: UIButton!
    
    @IBOutlet weak var durationLB: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    
    @IBAction func centerBtnAction(_ sender: Any) {
        if tab == "My works" {
            print("work")
        }
        else{
            print("draft")
        }
    }
}
