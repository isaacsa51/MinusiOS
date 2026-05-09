//
//  Currency.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 08/05/26.
//

import Foundation

struct Currency: Identifiable, Equatable {
    var id: String { code }
    let code: String
    let symbol: String
    let name: String
    
    static let all: [Currency] = [
        Currency(code: "USD", symbol: "$", name: "Dólar estadounidense"),
        Currency(code: "MXN", symbol: "$", name: "Peso mexicano"),
        Currency(code: "EUR", symbol: "€", name: "Euro"),
        Currency(code: "GBP", symbol: "£", name: "Libra esterlina"),
        Currency(code: "JPY", symbol: "¥", name: "Yen japonés"),
        Currency(code: "CNY", symbol: "¥", name: "Yuan chino"),
        Currency(code: "KRW", symbol: "₩", name: "Won surcoreano"),
        Currency(code: "INR", symbol: "₹", name: "Rupia india"),
        Currency(code: "BRL", symbol: "R$", name: "Real brasileño"),
        Currency(code: "ARS", symbol: "$", name: "Peso argentino"),
        Currency(code: "COP", symbol: "$", name: "Peso colombiano"),
        Currency(code: "CLP", symbol: "$", name: "Peso chileno"),
        Currency(code: "PEN", symbol: "S/", name: "Sol peruano"),
        Currency(code: "CAD", symbol: "CA$", name: "Dólar canadiense"),
        Currency(code: "AUD", symbol: "A$", name: "Dólar australiano"),
        Currency(code: "CHF", symbol: "CHF", name: "Franco suizo"),
        Currency(code: "SEK", symbol: "kr", name: "Corona sueca"),
        Currency(code: "NOK", symbol: "kr", name: "Corona noruega"),
        Currency(code: "DKK", symbol: "kr", name: "Corona danesa"),
        Currency(code: "PLN", symbol: "zł", name: "Zloty polaco"),
        Currency(code: "TRY", symbol: "₺", name: "Lira turca"),
        Currency(code: "RUB", symbol: "₽", name: "Rublo ruso"),
        Currency(code: "THB", symbol: "฿", name: "Baht tailandés"),
        Currency(code: "PHP", symbol: "₱", name: "Peso filipino"),
        Currency(code: "TWD", symbol: "NT$", name: "Dólar taiwanés"),
        Currency(code: "ILS", symbol: "₪", name: "Shekel israelí"),
        Currency(code: "ZAR", symbol: "R", name: "Rand sudafricano"),
        Currency(code: "NGN", symbol: "₦", name: "Naira nigeriana"),
        Currency(code: "EGP", symbol: "E£", name: "Libra egipcia")
    ]
    
    static func find(byCode code: String) -> Currency? {
        all.first { $0.code.caseInsensitiveCompare(code) == .orderedSame }
    }
}
