
// third-party stuff
use dye
import dye/[math]

// sdk stuff
import structs/[ArrayList, List]

// our stuff
import isaac/[level, tiles, hole]

/**
 * An implementation of A*
 *
 * Reference: http://www.policyalmanac.org/games/aStarTutorial.htm
 */
PathFinder: class {

    open := ArrayList<PathCell> new()
    closed := ArrayList<PathCell> new()

    path: ArrayList<Vec2i>

    init: func (level: Level, a, b: Vec2i) {
        // 1) Add the starting square (or node) to the open list.
        startNode := PathCell new(null, a, 0, arrivalCost(a, b))
        open add(startNode)

        lastNode: PathCell

        // 2) Repeat the following:
        while (!open empty?()) {
            sortOpenList()

            // a) Look for the lowest F cost square on the open list. We refer to this
            // as the current square.
            lowest := open removeAt(0)

            // b) Switch it to the closed list.
            closed add(lowest)

            if (lowest pos equals(b)) {
                // we added the end node to the closed list, it's done
                lastNode = lowest
                break
            }

            // c) For each of the 8 squares adjacent to this current square …

            testNeighbor := func (col, row: Int, g: Float) {
                // If it is not walkable or if it is on the closed list, ignore it.
                // Otherwise do the following.           
                for (c in closed) {
                    if (c pos x == col && c pos y == row) {
                        return // ignore
                    }
                }

                if (!level tileGrid validCoords?(col, row)) {
                    return // ignore
                }

                walkable := true

                tile := level tileGrid get(col, row)
                match tile {
                    case null =>
                        // walkable alright!
                    case block: Block =>
                        walkable = false
                    case poop: Poop =>
                        walkable = false
                    case hole: Hole =>
                        walkable = false
                }

                if (!walkable) {
                    return // ignore
                }

                for (o in open) {
                    if (o pos x == col && o pos y == row) {
                        // If it is on the open list already, check to see if
                        // this path to that square is better, using G cost as
                        // the measure. A lower G cost means that this is a
                        // better path. If so, change the parent of the square
                        // to the current square, and recalculate the G and F
                        // scores of the square.  If you are keeping your open
                        // list sorted by F score, you may need to resort the
                        // list to account for the change.

                        newG := lowest g + g
                        if (newG < o g) {
                            o parent = lowest
                        }
                    }
                }

                // If it isn’t on the open list, add it to the open list. Make the current
                // square the parent of this square. Record the F, G, and H costs of the
                // square. 
                pos := vec2i(col, row)
                node := PathCell new(lowest, pos, lowest g + g, arrivalCost(pos, b))
                open add(node)
            }

            x := lowest pos x
            y := lowest pos y
            testNeighbor(x - 1, y - 1, 14)
            testNeighbor(x - 1, y, 10)
            testNeighbor(x - 1, y + 1, 14)
            testNeighbor(x, y + 1, 10)
            testNeighbor(x + 1, y + 1, 14)
            testNeighbor(x + 1, y, 10)
            testNeighbor(x + 1, y - 1, 14)
            testNeighbor(x, y - 1, 10)

            // d) Stop when you:

            // Add the target square to the closed list, in which case the path has
            // been found (see note below), or Fail to find the target square, and the
            // open list is empty. In this case, there is no path.   
        }

        // 3) Save the path. Working backwards from the target square, go from
        // each square to its parent square until you reach the starting
        // square. That is your path.
        if (!lastNode) {
            return null // no path
        }

        path = ArrayList<Vec2i> new()
        path add(lastNode pos)

        while (lastNode parent) {
            lastNode = lastNode parent
            path add(0, lastNode pos)
        }
    }

    /**
     * Sort the open list so that the lowest values are at the end
     */
    sortOpenList: func {
        open sort(|a, b| a f > b f)
    }

    /**
     * Using the 'diagonal shortcut' method outlined here:
     * http://www.policyalmanac.org/games/heuristics.htm
     */
    arrivalCost: func (a, b: Vec2i) -> Float {
        xDistance := ((a x - b x) as Float) abs()
        yDistance := ((a y - b y) as Float) abs()

        if (xDistance > yDistance) {
            return 14.0 * yDistance + 10.0 * (xDistance - yDistance)
        } else {
            return 14.0 * xDistance + 10.0 * (yDistance - xDistance)
        }
    }

}

PathCell: class {

    parent: This
    pos: Vec2i

    f: Float // g + h
    g: Float // movement cost from starting point (computed)
    h: Float // movement cost to arrival (guesstimated)

    init: func (=parent, =pos, =g, =h) {
        f = g + h
    }

}

