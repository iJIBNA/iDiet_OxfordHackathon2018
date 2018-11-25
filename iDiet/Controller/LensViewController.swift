//
//  CameraViewController.swift
//  iDiet
//
//  Created by Franck-Stephane Ndame Mpouli on 24/11/2018.
//  Copyright © 2018 Ahmad Karkouti. All rights reserved.
//

import UIKit
import Firebase

var lensRef: LensViewController?
class LensViewController: UIViewController {
    
    // MARK: - References
    var refInsert: DatabaseReference!
    var refCurrent: DatabaseReference!
    
    var currentTarget = 0
    var currentFat = 0.0
    var currentSugar = 0.0
    var loggedIn = true
    let user = CurrentUser.shared
    
    var delegate: CaptureDelegate?
    
    // MARK: - Skeleton
    let previewView: UIView = {
        let pv = UIView()
        pv.backgroundColor = .white
        pv.layer.cornerRadius = 15
        pv.layer.shadowOffset = CGSize(width: 0, height: 10)
        pv.layer.shadowOpacity = 0.25
        pv.layer.shadowRadius = 10
        return pv
    }()
    
    let itemImage: UIImageView = {
        let ii = UIImageView()
        ii.contentMode = .scaleAspectFit
        ii.image = UIImage(named: "banana")
        ii.clipsToBounds = true
        return ii
    }()
    
    let itemTitle: UILabel = {
        let it = UILabel()
        it.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        it.textColor = .black
        it.text = "item"
        it.textAlignment = .center
        return it
    }()
    
    let itemCalories : UILabel = {
        let ic = UILabel()
        ic.textColor = .black
        ic.text = "1000"
        ic.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        return ic
    }()
    
    let itemFat : UILabel = {
        let ic = UILabel()
        ic.textColor = .black
        ic.text = "Fat: 100g"
        ic.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        return ic
    }()
    
    let itemSugar : UILabel = {
        let ic = UILabel()
        ic.textColor = .black
        ic.text = "Sugar: 10 mg"
        ic.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        return ic
    }()
    
    let cancelButton : UIButton = {
        let cb = UIButton()
        cb.setTitle("Cancel", for: .normal)
        cb.backgroundColor = .orange
        cb.layer.cornerRadius = 8
        cb.addTarget(self, action: #selector(cancelItem), for: .touchUpInside)
        return cb
    }()
    
    let addButton : UIButton = {
        let cb = UIButton()
        cb.setTitle("Add Item", for: .normal)
        cb.addTarget(self, action: #selector(addItem), for: .touchUpInside)
        cb.layer.cornerRadius = 8
        cb.backgroundColor = .orange
        return cb
    }()
    
    let foodLauncher = FoodPopUp()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previewView.isHidden = true
        lensRef = self
        captureRef?.delegate = self
        print(lensRef)
        setupView()
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        lensRef = self
        captureRef?.delegate = self
    }
    override func viewWillAppear(_ animated: Bool) {
        captureRef?.delegate = self
        guard let user = Auth.auth().currentUser else {return}
        if loggedIn == true {
            ObserveCurrent()
        }
    }
    
    // MARK: - Functions
    
    func setupView() {
        
        self.view.addSubview(previewView)
        previewView.anchor(top: nil, left: nil, right: nil, bottom: nil, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 0, width: 343, height: 462)
        previewView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        previewView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: -32).isActive = true
        
        previewView.addSubview(itemImage)
        itemImage.anchor(top: previewView.topAnchor, left: previewView.leftAnchor, right: previewView.rightAnchor, bottom: nil, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 0, width: 0, height: 150)
        
        previewView.addSubview(itemTitle)
        itemTitle.anchor(top: itemImage.bottomAnchor, left: previewView.leftAnchor, right: previewView.rightAnchor, bottom: nil, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 0, width: 0, height: 0)
        
        previewView.addSubview(itemCalories)
        itemCalories.anchor(top: itemTitle.bottomAnchor, left: previewView.leftAnchor, right: previewView.rightAnchor, bottom: nil, paddingTop: 0, paddingLeft: 16, paddingRight: 0, paddingBottom: 0, width: 0, height: 0)
        
        previewView.addSubview(itemFat)
        itemFat.anchor(top: itemCalories.bottomAnchor, left: previewView.leftAnchor, right: previewView.rightAnchor, bottom: nil, paddingTop: 0, paddingLeft: 16, paddingRight: 0, paddingBottom: 0, width: 0, height: 0)
        
        previewView.addSubview(itemSugar)
        itemSugar.anchor(top: itemFat.bottomAnchor, left: previewView.leftAnchor, right: previewView.rightAnchor, bottom: nil, paddingTop: 0, paddingLeft: 16, paddingRight: 0, paddingBottom: 0, width: 0, height: 0)
        
        previewView.addSubview(cancelButton)
        cancelButton.anchor(top: nil, left: nil, right: nil, bottom: previewView.bottomAnchor, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 32, width: 200, height: 0)
        cancelButton.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
        
        previewView.addSubview(addButton)
        addButton.anchor(top: nil, left: nil, right: nil, bottom: cancelButton.topAnchor, paddingTop: 0, paddingLeft: 0, paddingRight: 0, paddingBottom: 16, width: 200, height: 0)
        addButton.centerXAnchor.constraint(equalTo: previewView.centerXAnchor).isActive = true
        
        
    }
    
    @objc func cancelItem() {
        available = true
        print(delegate)
        delegate?.shouldRestartCapture()
        self.previewView.isHidden = true
        
    }
    
    func ObserveCurrent() {
        guard let userID = Auth.auth().currentUser else {return}
        refCurrent = Database.database().reference().child("Status").child(userID.uid)
        refCurrent.observe(.value, with: { snapshot in
            
            let value = snapshot.value as? NSDictionary
            self.currentTarget = Int(value?["Current"] as! String) ?? 0
            self.currentFat = Double(value?["Fat"] as! String) ?? 0
            self.currentSugar = Double(value?["Sugar"] as! String) ?? 0
        })
    }
    
    @objc func addItem() {
//<<<<<<< HEAD

//        print(delegate)
//=======
        available = true
        print(delegate)
//>>>>>>> 4869a2d7654e62f94146bfae16ec1665c3a06f22
        delegate?.shouldRestartCapture()
//        print(delegate)
//        print(delegate?.shouldRestartCapture())
        let toAdd = self.currentTarget + Int(self.itemCalories.text!)!
        let toAddFat = self.currentFat + Double(self.itemFat.text!)!
        let toAddSugar = self.currentSugar + Double(self.itemSugar.text!)!
        if Int(user.target ?? "0") ?? 0 >= toAdd{
        guard let userID = Auth.auth().currentUser else {return}
        refInsert = Database.database().reference().child("Status").child(userID.uid)
            self.refInsert.updateChildValues(["Current": "\(toAdd)", "Fat": "\(toAddFat)", "Sugar": "\(toAddSugar)"])
        self.previewView.isHidden = true
        } else {
            let alertController = UIAlertController(title: "Eating this item would make you go over your daily limit", message: "", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}

extension LensViewController: FoodPopupDelegate {
    func shouldAddFood() {
        available = true
        foodLauncher.handleDismissView()
    }

    func shouldCancelFood() {
        available = true
        foodLauncher.handleDismissView()
    }


}

extension LensViewController: LensDelegate {
    func foodItem(title: String, calories: String, fat: String, sugar: String) {
        foodLauncher.showMenu()
        foodLauncher.delegate = self
        available = false
        
//        self.previewView.isHidden = false
//        self.itemTitle.text = title
//        self.itemCalories.text = calories
    }
    
    
    
}
