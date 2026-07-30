//
//  Transaction.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

struct Transaction: Identifiable {
    let id: UUID
    let amount: Decimal
    let createdAt: Date
    let clientGeneratedId: String
    let periodId: UUID
    var isDeleted: Bool = false
    var isRecurrent: Bool { recurrentFrequency != nil }
    var recurrentFrequency: RecurrentFrequency?
    var recurrentEndDate: Date?
    var subscriptionDay: Int?
    let categoryId: UUID
    let categoryName: String?
    var isCredit: Bool = false
}

enum RecurrentFrequency: String, CaseIterable {
    case DAILY, WEEKLY, BIWEEKLY, MONTHLY
}

extension RecurrentFrequency {
    var displayName: String {
        switch self {
        case .DAILY: return "Diario"
        case .WEEKLY: return "Semanal"
        case .BIWEEKLY: return "Quincenal"
        case .MONTHLY: return "Mensual"
        }
    }
}
