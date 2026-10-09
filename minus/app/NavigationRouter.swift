//
//  NavigationRouter.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import SwiftUI
import AVRouting

struct PendingEditTransaction: Equatable {
    let id: UUID
    let amount: Double
    let categoryName: String?
    let date: Date
    let isIncome: Bool
    let extraNote: String?
}

@Observable
class NavigationRouter {
    var path = NavigationPath()

    var pendingEditTransaction: PendingEditTransaction?
    var shouldPresentNewBudgetSheet = false

    func navigate(to destination: Destinations) {
        path.append(destination)
    }

    func pop() { path.removeLast() }

    func popToRoot() { path = NavigationPath() }
}
