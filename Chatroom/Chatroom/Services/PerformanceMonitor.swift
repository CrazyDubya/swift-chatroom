//
//  PerformanceMonitor.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import Foundation
import UIKit

class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private var metrics: [String: PerformanceMetric] = [:]
    private var memoryWarningCount = 0
    private var crashReports: [CrashReport] = []

    private init() {
        setupMemoryWarningObserver()
    }

    // MARK: - Memory Monitoring

    private func setupMemoryWarningObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryWarning() {
        memoryWarningCount += 1

        let memoryUsage = getMemoryUsage()

        AnalyticsService.shared.logEvent(.crashOccurred, parameters: [
            "event": "memory_warning",
            "count": memoryWarningCount,
            "memory_usage_mb": memoryUsage
        ])

        #if DEBUG
        print("⚠️ Memory Warning #\(memoryWarningCount) - Usage: \(memoryUsage)MB")
        #endif
    }

    func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if result == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0
        }

        return 0
    }

    // MARK: - Performance Metrics

    func startMeasuring(_ operation: String) {
        metrics[operation] = PerformanceMetric(
            name: operation,
            startTime: Date()
        )
    }

    func stopMeasuring(_ operation: String) {
        guard let metric = metrics[operation] else { return }

        let duration = Date().timeIntervalSince(metric.startTime)
        metrics[operation]?.duration = duration

        // Log if duration exceeds threshold
        if duration > 1.0 {
            AnalyticsService.shared.logEvent(.featureDiscovered, parameters: [
                "performance_issue": operation,
                "duration_ms": duration * 1000
            ])
        }

        #if DEBUG
        print("⏱️ Performance: \(operation) took \(String(format: "%.2f", duration * 1000))ms")
        #endif
    }

    func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        startMeasuring(operation)
        defer { stopMeasuring(operation) }
        return try block()
    }

    func measureAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        startMeasuring(operation)
        defer { stopMeasuring(operation) }
        return try await block()
    }

    // MARK: - Network Monitoring

    func trackNetworkRequest(url: String, method: String, duration: TimeInterval, statusCode: Int?) {
        let parameters: [String: Any] = [
            "url": url,
            "method": method,
            "duration_ms": duration * 1000,
            "status_code": statusCode ?? 0,
            "success": (statusCode ?? 0) < 400
        ]

        AnalyticsService.shared.logEvent(.featureDiscovered, parameters: parameters)
    }

    // MARK: - Crash Reporting

    func logCrash(_ error: Error, context: String? = nil, stackTrace: String? = nil) {
        let report = CrashReport(
            error: error,
            context: context,
            stackTrace: stackTrace,
            timestamp: Date(),
            memoryUsage: getMemoryUsage()
        )

        crashReports.append(report)

        // Send to analytics
        AnalyticsService.shared.logError(error, context: context)

        // Save locally for later upload
        saveCrashReport(report)
    }

    private func saveCrashReport(_ report: CrashReport) {
        // TODO: Save crash report to disk for later upload
        #if DEBUG
        print("💥 Crash Report: \(report)")
        #endif
    }

    // MARK: - App Launch Performance

    private var appLaunchTime: Date?

    func recordAppLaunch() {
        appLaunchTime = Date()
    }

    func recordAppLaunchComplete() {
        guard let launchTime = appLaunchTime else { return }

        let duration = Date().timeIntervalSince(launchTime)

        AnalyticsService.shared.logEvent(.appLaunched, parameters: [
            "launch_duration_ms": duration * 1000,
            "memory_usage_mb": getMemoryUsage()
        ])

        #if DEBUG
        print("🚀 App Launch: \(String(format: "%.2f", duration * 1000))ms")
        #endif

        appLaunchTime = nil
    }

    // MARK: - Battery Monitoring

    func getBatteryLevel() -> Float {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryLevel
    }

    func getBatteryState() -> UIDevice.BatteryState {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState
    }

    // MARK: - Reports

    func generatePerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            metrics: Array(metrics.values),
            memoryUsage: getMemoryUsage(),
            memoryWarningCount: memoryWarningCount,
            crashCount: crashReports.count,
            batteryLevel: getBatteryLevel()
        )
    }
}

// MARK: - Supporting Types

struct PerformanceMetric {
    let name: String
    let startTime: Date
    var duration: TimeInterval?
}

struct CrashReport {
    let error: Error
    let context: String?
    let stackTrace: String?
    let timestamp: Date
    let memoryUsage: Double
}

struct PerformanceReport {
    let metrics: [PerformanceMetric]
    let memoryUsage: Double
    let memoryWarningCount: Int
    let crashCount: Int
    let batteryLevel: Float
}
