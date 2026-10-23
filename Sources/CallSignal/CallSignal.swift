// The Swift Programming Language
// https://docs.swift.org/swift-book
struct CallFlags {
    let isConnected: Bool
    let hasEnded: Bool
    let isOnHold: Bool
}

enum DetectionRule{
    case isConnected
    case isConnectedNotHeld
    case anyActive
}

func connectionMessage(call: CallFlags) -> String {
    switch (call.isOnHold, call.hasEnded, call.isConnected) {
    case (true, false, _):
        return "Call on hold"
    case (_, true, _):
        return "Call ended"
    case (_, false, true):
        return "Call connected"
    default:
        return "Call not connected"
    }
}

func hasMatchingCall(calls: [CallFlags], rule: DetectionRule) -> Bool {
    for call in calls {
        if matches(call: call, rule: rule) {
            return true
        }
    }
    return false
}

func ruleDescription(rule: DetectionRule) -> String {
    switch rule {
    case .isConnected:
        return "Detects if a call is connected"
    case .isConnectedNotHeld:
        return "Detects if a call is connected and not on hold"
    case .anyActive:
        return "Detects if any call is active"
    }
}

func matches(call: CallFlags, rule: DetectionRule) -> Bool {
    if call.hasEnded {
        return false
    }

    switch rule{
    case .isConnected:
        return call.isConnected
    case .isConnectedNotHeld:
        return call.isConnected && !call.isOnHold
    case .anyActive: // any call that is not ended is considered active
        return true
    }
}


@main
struct CallSignal {
    static func main() {
        let calls: [CallFlags] = [
            
        ]
        
        
            print(hasMatchingCall(calls: calls, rule: .isConnected))
            print(hasMatchingCall(calls: calls, rule: .isConnectedNotHeld))
            print(hasMatchingCall(calls: calls, rule: .anyActive))


    

    }

}
