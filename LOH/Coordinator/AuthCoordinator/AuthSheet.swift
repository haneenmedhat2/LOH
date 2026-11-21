//
//  AuthSheet.swift
//  CTF
//
//  Created by Mohamed Hadwa on 18/11/2025.
//

import Foundation

enum AuthModalRoute: Identifiable {
    case language
    
    var id: String {
        String(describing: self)
    }
}
