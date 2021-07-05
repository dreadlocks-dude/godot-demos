extends Node

var MapData : Image
export var width := 128
export var height := 64

export var rooms_per_run := 4
export var min_room_size := 5
export var max_room_size := 15
export var corridor_probability := 0.5
export var corridor_hor := Vector2(50, 10)
export var corridor_vert := Vector2(10, 50)

const COLORS = {
    NONE = Color(0,0,0,0), 
    DARK = Color(0.1,0.1,0.1,1), 
    RED = Color(1,0,0,1), 
    ORANGE = Color(1,1,0,1), 
    BLUE = Color(0,0,1,1), 
    GRAY = Color(0.2,0.2,0.2,1),
    WHITE = Color(1,1,1,1), 
}

const NOISE_DISTRIBUTION = [COLORS.NONE, 
                            COLORS.GRAY, COLORS.GRAY, COLORS.GRAY, COLORS.GRAY, COLORS.GRAY,
                            COLORS.WHITE]

func _ready() -> void:
    MapData = Image.new()
    MapData.create(width, height, false, Image.FORMAT_RGBA8)
    MapData.fill(COLORS.NONE)

func randomVector(mx: Vector2) -> Vector2:
    return Vector2(randi() % int(mx.x - min_room_size) + min_room_size, 
                   randi() % int(mx.y - min_room_size) + min_room_size)

func draw_random_room():
    var dst := randomVector(MapData.get_size() + Vector2.ONE * min_room_size) - Vector2.ONE * min_room_size
    if randf() > corridor_probability:
        draw_room(dst, randomVector(Vector2.ONE * max_room_size))
    elif randf() > 0.5:
        draw_room(dst, randomVector(corridor_hor))
    else:
        draw_room(dst, randomVector(corridor_vert))


func clean():
    var c:float
    MapData.lock()
    for i in range(1, MapData.get_width() - 1):
        for j in range(1, MapData.get_height() - 1):
            c = get_red(i, j)
            if c > 0.99 and check_stray(i, j):
                MapData.set_pixel(i, j, COLORS.ORANGE)
            elif c <= 0.99 and check_gap(i, j):
                MapData.set_pixel(i, j, COLORS.BLUE)
    applyMarked()
    MapData.unlock()


func draw_room(dst: Vector2, size: Vector2):
    size.x = min(size.x, MapData.get_width() - dst.x)
    size.y = min(size.y, MapData.get_height() - dst.y)

    for i in range(size.x):
        for j in range(size.y):
            if i*j != 0 and i+1 < size.x and j+1 < size.y:
                MapData.set_pixel(dst.x + i, dst.y + j, COLORS.DARK) 
            else:
                MapData.set_pixel(dst.x + i, dst.y + j, COLORS.WHITE) 

func get_color(x, y) -> Color:
    return MapData.get_pixel(int(x), int(y))

func get_red(x, y) -> float:
    return MapData.get_pixel(int(x), int(y)).r

func is_wall(x, y):
    return int(get_red(x, y) > 0.99)

func is_floor(x, y):
    var c:float = get_red(x, y)
    return int(c > 0.01 and c < 0.99)

func check_corner(x, y):
    for i in [-1, + 1]:
        for j in [-1, + 1]:
            if is_wall(x+i, y+j) and is_wall(x+i, y) and is_wall(x, y+j):
                return true
    return false

func check_gap(x, y):
    if is_wall(x - 1, y) and is_wall(x+1, y):
        return true
    if is_wall(x, y-1) and is_wall(x, y+1):
        return true
    return false

func check_stray(x, y):
    if is_floor(x - 1, y) and is_floor(x+1, y):
        return true
    if is_floor(x, y-1) and is_floor(x, y+1):
        return true
    return false


func check_pointy_corner(x, y):
    if is_wall(x-1, y):
        if not is_wall(x+1, y) and (is_wall(x, y+1) + is_wall(x, y - 1) == 1):
            return true
    elif is_wall(x+1, y) and (is_wall(x, y+1) + is_wall(x, y - 1) == 1):
        return true
    return false

func addNoise():
    MapData.lock()

    for i in range(1, MapData.get_width() - 1):
        for j in range(1, MapData.get_height() - 1):
            if randf() > 0.92:
                MapData.set_pixel(i, j, NOISE_DISTRIBUTION[randi() % len(NOISE_DISTRIBUTION)])
    MapData.unlock()

func applyMarked():
    var cl: Color
    for i in range(1, MapData.get_width() - 1):
        for j in range(1, MapData.get_height() - 1):
            cl = get_color(i, j)
            if cl == COLORS.ORANGE:
                MapData.set_pixel(i, j, COLORS.GRAY)
            elif cl == COLORS.RED:
                MapData.set_pixel(i, j, COLORS.NONE)
            elif cl == COLORS.BLUE:
                MapData.set_pixel(i, j, COLORS.WHITE)
    
func filterPass():
    MapData.lock()
    var c : float = 0.0
    for i in range(1, MapData.get_width() - 1):
        for j in range(1, MapData.get_height() - 1):
            c = get_red(i, j)
            if c > 0.99:
                if check_pointy_corner(i, j):
                    MapData.set_pixel(i, j, COLORS.RED)
                    continue
            elif check_corner(i, j):
                MapData.set_pixel(i, j, COLORS.BLUE)
                continue

    applyMarked()
    MapData.unlock()

func generate(): 
    MapData.lock()
    for _i in range(rooms_per_run):
        draw_random_room()
    MapData.unlock()
        



