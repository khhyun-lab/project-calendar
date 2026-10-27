//
//  TodayScheduleWidgetLiveActivity.swift
//  TodayScheduleWidget
//
//  Created by 규현 on 10/27/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TodayScheduleWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TodayScheduleWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TodayScheduleWidgetAttributes.self) { context in
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

extension TodayScheduleWidgetAttributes {
    fileprivate static var preview: TodayScheduleWidgetAttributes {
        TodayScheduleWidgetAttributes(name: "World")
    }
}

extension TodayScheduleWidgetAttributes.ContentState {
    fileprivate static var smiley: TodayScheduleWidgetAttributes.ContentState {
        TodayScheduleWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TodayScheduleWidgetAttributes.ContentState {
         TodayScheduleWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TodayScheduleWidgetAttributes.preview) {
   TodayScheduleWidgetLiveActivity()
} contentStates: {
    TodayScheduleWidgetAttributes.ContentState.smiley
    TodayScheduleWidgetAttributes.ContentState.starEyes
}
