//
//  UIViewController+alert.swift
//  ToDoList
//
//  Created by Grace Carroll on 3/8/21.
//

import UIKit

extension UIViewController {
    
    func oneButtonAlert(title: String, message: String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
