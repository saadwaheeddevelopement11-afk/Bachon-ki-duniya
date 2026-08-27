//
//  OnBoardingViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 16/03/2026.
//

import UIKit

class OnBoardingViewController: UIViewController {
    
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func continueBtn(_ sender: UIButton) {
        UserDefaults.standard.set(true, forKey: AppDefaultsKeys.hasSeenOnboarding)
        
        let loggedIn = UserDefaults.standard.bool(forKey: AppDefaultsKeys.isLoggedIn)
        AppRouter.setRoot(loggedIn ? .main : .login)
    }
}

