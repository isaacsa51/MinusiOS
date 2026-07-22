//
//  SchemaV1.swift
//  minus
//

import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [TransactionEntity.self, PeriodEntity.self]
    }
}
