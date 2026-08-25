//
//  EnvironmentKeys.swift
//  minus
//

import SwiftUI

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.preview()
}

extension EnvironmentValues {
    var dependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
