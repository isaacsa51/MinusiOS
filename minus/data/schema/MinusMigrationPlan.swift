//
//  MinusMigrationPlan.swift
//  minus
//

import SwiftData

enum MinusMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
