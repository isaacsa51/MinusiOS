//
//  CurrencyInputFormatter.swift
//  minus
//

import Foundation

enum CurrencyInputFormatter {
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

    static func formatWithSymbol(_ raw: String, symbol: String = "$") -> String {
        let formatted = format(raw)
        return "\(symbol)\(formatted)"
    }

    static func stripFormatting(_ formatted: String) -> String {
        let stripped = formatted.replacingOccurrences(of: ",", with: "")

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

    private static func formatIntegerPart(_ value: String) -> String {
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
