//
//  TransactionEntity.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation
import SwiftData

@Model
class TransactionEntity {
   // @attribute(.unique) it's the equal to @PrimaryKey on Room
    @Attribute(.unique) var id: UUID
    var amount: Double
    var createdAt: Date
    var clientGeneratedId: String
    var periodId: UUID
    var isDeleted: Bool
    @Attribute(originalName: "isCredit") var isIncome: Bool
    var isCreditCardCharge: Bool = false
    var isCreditCardPaid: Bool = false
    var categoryId: UUID
    var categoryName: String?
    var recurrentFrequency: String?
    var recurrentEndDate: Date?
    var subscriptionDay: Int?

    init(
        id: UUID,
        amount: Double,
        createdAt: Date,
        clientGeneratedId: String,
        periodId: UUID,
        isDeleted: Bool,
        isIncome: Bool,
        isCreditCardCharge: Bool = false,
        isCreditCardPaid: Bool = false,
        categoryId: UUID,
        categoryName: String? = nil,
        recurrentFrequency: String? = nil,
        recurrentEndDate: Date? = nil,
        subscriptionDay: Int? = nil
    ) {
        self.id = id
        self.amount = amount
        self.createdAt = createdAt
        self.clientGeneratedId = clientGeneratedId
        self.periodId = periodId
        self.isDeleted = isDeleted
        self.isIncome = isIncome
        self.isCreditCardCharge = isCreditCardCharge
        self.isCreditCardPaid = isCreditCardPaid
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.recurrentFrequency = recurrentFrequency
        self.recurrentEndDate = recurrentEndDate
        self.subscriptionDay = subscriptionDay
    }
}
