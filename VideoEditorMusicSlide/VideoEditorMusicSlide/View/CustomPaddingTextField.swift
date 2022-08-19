//
//  CustomPaddingTextField.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 23/11/2021.
//

import UIKit

class CustomPaddingTextField: UITextField {

    let padding = UIEdgeInsets(top: 0, left: 35, bottom: 0, right: 5)
    
    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

}
