//
//  Destinations.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

enum Destinations: Hashable {
    case editor
    case history
    case analytics(periodId: UUID?)
    case pastPeriods
    case settings
}
