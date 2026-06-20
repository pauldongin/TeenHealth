import Foundation
import HealthKit

// MARK: - Workout Summary

struct WorkoutSummary: Identifiable {
    let id: UUID
    let name: String
    let duration: TimeInterval
    let calories: Double
    let date: Date

    var durationFormatted: String {
        let mins = Int(duration / 60)
        if mins < 60 { return "\(mins) min" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}

// MARK: - Protocol

protocol HealthServiceProtocol: AnyObject {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func fetchTodaySteps() async -> Double
    func fetchTodayActiveEnergy() async -> Double
    func fetchLatestWeight() async -> Double?
    func saveWeight(_ kg: Double) async throws
    func fetchWorkouts(limit: Int) async -> [WorkoutSummary]
    func fetchSleepHours() async -> Double
}

// MARK: - Mock Service

final class MockHealthService: HealthServiceProtocol {
    var isAuthorized: Bool = true

    func requestAuthorization() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        isAuthorized = true
    }

    func fetchTodaySteps() async -> Double {
        Double.random(in: 2000...12000)
    }

    func fetchTodayActiveEnergy() async -> Double {
        Double.random(in: 150...600)
    }

    func fetchLatestWeight() async -> Double? {
        65.0 + Double.random(in: -2...2)
    }

    func saveWeight(_ kg: Double) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    func fetchWorkouts(limit: Int) async -> [WorkoutSummary] {
        let names = ["Walking", "Running", "Cycling", "Swimming", "HIIT", "Dance"]
        return (0..<min(limit, 5)).map { i in
            WorkoutSummary(
                id: UUID(),
                name: names[i % names.count],
                duration: Double.random(in: 1200...3600),
                calories: Double.random(in: 100...400),
                date: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            )
        }
    }

    func fetchSleepHours() async -> Double {
        Double.random(in: 6.5...9.0)
    }
}

// MARK: - Real HealthKit Service

final class RealHealthService: HealthServiceProtocol {
    private let store = HKHealthStore()
    var isAuthorized: Bool = false

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType(),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKObjectType.workoutType()]
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        return types
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
        isAuthorized = true
    }

    func fetchTodaySteps() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let steps = stats?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                cont.resume(returning: steps)
            }
            store.execute(query)
        }
    }

    func fetchTodayActiveEnergy() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        return await withCheckedContinuation { cont in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let energy = stats?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                cont.resume(returning: energy)
            }
            store.execute(query)
        }
    }

    func fetchLatestWeight() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    cont.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                cont.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    func saveWeight(_ kg: Double) async throws {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: Date(), end: Date())
        try await store.save(sample)
    }

    func fetchWorkouts(limit: Int) async -> [WorkoutSummary] {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: nil, limit: limit, sortDescriptors: [sortDescriptor]) { _, samples, _ in
                let workouts = (samples as? [HKWorkout] ?? []).map { w in
                    WorkoutSummary(
                        id: UUID(),
                        name: w.workoutActivityType.name,
                        duration: w.duration,
                        calories: w.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                        date: w.startDate
                    )
                }
                cont.resume(returning: workouts)
            }
            store.execute(query)
        }
    }

    func fetchSleepHours() async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: Date())
        return await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let totalSeconds = (samples as? [HKCategorySample] ?? [])
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                cont.resume(returning: totalSeconds / 3600)
            }
            store.execute(query)
        }
    }
}

// MARK: - HKWorkoutActivityType extension

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .walking: return "Walking"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .highIntensityIntervalTraining: return "HIIT"
        case .dance: return "Dance"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        case .yoga: return "Yoga"
        default: return "Workout"
        }
    }
}
