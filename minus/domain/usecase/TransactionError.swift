//
//  TransactionError.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

import Foundation

//enum class to handle errors cases if in case
enum TransactionError: LocalizedError {
    case invalidAmount
    case noActivePeriod
    case transactionNotFound

    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "El monto ingresado no es válido"
        case .noActivePeriod: return "No tienes un periodo de ahorro activo. Crea uno primero."
        case .transactionNotFound: return "No se encontró la transacción"
        }
    }
}
