//
//  nstuffzWidgetsLiveActivity.swift
//  nstuffzWidgets
//
//  Created by Rajiv Raghunathan on 28/02/26.
//

import ActivityKit
import AlarmKit
import WidgetKit
import SwiftUI

// Duplicate of the metadata type from the main app so the widget extension can decode it.
// Must match the main app's ReminderMetadata exactly.
struct ReminderMetadata: AlarmMetadata {
    var reminderTitle: String
    var reminderNote: String

    init(reminderTitle: String = "", reminderNote: String = "") {
        self.reminderTitle = reminderTitle
        self.reminderNote = reminderNote
    }
}

struct nstuffzWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<ReminderMetadata>.self) { context in
            // Lock Screen / StandBy UI
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.center) {
                    expandedContent(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    modeIcon(context: context)
                        .font(.title2)
                }
            } compactLeading: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                compactTrailingView(context: context)
            } minimal: {
                Image(systemName: "alarm.fill")
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<AlarmAttributes<ReminderMetadata>>) -> some View {
        let mode = context.state.mode
        let title = context.attributes.metadata?.reminderTitle ?? "Alarm"

        switch mode {
        case .countdown(let countdown):
            HStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Snoozed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(countdown.fireDate, style: .timer)
                        .font(.title2.monospacedDigit())
                        .foregroundStyle(.blue)
                }

                Spacer()
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.8))

        case .alert:
            HStack(spacing: 16) {
                Image(systemName: "alarm.waves.left.and.right.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Alarm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.8))

        case .paused:
            HStack(spacing: 16) {
                Image(systemName: "pause.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding()
            .activityBackgroundTint(.black.opacity(0.8))

        @unknown default:
            Text(title)
                .padding()
        }
    }

    // MARK: - Dynamic Island Expanded Content

    @ViewBuilder
    private func expandedContent(context: ActivityViewContext<AlarmAttributes<ReminderMetadata>>) -> some View {
        let title = context.attributes.metadata?.reminderTitle ?? "Alarm"

        switch context.state.mode {
        case .countdown(let countdown):
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                Text(countdown.fireDate, style: .timer)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.blue)
            }

        case .alert:
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                Text("Ringing")
                    .font(.headline)
                    .foregroundStyle(.red)
            }

        case .paused:
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                Text("Paused")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

        @unknown default:
            Text(title)
        }
    }

    // MARK: - Compact Trailing

    @ViewBuilder
    private func compactTrailingView(context: ActivityViewContext<AlarmAttributes<ReminderMetadata>>) -> some View {
        switch context.state.mode {
        case .countdown(let countdown):
            Text(countdown.fireDate, style: .timer)
                .monospacedDigit()
                .foregroundStyle(.blue)
                .frame(minWidth: 40)

        case .alert:
            Image(systemName: "bell.fill")
                .foregroundStyle(.red)
                .symbolEffect(.pulse)

        case .paused:
            Image(systemName: "pause.fill")
                .foregroundStyle(.orange)

        @unknown default:
            EmptyView()
        }
    }

    // MARK: - Mode Icon

    @ViewBuilder
    private func modeIcon(context: ActivityViewContext<AlarmAttributes<ReminderMetadata>>) -> some View {
        switch context.state.mode {
        case .countdown:
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.blue)
        case .alert:
            Image(systemName: "bell.fill")
                .foregroundStyle(.red)
        case .paused:
            Image(systemName: "pause.circle.fill")
                .foregroundStyle(.orange)
        @unknown default:
            EmptyView()
        }
    }
}
