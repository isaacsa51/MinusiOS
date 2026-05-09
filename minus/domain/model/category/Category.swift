//
//  Category.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

struct Category: Identifiable {
    let id: UUID
    let name: String?
    let isHidden: Bool = false
    let usageCount: Int = 0
    let lastUsedAt: Date?
    let createdAt: Date
}
