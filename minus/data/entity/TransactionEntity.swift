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
    var isCredit: Bool
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
        isCredit: Bool,
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
        self.isCredit = isCredit
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.recurrentFrequency = recurrentFrequency
        self.recurrentEndDate = recurrentEndDate
        self.subscriptionDay = subscriptionDay
    }
}
