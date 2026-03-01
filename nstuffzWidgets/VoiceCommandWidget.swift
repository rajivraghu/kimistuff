//
//  VoiceCommandWidget.swift
//  nstuffzWidgets
//
//  Created by Rajiv Raghunathan on 28/02/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct VoiceCommandProvider: TimelineProvider {
    func placeholder(in context: Context) -> VoiceCommandEntry {
        VoiceCommandEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (VoiceCommandEntry) -> Void) {
        completion(VoiceCommandEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VoiceCommandEntry>) -> Void) {
        // Static widget — just provide a single entry, refresh in an hour
        let entry = VoiceCommandEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct VoiceCommandEntry: TimelineEntry {
    let date: Date
}

// MARK: - Widget Views

struct VoiceCommandWidgetEntryView: View {
    var entry: VoiceCommandEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    // MARK: - Small Widget

    private var smallWidget: some View {
        Link(destination: URL(string: "nstuffz://voice")!) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white)
                }

                Text("Voice Alarm")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // MARK: - Medium Widget

    private var mediumWidget: some View {
        Link(destination: URL(string: "nstuffz://voice")!) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 60, height: 60)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Voice Command")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Tap to set a reminder with your voice")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

// MARK: - Widget Definition

struct VoiceCommandWidget: Widget {
    let kind: String = "VoiceCommandWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VoiceCommandProvider()) { entry in
            VoiceCommandWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Voice Alarm")
        .description("Tap to quickly set a reminder using your voice.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
