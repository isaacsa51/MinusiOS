//
//  Transaction.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

struct Transaction: Identifiable {
    let id: UUID
    let amount: Double
    let createdAt: Date
    let clientGeneratedId: String
    let periodId: UUID
    var isDeleted: Bool = false
    var isRecurrent: Bool { recurrentFrequency != nil }
    var recurrentFrequency: RecurrentFrequency?
    var recurrentEndDate: Date?
    var subscriptionDay: Int?
    let categoryId: UUID
    var isCredit: Bool = false
}

enum RecurrentFrequency {
    case WEEKLY, BIWEEKLY, DAILY
}
