//
//  CurrencyInputFormatter.swift
//  minus
//

import Foundation

/// Formats raw numeric input into currency display strings.
/// Handles grouping separators (e.g. "4250" → "4,250") and decimal input.
enum CurrencyInputFormatter {

    /// Formats a raw numeric string (e.g. "4250.5") into a display string with
    /// grouping separators (e.g. "4,250.5"). Preserves trailing dot and
    /// partial decimals for live typing.
    static func format(_ raw: String) -> String {
        guard !raw.isEmpty, raw != "0" else { return "0" }

        let parts = raw.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        let integerPart = String(parts[0])
        let decimalPart: String? = parts.count > 1 ? String(parts[1]) : nil

        let formattedInteger = formatIntegerPart(integerPart)

        if let decimals = decimalPart {
            return "\(formattedInteger).\(decimals)"
        } else if raw.hasSuffix(".") {
            return "\(formattedInteger)."
        }
        return formattedInteger
    }

    /// Formats a raw numeric string with a currency symbol prefix.
    static func formatWithSymbol(_ raw: String, symbol: String = "$") -> String {
        let formatted = format(raw)
        return "\(symbol)\(formatted)"
    }

    /// Strips grouping separators from a formatted string back to raw digits + decimal.
    static func stripFormatting(_ formatted: String) -> String {
        let stripped = formatted.replacingOccurrences(of: ",", with: "")

        // Only allow digits and a single decimal point
        var result = ""
        var hasDecimal = false
        for char in stripped {
            if char.isNumber {
                result.append(char)
            } else if char == "." && !hasDecimal {
                hasDecimal = true
                result.append(char)
            }
        }
        return result.isEmpty ? "0" : result
    }

    // MARK: - Private

    private static func formatIntegerPart(_ value: String) -> String {
        // Remove leading zeros
        let cleaned = String(value.drop { $0 == "0" })
        guard !cleaned.isEmpty else { return "0" }

        guard let number = Int64(cleaned) else { return cleaned }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSNumber(value: number)) ?? cleaned
    }
}
