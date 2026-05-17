import OSLog

public enum Log {
    public static let subsystem = "dev.sleev"

    public static let app = Logger(subsystem: subsystem, category: "app")
    public static let xpc = Logger(subsystem: subsystem, category: "xpc")
    public static let statusBar = Logger(subsystem: subsystem, category: "statusBar")
    public static let agent = Logger(subsystem: subsystem, category: "agent")
    public static let accessibility = Logger(subsystem: subsystem, category: "accessibility")
    public static let drag = Logger(subsystem: subsystem, category: "drag")
}
