// The Swift Programming Language
// https://docs.swift.org/swift-book
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

struct CallFlags {
    let isConnected: Bool
    let hasEnded: Bool
}

@main
struct CallSignal {
    static func main() {
        print(connectionMessage(call: CallFlags(isConnected: false, hasEnded: false)))
    }
}
