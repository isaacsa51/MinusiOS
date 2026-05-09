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
    
    init(
        id: UUID,
        amount: Double,
        createdAt: Date,
        clientGeneratedId: String,
        periodId: UUID,
        isDeleted: Bool,
        isCredit: Bool,
        categoryId: UUID
    ) {
        self.id = id
        self.amount = amount
        self.createdAt = createdAt
        self.clientGeneratedId = clientGeneratedId
        self.periodId = periodId
        self.isDeleted = isDeleted
        self.isCredit = isCredit
        self.categoryId = categoryId
    }
}
