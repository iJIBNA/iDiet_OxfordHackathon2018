//
//  ProfileViewController.swift
//  iDiet
//
//  Created by Franck-Stephane Ndame Mpouli on 24/11/2018.
//  Copyright © 2018 Ahmad Karkouti. All rights reserved.
//

import UIKit
import Firebase

class ProfileViewController: UIViewController {
    
    // MARK: - IBOUTLETS
    @IBOutlet weak var backgroundView: UIView!
    
    // MARK: - ATTRIBUTES
    var controllerColor: UIColor = UIColor(red: 0.23, green: 0.66, blue: 0.96, alpha: 1.0)
    
    // MARK: - CLASS METHODS
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.layer.cornerRadius = 0
        backgroundView.layer.masksToBounds = true
    }
    
    //MARK: - IBACTIONS
    @IBAction func handleLogoutButton(_ sender: UIButton) {
        try! Auth.auth().signOut()
        if Auth.auth().currentUser != nil {
            print("UserId: \(Auth.auth().currentUser?.uid ?? "User Not Found!")")
        } else {
            let LoginView = LoginViewController()
            present(LoginView, animated: true, completion: nil)
        }
    }
}

// MARK: - ColoredView
extension ProfileViewController: ColoredView {}
