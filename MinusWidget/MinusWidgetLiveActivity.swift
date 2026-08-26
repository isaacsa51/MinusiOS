//
//  MinusWidgetLiveActivity.swift
//  MinusWidget
//
//  Created by Isaac Emmanuel Serrano Altamirano on 26/08/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MinusWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MinusWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MinusWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MinusWidgetAttributes {
    fileprivate static var preview: MinusWidgetAttributes {
        MinusWidgetAttributes(name: "World")
    }
}

extension MinusWidgetAttributes.ContentState {
    fileprivate static var smiley: MinusWidgetAttributes.ContentState {
        MinusWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MinusWidgetAttributes.ContentState {
         MinusWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MinusWidgetAttributes.preview) {
   MinusWidgetLiveActivity()
} contentStates: {
    MinusWidgetAttributes.ContentState.smiley
    MinusWidgetAttributes.ContentState.starEyes
}
