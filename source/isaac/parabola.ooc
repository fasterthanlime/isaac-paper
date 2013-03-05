

/**
 * A parabola, for smooth movement
 */
Parabola: class {

    height: Float
    length: Float

    init: func (=height, =length) {
    }

    eval: func (x: Float) -> Float {
        a := (2.0 * x / length) - 1.0
        b := a * a
        c := 1.0 - b
        c * height
    }

}
