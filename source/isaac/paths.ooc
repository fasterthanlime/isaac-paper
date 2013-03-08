
// sdk stuff
import math

/**
 * A trajectory
 */
Path: abstract class {

    t := 0.0
    incr := 0.1

    init: func {
        // override, bro
    }

    eval: func ~noparam -> Float {
        eval(t + incr)
    }
    
    eval: abstract func (x: Float) -> Float

    done?: abstract func -> Bool
    
}

/**
 * A parabola, for smooth movement
 */
Parabola: class extends Path {

    height: Float
    length: Float
    bottom: Float

    init: func (=height, =length, bottom := 0) {
        super()
        this bottom = bottom
    }

    eval: func (x: Float) -> Float {
        t = x
        if (x > length) {
            return bottom
        }

        a := (2.0 * x / length) - 1.0
        b := a * a
        c := 1.0 - b
        c * height
    }

    done?: func -> Bool {
        t >= length
    }

}

/**
 * A sinusoid
 */
Sinus: class extends Path {

    amplitude: Float

    init: func (=amplitude) {
    }

    eval: func (x: Float) -> Float {
        t = x
        sin(t) * amplitude
    }

    done?: func -> Bool {
        false
    }

}
