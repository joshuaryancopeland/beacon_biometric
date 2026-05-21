import SwiftUI

// MARK: - Vital Sign Types

enum VitalSign: String, CaseIterable, Identifiable {
    case heartRate      = "heartRate"
    case spO2           = "spO2"
    case bloodPressure  = "bloodPressure"
    case respiratoryRate = "respiratoryRate"
    case temperature    = "temperature"
    case mapPressure    = "mapPressure"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .heartRate:       return "Heart Rate"
        case .spO2:            return "SpO₂"
        case .bloodPressure:   return "Blood Pressure"
        case .respiratoryRate: return "Resp Rate"
        case .temperature:     return "Temperature"
        case .mapPressure:     return "MAP"
        }
    }

    var unit: String {
        switch self {
        case .heartRate:       return "bpm"
        case .spO2:            return "%"
        case .bloodPressure:   return "mmHg"
        case .respiratoryRate: return "/min"
        case .temperature:     return "°F"
        case .mapPressure:     return "mmHg"
        }
    }
}

// MARK: - Status

enum VitalStatus {
    case normal
    case warning
    case critical

    var color: Color {
        switch self {
        case .normal:   return Color(red: 0.086, green: 0.639, blue: 0.290) // #16a34a
        case .warning:  return Color(red: 0.918, green: 0.353, blue: 0.000) // #ea580c
        case .critical: return Color(red: 0.863, green: 0.098, blue: 0.098) // #dc1818
        }
    }
}

// MARK: - Heart Rate

struct HeartRateParams {
    static let normalLow:    Double = 60
    static let normalHigh:   Double = 100
    static let criticalLow:  Double = 40
    static let criticalHigh: Double = 150

    static func status(for bpm: Double) -> VitalStatus {
        if bpm < criticalLow || bpm > criticalHigh { return .critical }
        if bpm < normalLow   || bpm > normalHigh   { return .warning }
        return .normal
    }

    static func trend(for bpm: Double) -> String {
        if bpm < normalLow  { return "↓ Bradycardia" }
        if bpm > normalHigh { return "↑ Tachycardia" }
        return "↑ Normal sinus"
    }
}

// MARK: - SpO₂

struct SpO2Params {
    static let normal:   Double = 98
    static let adequate: Double = 95
    static let low:      Double = 94
    static let critical: Double = 90

    static func status(for pct: Double) -> VitalStatus {
        if pct < critical { return .critical }
        if pct < low      { return .warning }
        return .normal
    }

    static func trend(for pct: Double) -> String {
        if pct >= normal   { return "→ Stable" }
        if pct >= adequate { return "↓ Adequate" }
        return "↓ Low"
    }
}

// MARK: - Blood Pressure

struct BloodPressureParams {
    static let sysCriticalLow:  Double = 80
    static let sysNormalLow:    Double = 100
    static let sysNormalHigh:   Double = 130
    static let sysElevated:     Double = 140
    static let sysCriticalHigh: Double = 180

    static let diaNormalLow:    Double = 60
    static let diaNormalHigh:   Double = 85
    static let diaCriticalHigh: Double = 120

    static let mapCriticalLow:  Double = 65
    static let mapNormalLow:    Double = 70
    static let mapNormalHigh:   Double = 100

    static func map(sys: Double, dia: Double) -> Double {
        (sys + 2 * dia) / 3
    }

    static func status(sys: Double, dia: Double) -> VitalStatus {
        let map = Self.map(sys: sys, dia: dia)
        if sys < sysCriticalLow || sys > sysCriticalHigh { return .critical }
        if dia > diaCriticalHigh                         { return .critical }
        if map < mapCriticalLow                          { return .critical }
        if sys < sysNormalLow || sys > sysElevated       { return .warning }
        if dia < diaNormalLow || dia > diaNormalHigh     { return .warning }
        return .normal
    }

    static func trend(sys: Double, dia: Double) -> String {
        let map = Int(Self.map(sys: sys, dia: dia))
        if sys > sysElevated   { return "↑ HTN Stage 2" }
        if sys > sysNormalHigh { return "↑ Elevated" }
        if sys < sysNormalLow  { return "↓ Hypotension" }
        return "↓ MAP \(map)"
    }
}

// MARK: - Respiratory Rate

struct RespiratoryRateParams {
    static let normalLow:    Double = 12
    static let normalHigh:   Double = 20
    static let criticalLow:  Double = 8
    static let criticalHigh: Double = 30

    static func status(for rr: Double) -> VitalStatus {
        if rr < criticalLow || rr > criticalHigh { return .critical }
        if rr < normalLow   || rr > normalHigh   { return .warning }
        return .normal
    }

    static func trend(for rr: Double) -> String {
        if rr < normalLow  { return "↓ Bradypnea" }
        if rr > normalHigh { return "↑ Tachypnea" }
        return "→ Normal"
    }
}

// MARK: - Temperature

struct TemperatureParams {
    static let hypothermiaCritical: Double = 95.0
    static let hypothermiaWarning:  Double = 96.8
    static let normalLow:           Double = 97.7
    static let normalHigh:          Double = 99.5
    static let lowGradeFever:       Double = 100.4
    static let feverWarning:        Double = 103.0
    static let feverCritical:       Double = 104.0

    static func status(for temp: Double) -> VitalStatus {
        if temp < hypothermiaCritical || temp > feverCritical { return .critical }
        if temp < hypothermiaWarning  || temp > feverWarning  { return .warning }
        if temp < normalLow           || temp > lowGradeFever { return .warning }
        return .normal
    }

    static func trend(for temp: Double) -> String {
        if temp < hypothermiaCritical { return "↓ Hypothermia" }
        if temp < normalLow           { return "↓ Low" }
        if temp > feverCritical       { return "↑ High Fever" }
        if temp > lowGradeFever       { return "↑ Fever" }
        return "→ Afebrile"
    }
}

// MARK: - Update Intervals

/// How frequently each vital is sampled and displayed (in seconds).
/// Sources: AHA, AACN, and standard ICU/step-down monitoring protocols.
enum VitalUpdateInterval {
    static let heartRate: TimeInterval = 1

    static let spO2: TimeInterval = 4

    static let bloodPressureStable:   TimeInterval = 900
    static let bloodPressureActive:   TimeInterval = 300
    static let bloodPressureArterial: TimeInterval = 1

    static let respiratoryRate: TimeInterval = 4

    static let temperatureStable: TimeInterval = 3600
    static let temperatureActive: TimeInterval = 900

    static let alarmSuppressionWindow: TimeInterval = 120
}
