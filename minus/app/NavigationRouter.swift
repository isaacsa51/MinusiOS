//
//  NavigationRouter.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI
import AVRouting

@Observable
class NavigationRouter {
    var path = NavigationPath()
    
    func navigate(to destination: Destinations) {
        path.append(destination)
    }
    
    func pop() { path.removeLast() }
    
    func popToRoot() { path = NavigationPath() }
}
