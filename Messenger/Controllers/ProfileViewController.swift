//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Oscar Lui on 8/4/2022.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import RealmSwift




final class ProfileViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var data = [ProfileViewModel]()
    
    private var logInObserver: NSObjectProtocol?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")" ,
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")" ,
                                     handler: nil))

        data.append(ProfileViewModel(viewModelType: .logout,
                                     title: "Log out",
                                     handler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            let alert = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "Log Out",
                                          style: .destructive,
                                          handler: { [weak self] _ in
                guard let strongself = self else {
                    return
                }
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                // Facebook Log out
                FBSDKLoginKit.LoginManager().logOut()
                
                // Google Log out
                GIDSignIn.sharedInstance.signOut()
                
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController:vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongself.present(nav,animated: true)
                }
                catch {
                    print("Failed to log out")
                }
                
           
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            strongSelf.present(alert, animated: true)
            
        }))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier:"cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        
        logInObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: {
            [weak self] _ in
            
            print("observer working")
            guard let strongSelf = self else {
                return
            }
            
            
            strongSelf.data[0] = ProfileViewModel(viewModelType: .info,
                                         title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")" ,
                                         handler: nil)
            strongSelf.data[1] = ProfileViewModel(viewModelType: .info,
                                         title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")" ,
                                         handler: nil)
            strongSelf.tableView.tableHeaderView = strongSelf.createTableHeader()
            strongSelf.tableView.reloadData()
        })
        
    }
    
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let filename = safeEmail + "_profile_picture.png"
        let path = "images/"+filename
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .link
        let imageView = UIImageView(frame: CGRect(x: (view.width-150)/2, y: 75, width: 150, height: 150))
        
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(for: path, completion: {  result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    imageView.sd_setImage(with: url)
                }
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        })
        
        return headerView
        
    }
    
  


}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        
        cell.setUp(with: viewModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        data[indexPath.row].handler?()
        
    }
        
        
   
    
    
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    
    func setUp(with viewModel: ProfileViewModel) {
        textLabel?.text = viewModel.title
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
        
    }
}
