//
//  TransactionError.swift
//  minus
//
//  Created by Isaac Emmanuel Serrano Altamirano on 09/05/26.
//

//enum class to handle errors cases if in case
enum TransactionError: Error {
    case invalidAmount
    case noActivePeriod
    case transactionNotFound
}
