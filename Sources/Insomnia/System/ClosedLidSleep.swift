import CoreGraphics
import Foundation
import IOKit
import IOKit.pwr_mgt

/// Puts a closed Mac to sleep after a timer or floor-rule end (spec section 6).
protocol ClosedLidSleeping: Sendable {
    /// `AppleClamshellCausesSleep`, for the log only. It decides nothing:
    /// on the MacBook Pro M5 (macOS 27.0.1) this fork was made for it read
    /// No with the lid open and no monitor, so a sleep gated on it would
    /// never be asked.
    func lidCloseCausesSleep() -> Bool?
    /// Active displays other than the built-in panel. A Mac in clamshell
    /// mode on a monitor is in use and must not be put to sleep. nil when
    /// the display list cannot be read.
    func activeExternalDisplays() -> Int?
    /// `IOPMSleepSystem`. No root needed. macOS refuses it while sleep is
    /// disabled.
    func requestSleep() throws
}

struct ClosedLidSleepError: Error, LocalizedError {
    let call: String
    let code: IOReturn

    var errorDescription: String? {
        "\(call) returned \(String(format: "0x%08x", UInt32(bitPattern: code)))"
    }
}

struct IOKitClosedLidSleep: ClosedLidSleeping {
    func lidCloseCausesSleep() -> Bool? {
        LidObserver.readRootDomainBool("AppleClamshellCausesSleep")
    }

    /// Public CoreGraphics: the active display list, minus the built-in
    /// panel (`CGDisplayIsBuiltin`).
    func activeExternalDisplays() -> Int? {
        var ids = [CGDirectDisplayID](repeating: 0, count: 16)
        var count: UInt32 = 0
        guard CGGetActiveDisplayList(UInt32(ids.count), &ids, &count) == .success else { return nil }
        return ids.prefix(Int(count)).filter { CGDisplayIsBuiltin($0) == 0 }.count
    }

    func requestSleep() throws {
        let connect = IOPMFindPowerManagement(kIOMainPortDefault)
        guard connect != 0 else {
            throw ClosedLidSleepError(call: "IOPMFindPowerManagement", code: kIOReturnNotFound)
        }
        defer { IOServiceClose(connect) }
        let result = IOPMSleepSystem(connect)
        guard result == kIOReturnSuccess else {
            throw ClosedLidSleepError(call: "IOPMSleepSystem", code: result)
        }
    }
}

struct NoopClosedLidSleep: ClosedLidSleeping {
    func lidCloseCausesSleep() -> Bool? { nil }
    func activeExternalDisplays() -> Int? { nil }
    func requestSleep() throws {}
}
