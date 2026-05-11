//
//  ProfileViewController.swift
//  Bachon ki duniya
//
//  Created by macbook pro on 12/03/2026.
//

import UIKit

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func logoutBtn(_ sender: UIButton) {
        print("Logout Pressed")
    }
    
    @IBAction func languageSelectionBtn(_ sender: UIButton) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "LanguageSelectionViewController") as? LanguageSelectionViewController {
            present(vc, animated: true)
        }
    }
    
    @IBAction func totalWatchTimeBtn(_ sender: UIButton) {
        
    }
    
    @IBAction func mostWatchedCatBtn(_ sender: UIButton) {
        
    }
}
