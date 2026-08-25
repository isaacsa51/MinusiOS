//
//  ModelContainerProvider.swift
//  minus
//

import SwiftData
import Foundation

enum ModelContainerProvider {
    static func makeContainer() -> ModelContainer {
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            return try ModelContainer(for: schema, migrationPlan: MinusMigrationPlan.self)
        } catch {
            fatalError("Error trying to init database: \(error.localizedDescription)")
        }
    }

    /// Throwaway store for #Preview and other contexts that need real repository
    /// behavior (save/read round-trips) without touching the user's actual data.
    static func makeInMemoryContainer() -> ModelContainer {
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, migrationPlan: MinusMigrationPlan.self, configurations: configuration)
        } catch {
            fatalError("Error trying to init in-memory database: \(error.localizedDescription)")
        }
    }
}
