// The Swift Programming Language
// https://docs.swift.org/swift-book
struct CallFlags {
    let isConnected: Bool
    let hasEnded: Bool
}

func connectionMessage(call: CallFlags) -> String {
    
    if call.hasEnded {
        return "Call ended"
    } else if call.isConnected {
        return "Call connected"
    } else {
        return "Call not connected"
    }
}

func observationMessage(isConnected: Bool?) -> String{
    switch isConnected {
    case true:
        return "Call connected"
    case false:
        return "Call not connected"
    case nil:
        return "Not checked yet"
    }
}

func hasConnectedCall(calls: [CallFlags]) -> Bool {
    
    for call in calls {
        if call.isConnected && !call.hasEnded {
            return true
        }
    }
    return false
}



@main
struct CallSignal {
    static func main() {
        let calls: [CallFlags] = [CallFlags(isConnected: false, hasEnded: false),
                                CallFlags(isConnected: false, hasEnded: true),
                                CallFlags(isConnected: true, hasEnded: false),
                                CallFlags(isConnected: true, hasEnded: true)
                                ]
        
        print(hasConnectedCall(calls: calls))
    }
}
