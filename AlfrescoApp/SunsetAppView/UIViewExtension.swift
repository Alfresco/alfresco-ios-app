//
//  UIViewExtension.swift
//  AlfrescoApp
//
//  Created by global on 23/03/22.
//  Copyright © 2022 Alfresco. All rights reserved.
//

import UIKit

// MARK: - View Extension
public extension UIView {
    static func loadFromXib<T>(withOwner: Any? = nil, options: [UINib.OptionsKey : Any]? = nil) -> T where T: UIView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: "\(self)", bundle: bundle)
        guard let view = nib.instantiate(withOwner: withOwner, options: options).first as? T else {
            fatalError("Could not load view from nib file.")
        }
        return view
    }
}
