KEY = (x, y) ->
    return x + ',' + y

COORDS = (key) ->
    parts = key.split(",")
    x = parseInt(parts[0])
    y = parseInt(parts[1])
    return [x, y]


mirrors =
    leftmirror:
        dx: 1
        dy: 0
    rightmirror:
        dx: -1
        dy: 0
    upmirror:
        dx: 0
        dy: 1
    downmirror:
        dx: 0
        dy: -1

class Level
    canMoveTo: (x, y) ->
        key = KEY(x, y)
        cell = @cells[KEY(x, y)]
        if not cell?
            return false

        if cell.blocksMovement == false
            return {canMove: true}

        bump = getBumpMessage(cell)
        return {canMove: false, bump: bump}

    allEntities: ->
        all = []
        for key, entityList of @entities
            all = all.concat(entityList)

        return all

    constructor: (@game, opts) ->
        opts ?= {}
        @cells = {}
        @cellsByName = {}
        @entities = {}

        console.time('generating floor')
        @generate(opts)
        console.timeEnd('generating floor')

        @ambientLight = [200, 200, 200]

        @display = @game.display

    switchLevel: (delta) ->
        @game.switchLevel(delta)

    findFreeCell: ({type, room} = {}) ->
        type ?= 'floor'

        assert(typeof(type) == 'string')

        cellList = @cellsByName[type]
        assert(cellList.length)
        roomRect = if room? then Rect.fromRoom(room)

        while true
            # TODO: bust out of this loop
            key = cellList.random()

            if roomRect?
                [x, y] = COORDS(key)
                if not roomRect.containsXY(x, y)
                    continue

            assert(@cells[key] == cells[type])
            if not @entities[key]?.length
                return COORDS(key)

    lock: -> @game.lock()
    unlock: -> @game.unlock()

    addStatus: (statusMessage) ->
        @game.addStatus(statusMessage)

    setCell: (x, y, type) ->
        cell = cells[type]
        assert(cell, "unknown cell type '%s'".format(type.toString()))
        key = x+','+y

        oldCell = @cells[key]
        if oldCell?
            cellList = @cellsByName[oldCell.name]
            i = cellList.indexOf(key)
            if i != -1 then cellList.splice(i, 1)

        @cells[key] = cell

        cellList = @cellsByName[type]
        if not cellList then cellList = @cellsByName[type] = []

        cellList.push(key)

    generate: (opts) ->
        if true
            width = ROT.DEFAULT_WIDTH
            height = ROT.DEFAULT_HEIGHT
            digger = new ROT.Map.Digger(width, height)
            digger.create (x, y, val) =>
                if val == 0
                    @setCell(x, y, 'floor')

            # place walls
            for y in [0..height]
                for x in [0..width]
                    if not @cells[x+','+y]?
                        for [dx, dy] in ROT.DIRS['8']
                            if @cells[(x+dx)+','+(y+dy)] == cells.floor
                                @setCell(x, y, 'plywood')
                                break
            

            # place down stairs
            exitRoom = digger._rooms.random()
            exitRoomRect = Rect.fromRoom(exitRoom)
            [x, y] = @findFreeCell({room: exitRoom})
            @downStairs = new DownStairs(this, x, y)

            # place up stairs in a room kind of far away
            otherRooms = (r for r in digger._rooms if r != exitRoom)
            otherRooms.sort (r1, r2) ->
                a = Point.distance(Rect.fromRoom(r1).center(), exitRoomRect.center())
                b = Point.distance(Rect.fromRoom(r2).center(), exitRoomRect.center())
                return if a >= b then -1 else 1

            [x, y] = @findFreeCell({room: otherRooms[0]})

            if not opts.noUpStairs
                @upStairs = new UpStairs(this, x, y)
            else
                @upStairsPosition = [x, y]

        else
            [startx, endx] = [7, 23]
            [starty, endy] = [3, 13]

            WALLS_MIRRORED = true

            for y in [starty..endy]
                for x in [startx..endx]
                    @setCell(x, y, 'floor')

            if WALLS_MIRRORED
                for y in [starty..endy]
                    @setCell(endx+1, y, 'leftmirror')
                    @setCell(startx-1, y, 'rightmirror')
                    undefined

                for x in [startx..endx]
                    @setCell(x, endy+1, 'upmirror')
                    @setCell(x, starty-1, 'downmirror')
                    undefined

        @recalcFov()

        for i in [0..9]
            [x, y] = @findFreeCell()
            new Food(this, x, y)

    entryPosition: (delta) ->
        if delta > 0
            @upStairs?.position() or @upStairsPosition
        else
            @downStairs.position()

    recalcFov: ->
        lightPasses = (x, y) =>
            @cells[x+','+y]?.lightPasses

        @fov = new ROT.FOV.PreciseShadowcasting(lightPasses, {topology: 4})

    calcLightData: ->
        reflectivity = (x, y) => 
            @cells[x+','+y]?.reflectivity or 0

        lighting = new ROT.Lighting(reflectivity, {range: 12, passes: 2})
        lighting.setFOV(@fov)

        for key, entityList of @entities
            for entity in entityList
                lightInfo = entity.light
                if lightInfo
                    lighting.setLight(entity.getX(), entity.getY(), lightInfo.color)

        lightData = {}
        lighting.compute (x, y, color) ->
            lightData[x+','+y] = color

        return lightData

    moveEntity: (entity, x, y) ->
        otherEntities = (@entities[KEY(x, y)] or []).slice()
        for a in otherEntities
            a.bump(entity)

        @removeEntity(entity)
        entity.setPosition(x, y)
        @addEntity(entity, x, y)

        otherEntities = (@entities[KEY(x, y)] or []).slice()
        for b in otherEntities
            if b != entity
                b.afterBump(entity)

    removeEntity: (entity) ->
        x = entity.getX()
        y = entity.getY()
        entityList = @entities[KEY(x, y)]
        assert(entityList)
        found = undefined
        for e, i in entityList
            if e == entity
                found = entityList.splice(i, 1)
                assert(found[0] == e and e == entity)
                break

        assert (found)

    addEntity: (entity, x, y) ->
        key = KEY(x, y)
        entityList = @entities[key]
        if not entityList?
            entityList = @entities[key] = []

        entityList.push(entity)

    draw: ->
        lightData = @calcLightData()

        for key, cell of @cells
            [x, y] = COORDS(key)

            baseColor = if @cells[key] then [100, 100, 100] else [50, 50, 50]
            light = @ambientLight

            dynamicLight = lightData[key]
            if dynamicLight?
                light = ROT.Color.add(light, dynamicLight)

            finalColor = ROT.Color.multiply(baseColor, light)

            entityList = @entities[key]
            if entityList?.length
                topEntity = entityList[entityList.length-1]
                character = topEntity.char
                assert(character, "entity doesn't define .char")
                entityColor = topEntity.color
                if entityColor?
                    if typeof(entityColor) == 'string'
                        entityColor = ROT.Color.fromString(entityColor)

                    finalColor = ROT.Color.multiply(finalColor, entityColor)
            else
                character = cell.char

            @display.draw(x, y, character, ROT.Color.toRGB(finalColor), null)

        #
        # render mirrors
        #
        maxwidth = @display._options.width
        maxheight = @display._options.height

        for mirrorType, delta of mirrors
            cellList = @cellsByName[mirrorType] or []
            for key in cellList
                [mirrorx, mirrory] = COORDS(key)

                xDelta = delta.dx
                yDelta = delta.dy
                rayXDelta = xDelta
                rayYDelta = yDelta

                dx = 0
                dy = 0
                rayX = 0
                rayY = 0
        
                while true
                    dx += xDelta
                    dy += yDelta
                    rayX += rayXDelta
                    rayY += rayYDelta

                    [drawx, drawy] = [mirrorx + dx, mirrory + dy]
                    if drawx >= maxwidth or drawy >= maxheight or drawx < 0 or drawy < 0
                        break
                
                    cellKey = (mirrorx - rayX) + ',' + (mirrory - rayY)
                    if not @cells[cellKey]
                        break

                    args = @display._data[cellKey]
                    if not args?
                        break

                    [x, y, ch, fg, bg] = args
                    @display.draw(drawx, drawy, ch, fg, bg)

                    if ch == cells.leftmirror.char or ch == cells.rightmirror.char
                        rayXDelta = -rayXDelta
                    if ch == cells.upmirror.char or ch == cells.downmirror.char
                        rayYDelta = -rayYDelta

        undefined

window.Level = Level
