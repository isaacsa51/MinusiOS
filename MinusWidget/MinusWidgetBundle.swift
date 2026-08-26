//
//  MinusWidgetBundle.swift
//  MinusWidget
//
//  Created by Isaac Emmanuel Serrano Altamirano on 26/08/26.
//

import WidgetKit
import SwiftUI

@main
struct MinusWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetOverviewWidget()
        MinusWidgetControl()
        MinusWidgetLiveActivity()
    }
}
