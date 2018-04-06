//
//  UserViewController.swift
//  RecreateDemoCells
//
//  Created by C4Q on 4/4/18.
//  Copyright © 2018 Glo. All rights reserved.
//

import UIKit
import Firebase
import expanding_collection

class UserViewController: ExpandingViewController {
    
    
    fileprivate var cellsIsOpen = [Bool]()
//    typealias ItemInfo = (image: String, title: String)
//    fileprivate let items: [ItemInfo] = [(#imageLiteral(resourceName: "bg_food1"), "Hi there")]
    fileprivate let favoritePlates = ["Chili","Pizza", "Chinese", "Tacos", "Sushi", "Bacon", "French Fries"]
    
    var currentLover: Lover!
    
    var currentFoods: [String]!
    
    var lovers = [Lover]() {
        didSet {
            fillCellIsOpenArray()
            self.collectionView?.reloadData()
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        if Auth.auth().currentUser == nil {
            let welcomeVC = UIViewController.storyboardInstance(storyboardName: "Main", viewControllerIdentifiier: "WelcomeController")
            if let window = UIApplication.shared.delegate?.window {
                window?.rootViewController = welcomeVC
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        itemSize = CGSize(width: 256, height: 460)
        //        itemSize = CGSize(width: 350, height: 550)
        super.viewDidLoad()
        registerCell()
        configureNavBar()
        addGesture(to: collectionView!)
        //        fillCellIsOpenArray()
        loadCurrentUser()
        //        getAllLoversExceptCurrent()
        fetchLovers()
        
    }
    
    func getAllLoversExceptCurrent() {
        var loverArr = [Lover]()
        Database.database().reference().child("lovers").observe(.childAdded, with: { (snapshot) in
            if let dict = snapshot.value as? [String: AnyObject]{
                let lover = Lover(dictionary: dict)
                lover.id = snapshot.key
                if lover.id != Auth.auth().currentUser?.uid {
                    loverArr.append(lover)
                }
            }
        }, withCancel: nil)
        self.lovers = loverArr
    }
    
    private func fetchLovers() {
        var loverArr = [Lover]()
        let loverRef = Database.database().reference().child("lovers")
        loverRef.observe(.value) { (snapshot) in
            for child in snapshot.children {
                let childDAtaSnapshot = child as! DataSnapshot
                if let dict = childDAtaSnapshot.value as? [String: AnyObject] {
                    let newLover = Lover(dictionary: dict)
                    loverArr.append(newLover)
                }
            }
            self.lovers = loverArr.filter{$0.gender == "Male"}
        }
    }
    
    
    
    func loadCurrentUser() {
        DBService.manager.getCurrentLover { (onlineLover, error) in
            if let lover = onlineLover {
                self.currentLover = lover
            }
            if let error = error {
                print("loading current user error: \(error)")
            }
        }
    }
    
    
}

//MARK: Helpers
extension UserViewController {
    fileprivate func registerCell() {
        let nib = UINib(nibName: String(describing: UserProfileCollectionViewCell.self), bundle: nil)
        collectionView?.register(nib, forCellWithReuseIdentifier: String(describing: UserProfileCollectionViewCell.self))
    }
    
    fileprivate func fillCellIsOpenArray() {
        if cellsIsOpen.isEmpty {
            cellsIsOpen = Array(repeating: false, count: lovers.count)
        }
    }
    
    fileprivate func getViewController() -> ExpandingTableViewController {
        let storyB = UIStoryboard(name: "NewDiscover", bundle: nil)
        let toViewController: UserDetailTableViewController = storyB.instantiateViewController()
        toViewController.lover = lovers[currentIndex]
        toViewController.currentFoods = currentFoods
        return toViewController
    }
    
    fileprivate func configureNavBar() {
        navigationItem.leftBarButtonItem?.image = navigationItem.leftBarButtonItem?.image!.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
    }
    
}

//MARK: Gestures
extension UserViewController {
    
    fileprivate func addGesture(to view: UIView) {
        let upGesture = Init(UISwipeGestureRecognizer(target: self, action: #selector(UserViewController.swipeHandler(_:)))) {
            $0.direction = .up
        }
        
        let downGesture = Init(UISwipeGestureRecognizer(target: self, action: #selector(UserViewController.swipeHandler(_:)))) {
            $0.direction = .down
        }
        view.addGestureRecognizer(upGesture)
        view.addGestureRecognizer(downGesture)
    }
    
    @objc func swipeHandler(_ sender: UISwipeGestureRecognizer) {
        let indexPath = IndexPath(row: currentIndex, section: 0)
        guard let cell = collectionView?.cellForItem(at: indexPath) as? UserProfileCollectionViewCell else { return }
        
        
        if sender.direction == .down {
            cell.overlayView.isHidden = false
            cell.customTitle.isHidden = false
            cell.backgroundImageView.contentMode = .scaleToFill
            
        }
        
        if cell.isOpened == false && sender.direction == .down {
            cell.backgroundImageView.contentMode = .scaleToFill
            cell.overlayView.isHidden = false
            cell.customTitle.isHidden = false
        }
        
        // double swipe Up transition
        if cell.isOpened == true && sender.direction == .up {
            cell.backgroundImageView.contentMode = .scaleAspectFit
            cell.customTitle.isHidden = true
            cell.overlayView.isHidden = true
            pushToViewController(getViewController())
            
            
            
            
            if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(true)
            }
        }
        
        let open = sender.direction == .up ? true : false
        cell.cellIsOpen(open)
        cellsIsOpen[indexPath.row] = cell.isOpened
        //        cell.backgroundImageView.contentMode = .scaleAspectFit
        //        cell.customTitle.isHidden = true
        
    }
    
    
    
}


//MARK: UICollectionView DataSource
extension UserViewController {
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
        guard let cell = cell as? UserProfileCollectionViewCell else { return }
        
        //        let index = indexPath.row % lovers.count
        //        let lover = lovers[index]
        
        let index = indexPath.row % lovers.count
        let lover = lovers[index]
       
        
        //        cell.backgroundImageView.image = nil
        //        cell.favFoodImageView.image = nil
        cell.customTitle.text = lover.name
//        cell.favoriteFoodNameLabel.text = lover.favDish
        
        let currentLoverFoods = [currentLover.firstFoodPrefer, currentLover.secondFoodPrefer, currentLover.thirdFoodPrefer]
        let loverFoods = [lover.firstFoodPrefer, lover.secondFoodPrefer, lover.thirdFoodPrefer]
        var common = [String]()
        
        for option in currentLoverFoods where option != nil {
            if loverFoods.contains(where: {$0 == option}) {
                common.append(option!)
            }
        }
        self.currentFoods = common
        cell.favoriteCuisinesLabel.text = common.joined(separator: ", ")
        
        if let image = lover.profileImageUrl {
            cell.backgroundImageView.loadImageUsingCacheWithUrlString(image)
        } else {
            cell.backgroundImageView.image = #imageLiteral(resourceName: "profile")
        }
        if let image = lover.favDishImageUrl {
            cell.favFoodImageView.loadImageUsingCacheWithUrlString(image)
        } else {
            let indexFavPlate = Int(arc4random() % UInt32(favoritePlates.count))
            cell.favFoodImageView.image = UIImage(named: favoritePlates[indexFavPlate])
            cell.favoriteFoodNameLabel.text = favoritePlates[indexFavPlate]
            lovers[index].favDish = favoritePlates[indexFavPlate]
        }
        
        cell.cellIsOpen(cellsIsOpen[index], animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? UserProfileCollectionViewCell
            , currentIndex == indexPath.row else { return }
        
        if !cell.isOpened  {
            cell.cellIsOpen(true)
            //            cell.customTitle.isHidden = false
            
        }
            
        else {
    
            pushToViewController(getViewController())
            
            
            
            if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(true)
            }
        }
    }
}


extension UserViewController {
    
    override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return lovers.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        //        let lover = lovers[indexPath.row]
        //        guard let cell = collectionView.cellForItem(at: indexPath) as? UserProfileCollectionViewCell else { return UICollectionViewCell() }
        //        cell.backgroundImageView.image = nil
        //        cell.layoutSubviews()
        //        cell.customTitle.text = "\(lover.name)"
        //        cell.favFoodImageView.image = nil
        //        cell.favoriteFoodNameLabel.text = lover.favDish
        //        let currentLoverFoods = [currentLover.firstFoodPrefer, currentLover.secondFoodPrefer, currentLover.thirdFoodPrefer]
        //        let loverFoods = [lover.firstFoodPrefer, lover.secondFoodPrefer, lover.thirdFoodPrefer]
        //        var common = [String]()
        //
        //        for option in currentLoverFoods where option != nil {
        //            if loverFoods.contains(where: {$0 == option}) {
        //                common.append(option!)
        //            }
        //        }
        //        cell.favoriteCuisinesLabel.text = common.joined(separator: ", ")
        //
        //        if let image = lover.profileImageUrl {
        //            cell.backgroundImageView.loadImageUsingCacheWithUrlString(image)
        //        } else {
        //            cell.backgroundImageView.image = #imageLiteral(resourceName: "profile")
        //        }
        //        if let image = lover.favDishImageUrl {
        //            cell.favFoodImageView.loadImageUsingCacheWithUrlString(image)
        //        } else {
        //            cell.favFoodImageView.image = #imageLiteral(resourceName: "profile")
        //        }
        //        return cell
        //
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: UserProfileCollectionViewCell.self), for: indexPath)
    }
}



//let lover = lovers[indexPath.row]
//let cell = self.collectionView?.dequeueReusableCell(withReuseIdentifier: "NewDiscoverCell", for: indexPath) as! NewDiscoverCollectionViewCell
//cell.userImageView.image = nil
//cell.layoutSubviews()
//cell.userNameLabel.text = "\(lover.name)"
//cell.favoriteFoodImageView.image = nil
//cell.favoriteFoodLabel.text = lover.favDish
//let currentLoverFoods = [currentLover.firstFoodPrefer, currentLover.secondFoodPrefer, currentLover.thirdFoodPrefer]
//let loverFoods = [lover.firstFoodPrefer, lover.secondFoodPrefer, lover.thirdFoodPrefer]
//var common = [String]()
//
//for option in currentLoverFoods where option != nil {
//    if loverFoods.contains(where: {$0 == option}) {
//        common.append(option!)
//    }
//}
//cell.favoriteCuisinesLabel.text = common.joined(separator: ", ")
//
//if let image = lover.profileImageUrl {
//    cell.userImageView.loadImageUsingCacheWithUrlString(image)
//} else {
//    cell.userImageView.image = #imageLiteral(resourceName: "profile")
//}
//if let image = lover.favDishImageUrl {
//    cell.favoriteFoodImageView.loadImageUsingCacheWithUrlString(image)
//} else {
//    cell.favoriteFoodImageView.image = #imageLiteral(resourceName: "profile")
//}
//return cell


