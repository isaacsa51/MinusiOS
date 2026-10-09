//
//  BudgetFormulaBreakdown.swift
//  minus
//

import Foundation

/// One row of the "How it's calculated" ledger. Amounts arrive already
/// formatted — the view model owns the period's currency symbol.
struct BudgetFormulaLine: Identifiable {
    enum Sign {
        case none, plus, minus, equals

        var symbol: String {
            switch self {
            case .none: return ""
            case .plus: return "+"
            case .minus: return "\u{2212}" // real minus sign, not a hyphen
            case .equals: return "="
            }
        }
    }

    /// Labels are unique within a section, so they double as the ForEach id.
    var id: String { label }
    let label: String
    let amount: String
    var sign: Sign = .none
}

/// Everything the formula sheet renders, resolved against the active period's
/// real numbers. Sections with nothing to say come through empty and the sheet
/// hides them.
struct BudgetFormulaBreakdown {
    /// The two settings the numbers below depend on, e.g. "Spread across all days · Daily".
    let subtitle: String

    /// The running subtraction that produces the fraction's numerator.
    let poolLines: [BudgetFormulaLine]
    let numerator: String
    let denominator: String
    let dailyRate: String

    /// Per-charge detail behind the "set aside" line in `poolLines`. Empty when
    /// the reserve preference is off or nothing is due.
    let reservedCharges: [ReservedChargeRow]
    let reservedTotal: String

    /// How the daily amount turns into the number on the pill.
    let leftLines: [BudgetFormulaLine]
    let total: String
    /// Set only when `total` came out negative — says which way it went.
    let shortfallNote: String?
}
