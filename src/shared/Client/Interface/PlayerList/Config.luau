return {
    colours = {
        finished = Color3.fromRGB(25, 255, 140),
        unfinished = Color3.fromRGB(20, 20, 20)
    },
    toggle = {
        tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        goals = {
            [true] = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) },
            [false] = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 20, 0.5, 0) }
        }
    },
    hover = {
        tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        goals = {
            [true] = { Position = UDim2.new(1, -30, 0.5, 0) },
            [false] = { Position = UDim2.new(1, -10, 0.5, 0) }
        }
    }
}