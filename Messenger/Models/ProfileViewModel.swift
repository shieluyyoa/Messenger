//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Oscar Lui on 22/7/2022.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
    
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
    
}
