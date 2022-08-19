//
//  FunctionCLVCell.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 22/11/2021.
//

import UIKit

class FunctionCLVCell: UICollectionViewCell {

    @IBOutlet weak var imageFunction: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        imageFunction.layer.cornerRadius = 15
        
    }

}
