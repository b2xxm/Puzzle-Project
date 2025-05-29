return {
    game = {
        intermissionDuration = 2,
        maxGameDuration = 1000
    },

    board = {
        rows = 6,
        columns = 6
    },

    playerList = {
        colours = {
            finished = Color3.fromRGB(25, 255, 140),
            unfinished = Color3.fromRGB(20, 20, 20)
        },
        toggle = {
            tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            goals = {
                [true] = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) },
                [false] = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0) }
            }
        },
        hover = {
            tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            goals = {
                [true] = { Position = UDim2.new(1, -30, 0.5, 0) },
                [false] = { Position = UDim2.new(1, -10, 0.5, 0) }
            }
        }
    },

    boardInterface = {
        padding = 3,
        colours = {
            unoccupied = Color3.fromRGB(20, 20, 20),
            occupied = {
                red = Color3.fromRGB(255, 55, 55),
                orange = Color3.fromRGB(255, 155, 55),
                yellow = Color3.fromRGB(255, 255, 55),
                green = Color3.fromRGB(55, 255, 122),
                lblue = Color3.fromRGB(55, 255, 222),
                dblue = Color3.fromRGB(55, 122, 255),
                purple = Color3.fromRGB(155, 55, 255),
                brown = Color3.fromRGB(155, 94, 33),
                grey = Color3.fromRGB(100, 100, 100)
            },
            valid = {
                transparency = 0.9,
                colour = Color3.new(1, 1, 1)
            },
            invalid = {
                transparency = 0.9,
                colour = Color3.new(1, 0.2, 0.2)
            }
        }
    }
}