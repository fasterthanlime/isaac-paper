
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger, Handler, Formatter, Filter, Level]

version (android) {
    import deadlogger/AndroidHandler
}

// sdk stuff
import io/File

Logging: class {

    setup: static func {
        version (android) {
            // log to Android handler
            Log root attachHandler(AndroidHandler new())
        } else {
            // log to console
            console := StdoutHandler new()
            formatter := NiceFormatter new()
            version (!windows) {
                formatter = ColoredFormatter new(formatter)
            }
            console setFormatter(formatter)
            console setFilter(LevelFilter new(Level info..Level critical))
            Log root attachHandler(console)

            // aaand log to file.
            logFile := File new("log.txt")
            if (logFile exists?()) {
                logFile remove()
            }
            file := FileHandler new("log.txt")
            file setFormatter(NiceFormatter new())
            Log root attachHandler(file)
        }
    }

}

