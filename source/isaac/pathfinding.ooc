
// third-party stuff
use dye
import dye/[math]

use deadlogger
import deadlogger/[Log, Logger]

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
    level: Level

    logger := static Log getLogger(This name)

    init: func (=level, a, b: Vec2i) {
        // 1) Add the starting square (or node) to the open list.
        startNode := PathCell new(null, a x, a y, 0, arrivalCost(a x, a y, b))
        open add(startNode)

        lastNode: PathCell

        // 2) Repeat the following:
        while (!open empty?()) {
            sortOpenList()

            // a) Look for the lowest F cost square on the open list. We refer to this
            // as the current square.
            lowest := open removeAt(0)

            //logger info("open = %d, closed = %d", open size, closed size)
            //logger info("Testing lowest %d, %d, F/G/H costs = %.2f/%.2f/%.2f", lowest col, lowest row, lowest f, lowest g, lowest h)

            // b) Switch it to the closed list.
            closed add(lowest)

            if (lowest col == b x && lowest row == b y) {
                // we added the end node to the closed list, it's done
                //logger info("Done, lastNode = %d, %d", lowest col, lowest row)
                lastNode = lowest
                break
            }

            // c) For each of the 8 squares adjacent to this current square …
            x := lowest col
            y := lowest row

            testNeighbor := func (dx, dy: Int, g: Float) {
                col := x + dx
                row := y + dy

                // If it is not walkable or if it is on the closed list, ignore it.
                // Otherwise do the following.           
                for (c in closed) {
                    if (c col == col && c row == row) {
                        return // ignore
                    }
                }
            
                if (!walkable?(col, row)) {
                    return // ignore
                }
                
                // handle impossible diagonals
                // ie. something like that:
                //
                //   #b    you can't walk straight from a to b
                //   a#    but the previous version of the algorithm allowed it.
                //
                if (dx != 0 && dy != 0) { // diagonal?
                    (cola, rowa) := (x + dx, y)
                    (colb, rowb) := (x, y + dy)
                    if (!walkable?(cola, rowa) && !walkable?(colb, rowb)) {
                        // if both are not walkable, it means we can't go through
                        return // ignore
                    }

                }

                alreadyAdded := false
                for (o in open) {
                    if (o col == col && o row == row) {
                        alreadyAdded = true

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

                if (!alreadyAdded) {
                    // If it isn’t on the open list, add it to the open list. Make the current
                    // square the parent of this square. Record the F, G, and H costs of the
                    // square. 
                    node := PathCell new(lowest, col, row, lowest g + g, arrivalCost(col, row, b))
                    open add(node)
                }
            }

            testNeighbor(-1, -1, 14)
            testNeighbor(-1, 0, 10)
            testNeighbor(-1, 1, 14)
            testNeighbor(0, 1, 10)
            testNeighbor(0 + 1, 1, 14)
            testNeighbor(0 + 1, 0, 10)
            testNeighbor(0 + 1, -1, 14)
            testNeighbor(0, -1, 10)

            // d) Stop when you:

            // Add the target square to the closed list, in which case the path has
            // been found (see note below), or Fail to find the target square, and the
            // open list is empty. In this case, there is no path.   
        }

        // 3) Save the path. Working backwards from the target square, go from
        // each square to its parent square until you reach the starting
        // square. That is your path.
        if (!lastNode) {
            return // no path
        }

        path = ArrayList<Vec2i> new()
        path add(vec2i(lastNode col, lastNode row))

        while (lastNode parent) {
            lastNode = lastNode parent
            path add(0, vec2i(lastNode col, lastNode row))
        }
    }

    walkable?: func (col, row: Int) -> Bool {
        if (!level tileGrid validCoords?(col, row)) {
            return false // ignore
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

        walkable
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
    arrivalCost: func (col, row: Int, b: Vec2i) -> Float {
        xDistance := ((col - b x) as Float) abs()
        yDistance := ((row - b y) as Float) abs()

        if (xDistance > yDistance) {
            return 14.0 * yDistance + 10.0 * (xDistance - yDistance)
        } else {
            return 14.0 * xDistance + 10.0 * (yDistance - xDistance)
        }
    }

}

PathCell: class {

    parent: This
    col, row: Int

    f: Float // g + h
    g: Float // movement cost from starting point (computed)
    h: Float // movement cost to arrival (guesstimated)

    init: func (=parent, =col, =row, =g, =h) {
        f = g + h
    }

}

