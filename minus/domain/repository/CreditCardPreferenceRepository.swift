//
//  CreditCardPreferenceRepository.swift
//  minus
//

protocol CreditCardPreferenceRepository {
    func isCreditCardPaymentsEnabled() -> Bool
    func setCreditCardPaymentsEnabled(_ enabled: Bool)
    func getCutoffDay() -> Int?
    func setCutoffDay(_ day: Int)
}
