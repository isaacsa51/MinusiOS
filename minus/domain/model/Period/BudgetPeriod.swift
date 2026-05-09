//
//  BudgetPeriod.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

enum BudgetPeriod{
    case DAILY, WEEKLY, BIWEEKLY, MONTHLY
}

enum RemainingBudgetStrategy {
    case ASK_ALWAYS, SPLIT_EQUALLY, ADD_TO_FIRST_DAY
}

struct BudgetSettings {
    var totalBudget: Decimal
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date? = nil
    var currency: String = "USD"
    var daysInPeriod: Int = 1
    var rollOverEnabled: Bool = false
    var rollOverLimit: Decimal? = nil
    var rollOverCarryForward: Bool = false
    var remainingBudgetStrategy: RemainingBudgetStrategy = .ASK_ALWAYS
    var creditCardCutOff: Int? = nil
    
    func getDaysForPeriod() -> Int {
        let baseDays: Int
        
        switch period {
            case .DAILY: baseDays = 1
            case .WEEKLY: baseDays = 7
            case .BIWEEKLY: baseDays = 14
            case .MONTHLY: baseDays = 30
        }
        
        return Swift.max(baseDays, daysInPeriod)
    }
    
    func calculateDailyBudget() -> Decimal {
        let days = getDaysForPeriod()
        
        if days > 0 {
            let result = totalBudget / Decimal(days)
            var roundedResult = Decimal()
            var mutableResult = result
            
            NSDecimalRound(&roundedResult, &mutableResult, 2, .plain)
            return roundedResult
        } else {
            return totalBudget
        }
    }
    
    func getPeriodEndDate() -> Date {
        if let endDate = endDate {
            return endDate
        }
        
        let daysToAdd = getDaysForPeriod() - 1
        
        return Calendar.current.date(byAdding: .day, value: daysToAdd, to: startDate) ?? startDate
    }
    
    static let `default` = BudgetSettings(
        totalBudget: .zero,
        period: .DAILY,
        startDate: Date()
    )
}
