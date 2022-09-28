//
//  LoginViewController.swift
//  Messenger
//
//  Created by Oscar Lui on 8/4/2022.
//

import UIKit
import Firebase
import FBSDKLoginKit
import FirebaseAuth
import GoogleSignIn
import JGProgressHUD
import SwiftUI

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        button.removeConstraints(button.constraints)
        return button
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named:"logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField:UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = . no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()

        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20,weight: .bold)
        return button
    }()
    
    private let passwordField:UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = . no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let googleLogInButton:GIDSignInButton = {
        let button = GIDSignInButton()
        button.colorScheme = .dark
        button.style = .wide
        return button
    }()

    
    private let signInTextLabl: UILabel = {
        let label = UILabel()
        label.text = "Or sign in with"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        googleLogInButton.addTarget(self, action: #selector(googleLogInButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        
        
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogInButton)
        scrollView.addSubview(signInTextLabl)
            
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        
        loginButton.frame = CGRect(x: 70, y: passwordField.bottom+30, width: scrollView.width-140, height: 45)
        
        
        signInTextLabl.frame = CGRect(x: 90, y: loginButton.bottom+20, width: scrollView.width-180, height: 20)
        
        facebookLoginButton.frame = CGRect(x:75, y: signInTextLabl.bottom+20, width: scrollView.width-150, height: 40)
        
        googleLogInButton.frame = CGRect(x:70, y: facebookLoginButton.bottom+10, width: scrollView.width-140,height:52)
        
        
       
       
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text , let password = passwordField.text , !email.isEmpty, !password.isEmpty ,password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: scrollView)
        // Firebase Log in
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult,error in
            
            
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
                
            }
            
            guard let result = authResult,error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: {
                result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String:Any],
                          let firstName = userData["first_name"],
                          let lastName = userData["last_name"]
                    
                    else {
                        print("data fetching fail")
                        return
                    }
                    
                    UserDefaults.standard.setValue("\(firstName) \(lastName)",forKey: "name")
                    UserDefaults.standard.setValue(email,forKey: "email")
                    print("\(UserDefaults.standard.object(forKey: "name"))")
                    print("\(UserDefaults.standard.object(forKey: "email"))")
                    NotificationCenter.default.post(name: .didLogInNotification, object: nil)

                case .failure(let error):
                    print("Failed to read data with error \(error)")
                }
        })
                        
            
            print("Logged In User : \(user)")
            
           strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        })
    }
    
    @objc private func googleLogInButtonTapped() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)

        // Start the sign in flow!
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in

          if let error = error {
            print("error occrued:\(error)")
            return
          }
            
            print("Signed in with google")
            
            
            
            guard let profile = user?.profile,
                  let email = user?.profile?.email,
                  let firstName = user?.profile?.givenName,
                  let lastName = user?.profile?.familyName
            else {
                return
                  }
            
            UserDefaults.standard.set(email,forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
            
            print(email)
            
            DatabaseManager.shared.userExists(with: email, completeion: {
                exist in
                if !exist {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: {
                        success in
                        if success {
                            // upload image
                            if profile.hasImage {
                                guard let url = user?.profile?.imageURL(withDimension: 200) else {
                                    return
                                }

                                URLSession.shared.dataTask(with: url, completionHandler: {
                                    data,_,_ in
                                    guard let data = data else {
                                        return
                                    }
                                    let fileName = chatUser.profilePictureFileName
                                    StorageManager.shared.uploadProfilePicture(with: data, fileName:fileName, completion: {
                                        result in
                                        switch result {
                                        case .success(let downloadUrl):
                                            UserDefaults.standard.set(downloadUrl,forKey: "profile_picture_url")
                                            print(downloadUrl)
                                        case .failure(let error):
                                            print("Storage manager error: \(error)")
                                        }
                                    })

                                }).resume()

                            }


                    }
                })
              }
            })
          guard
            let authentication = user?.authentication,
            let idToken = authentication.idToken
          else {
              
            print("Missing auth object off of google user")
            return
          }

        let credential = GoogleAuthProvider.credential(withIDToken: idToken,accessToken: authentication.accessToken)
        
            
        Firebase.Auth.auth().signIn(with: credential, completion: { authResult, error in
            
            guard authResult != nil , error == nil else {
                print("failed to log in with google credential")
                return
            }
            
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            print("Successfully signed in with Google cred")
            print("Successfully logged in")
            
            self.navigationController?.dismiss(animated: true, completion: nil)
        })
        }
        
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all information to log in", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert,animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)

    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
        
    }
}


extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        // unwrap the token from facebook
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        
        // request from facebook to get email and name
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath:  "me",
                                                         parameters: ["fields": "email,first_name,last_name,picture.tyoe(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: {
            _,result,error in
            guard let result = result as? [String:Any], error == nil else {
                print("Failed to make facebook graph request")
                return
                
            }
            
            print("result:\(result)")
            
          
            // unwrap the requested data
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any] ,
                  let data = picture["data"] as?[String:Any],
                  let pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from fb result")
                return
            }
            
            UserDefaults.standard.set(email,forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)",forKey: "name")
            
            //check if email exists in firebase,if it doesnt , insert it in the database
            DatabaseManager.shared.userExists(with: email, completeion: {
                exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser, completion: {
                        success in
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            URLSession.shared.dataTask(with: url, completionHandler:{ data, _ , _ in
                                guard let data = data else {
                                    return
                                }
                                
                                print("got data from FB, uploading")
                                // upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName:fileName, completion: {
                                    result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl,forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                                
                            }).resume()
                        }
                    })
                }
            })
            
            
            // use the crediential from facebook to sign user in
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self]  authResult, error in
                guard let strongSelf = self else {
                    return
                    
                }
                guard authResult != nil , error == nil else {
                    if let error = error {
                        print("Facebook credential login failed , MFA may be needed - \(error)")
                    }
                   
                    return
                }
                
                print("Successfully logged in")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            })
            
        })
        
        
      
        
    }
    
}
