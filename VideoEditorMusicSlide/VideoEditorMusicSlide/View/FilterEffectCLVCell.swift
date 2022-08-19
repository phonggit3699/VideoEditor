//
//  FilterEffectCLVCell.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 23/11/2021.
//

import UIKit

class FilterEffectCLVCell: UICollectionViewCell {

    @IBOutlet weak var nameFilter: UILabel!
    @IBOutlet weak var imageFilter: UIImageView!
    
    @IBOutlet weak var dowloadBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        dowloadBtn.isHidden = true
    }
    @IBAction func downloadAction(_ sender: Any) {
        print("download")
    }
    
}
