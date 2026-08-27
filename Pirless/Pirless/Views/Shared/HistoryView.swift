//
//  HistoryView.swift
//  Pirless
//
//  History PM2.5 berdasarkan TrafficPoint.
//

import SwiftUI
import Charts
import UIKit

// MARK: - History Filter

enum HistoryFilter: String, CaseIterable, Identifiable {

    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }
}

// MARK: - Chart Data

struct HistoryChartData: Identifiable {

    let id: UUID
    let date: Date
    let pm25: Double
    let vehicles: Int

    init(
        id: UUID = UUID(),
        date: Date,
        pm25: Double,
        vehicles: Int
    ) {
        self.id = id
        self.date = date
        self.pm25 = pm25
        self.vehicles = vehicles
    }
}

// MARK: - History View

struct HistoryView: View {

    // MARK: - ViewModel

    @State private var viewModel: HistoryViewModel

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Init

    init(trafficPoint: TrafficPoint) {
        _viewModel = State(wrappedValue: HistoryViewModel(trafficPoint: trafficPoint))
    }

    // MARK: - Body

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(spacing: 20) {

                headerView

                filterSegmentedControl

                if viewModel.selectedFilter == .daily {
                    chartCard
                    saveButton
                    metricsView
                } else {
                    maintenanceState
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 30)
        }
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden()
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let csvURL = viewModel.csvURL {
                ShareSheet(items: [csvURL])
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Header

private extension HistoryView {

    var headerView: some View {
        HStack {

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Kembali")

            Spacer()

            VStack(spacing: 3) {

                Text("History")
                    .font(.system(size: 20, weight: .bold))

                Text(viewModel.trafficPoint.locationName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }
}

// MARK: - Filter

private extension HistoryView {

    var filterSegmentedControl: some View {
        HStack(spacing: 4) {

            filterButton(title: "Daily",   filter: .daily,   enabled: true)
            filterButton(title: "Weekly",  filter: .weekly,  enabled: false)
            filterButton(title: "Monthly", filter: .monthly, enabled: false)
        }
        .padding(4)
        .background(Color(.systemGray5))
        .clipShape(Capsule())
    }

    @ViewBuilder
    func filterButton(
        title: String,
        filter: HistoryFilter,
        enabled: Bool
    ) -> some View {

        let selected = viewModel.selectedFilter == filter

        Button {
            guard enabled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedFilter = filter
            }
        } label: {

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(selected ? Color.black : Color.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if selected {
                        Capsule()
                            .fill(Color(red: 0.68, green: 0.85, blue: 0.95))
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

// MARK: - Maintenance State

private extension HistoryView {

    var maintenanceState: some View {
        VStack(spacing: 10) {

            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 64, height: 64)

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("Coming Soon")
                .font(.system(size: 17, weight: .bold))

            Text("Weekly dan Monthly history\nakan tersedia pada pembaruan berikutnya.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 420)
    }
}

// MARK: - Chart Card

private extension HistoryView {

    var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack {

                VStack(alignment: .leading, spacing: 3) {

                    Text("PM2.5")
                        .font(.system(size: 18, weight: .bold))

                    Text(viewModel.trafficPoint.locationName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(viewModel.chartData.count) data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.chartData.isEmpty {
                emptyChart
            } else {
                pm25Chart
            }
        }
        .padding(16)
        .background(Color(red: 0.90, green: 0.94, blue: 0.93))
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}

// MARK: - Empty Chart

private extension HistoryView {

    var emptyChart: some View {
        VStack(spacing: 10) {

            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 64, height: 64)

                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("Belum ada riwayat")
                .font(.system(size: 15, weight: .semibold))

            Text("Belum ada data PM2.5 untuk titik ini hari ini.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 230)
    }
}

// MARK: - PM2.5 Chart

private extension HistoryView {

    var pm25Chart: some View {
        Chart {
            ForEach(viewModel.chartData) { item in

                AreaMark(
                    x: .value("Waktu", item.date),
                    y: .value("PM2.5", item.pm25)
                )
                .foregroundStyle(Color.green.opacity(0.18))

                LineMark(
                    x: .value("Waktu", item.date),
                    y: .value("PM2.5", item.pm25)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                PointMark(
                    x: .value("Waktu", item.date),
                    y: .value("PM2.5", item.pm25)
                )
                .foregroundStyle(.green)
            }
        }
        .frame(height: 230)
        .chartXAxis {
            AxisMarks(values: .automatic) {
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }
}

// MARK: - Save Button

private extension HistoryView {

    var saveButton: some View {
        HStack {

            Spacer()

            Button {
                viewModel.createCSV()
            } label: {

                HStack(spacing: 7) {

                    Image(systemName: "square.and.arrow.down")

                    Text("Save Data")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(red: 0.10, green: 0.55, blue: 0.48))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.chartData.isEmpty)
            .opacity(viewModel.chartData.isEmpty ? 0.5 : 1)
        }
    }
}

// MARK: - Metrics

private extension HistoryView {

    var metricsView: some View {
        VStack(spacing: 14) {

            metricCard(
                title: "AVG PM2.5",
                value: viewModel.formatPM25(viewModel.averagePM25),
                unit: "µg/m³",
                icon: "wind",
                iconColor: .green
            )

            metricCard(
                title: "PEAK PM2.5",
                value: viewModel.formatPM25(viewModel.peakPM25),
                unit: "µg/m³",
                icon: "exclamationmark.triangle.fill",
                iconColor: .red
            )

            metricCard(
                title: "AVG VEHICLES",
                value: viewModel.formatVehicles(viewModel.averageVehicles),
                unit: "vehicles / interval",
                icon: "car.fill",
                iconColor: .blue
            )
        }
    }

    func metricCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        iconColor: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 7) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 5) {

                Text(value)
                    .font(.system(size: 32, weight: .bold))

                if value != "—" {
                    Text(unit)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {

    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HistoryView(
            trafficPoint: TrafficPoint(
                id: UUID(),
                locationName: "Baranangsiang",
                latitude: -6.6015,
                longitude: 106.8061
            )
        )
    }
}
