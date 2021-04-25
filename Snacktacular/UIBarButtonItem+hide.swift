//
//  UIBarButtonItem+hide.swift
//  Snacktacular
//
//  Created by Grace Carroll on 4/25/21.
//

import UIKit

extension UIBarButtonItem {
    func hide() {
        self.isEnabled = false
        self.tintColor = .clear
    }
}
