//
//  Extensions.swift
//  AudioVisulizer
//
//  Created by Meet Budheliya on 08/03/24.
//

import UIKit

var activityIndicator = UIActivityIndicatorView()

//MARK: - UIViewController
extension UIViewController {
    

    // Loader start and stop
    func loadingStart(){
        activityIndicator.frame = CGRectMake(0, 0, 40, 40)
        activityIndicator.style = .medium
        activityIndicator.color = .black
        activityIndicator.center = CGPointMake(self.view.bounds.width / 2, self.view.bounds.height / 2)
        self.view.addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
    }
    
    func loadingStop(){
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
}
