

/**
 * A parabola, for smooth movement
 */
Parabola: class {

    height: Float
    length: Float
    bottom: Float

    init: func (=height, =length, bottom := 0) {
        this bottom = bottom
    }

    eval: func (x: Float) -> Float {
        if (x > length) {
            return bottom
        }

        a := (2.0 * x / length) - 1.0
        b := a * a
        c := 1.0 - b
        c * height
    }

}
