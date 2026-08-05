import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var showSettings = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let error = viewModel.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }

                    if let reading = viewModel.reading {
                        ReadingCard(reading: reading)
                    } else if viewModel.isLoading {
                        ProgressView("Finding your air quality…")
                            .padding(.top, 80)
                    } else if !viewModel.hasAPIKey {
                        ContentUnavailableView {
                            Label("AirNow key needed", systemImage: "key")
                        } description: {
                            Text("USAirQMinder reads live air quality from the EPA's AirNow service, which needs a free API key.")
                        } actions: {
                            Button("Open Settings") { showSettings = true }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 40)
                    } else if viewModel.errorMessage == nil {
                        ContentUnavailableView(
                            "No reading yet",
                            systemImage: "aqi.medium",
                            description: Text("Pull to refresh or tap the arrows to check your local Air Quality Index.")
                        )
                        .padding(.top, 40)
                    }

                    scheduleFooter
                }
                .padding(.vertical)
                // On a tall iPad screen the content otherwise sits jammed under
                // the title with the rest of the page blank; this centres it in
                // the space instead. Left alone on iPhone, where it fills.
                .verticallyCentredInContainer(horizontalSizeClass == .regular)
            }
            .refreshable { await viewModel.refresh() }
            .navigationTitle("USAirQMinder")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Refresh now")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(viewModel)
            }
            .task {
                if viewModel.reading == nil && viewModel.hasAPIKey {
                    await viewModel.refresh()
                    viewModel.scheduleTimer()
                }
            }
        }
    }

    private var scheduleFooter: some View {
        VStack(spacing: 4) {
            if let lastChecked = viewModel.lastChecked {
                Text("Last checked \(lastChecked.formatted(date: .omitted, time: .shortened))")
            }
            if let nextCheck = viewModel.nextCheck {
                Text("Next check about \(nextCheck.formatted(date: .abbreviated, time: .shortened)) · \(viewModel.interval.label.lowercased())")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
}

private struct ReadingCard: View {
    let reading: AQIReading

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isWide: Bool { horizontalSizeClass == .regular }

    /// The dial fills across the band the reading sits in, so a move from 40
    /// to 60 is visible rather than being lost on a 0–500 sweep.
    private var dialFraction: Double {
        let upper = reading.category.upperBound
        let lower: Double = {
            switch reading.category {
            case .good: return 0
            case .moderate: return 50
            case .unhealthySensitive: return 100
            case .unhealthy: return 150
            case .veryUnhealthy: return 200
            case .hazardous: return 300
            }
        }()
        let span = upper - lower
        guard span > 0 else { return 1 }
        return min(max((Double(reading.aqi) - lower) / span, 0.02), 1.0)
    }

    private func dial(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(reading.category.color.opacity(0.15), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: dialFraction)
                .stroke(reading.category.color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(reading.displayValue)
                    .font(.system(size: size * 0.33, weight: .bold, design: .rounded))
                    .foregroundStyle(reading.category.textColor)
                Text("AQI")
                    .font(size > 260 ? .title3 : .headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Air Quality Index \(reading.displayValue), \(reading.category.label)")
    }

    private var headline: some View {
        VStack(alignment: isWide ? .leading : .center, spacing: 8) {
            Text(reading.category.label)
                .font(isWide ? .largeTitle.weight(.bold) : .title2.weight(.bold))
                .foregroundStyle(reading.category.textColor)
                .multilineTextAlignment(isWide ? .leading : .center)

            Text(reading.category.advice)
                .font(isWide ? .body : .subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(isWide ? .leading : .center)
        }
        .frame(maxWidth: .infinity, alignment: isWide ? .leading : .center)
    }

    @ViewBuilder
    private var pollutants: some View {
        if reading.allPollutants.count > 1 {
            HStack(spacing: 8) {
                ForEach(reading.allPollutants, id: \.name) { pollutant in
                    VStack(spacing: 2) {
                        Text(pollutant.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(pollutant.aqi)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AQICategory(aqi: pollutant.aqi).textColor)
                    }
                    .frame(minWidth: 56)
                    .padding(.vertical, 8)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .frame(maxWidth: .infinity, alignment: isWide ? .leading : .center)
        }
    }

    private var metadata: some View {
        VStack(alignment: isWide ? .leading : .center, spacing: 4) {
            Label("\(reading.location) · \(Int(reading.distanceKm.rounded())) km away", systemImage: "mappin.and.ellipse")
            Label("Driven by \(reading.parameterName)", systemImage: "smoke")
            Label("Observed \(reading.observedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "clock")
        }
        .font(isWide ? .subheadline : .caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: isWide ? .leading : .center)
    }

    var body: some View {
        if isWide {
            // On an iPad the phone layout leaves most of the screen empty, so
            // the dial and the words it needs sit side by side instead. Capped
            // rather than filling the width — a line of body text running the
            // whole 13" is worse than the whitespace it replaces.
            HStack(alignment: .center, spacing: 56) {
                dial(size: 320)
                VStack(alignment: .leading, spacing: 24) {
                    headline
                    pollutants
                    metadata
                }
                .frame(maxWidth: 420, alignment: .leading)
            }
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 20) {
                dial(size: 220)
                    .padding(.top, 8)
                headline
                pollutants
                metadata
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel())
}

extension View {
    /// Fills the scroll container's height and centres within it, so a short
    /// card sits in the middle of a tall iPad screen rather than at the top.
    @ViewBuilder
    func verticallyCentredInContainer(_ enabled: Bool) -> some View {
        if enabled {
            containerRelativeFrame(.vertical, alignment: .center)
        } else {
            self
        }
    }
}
