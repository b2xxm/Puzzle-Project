return {
    colours = {
        finished = Color3.fromRGB(25, 255, 140),
        unfinished = Color3.fromRGB(20, 20, 20)
    },
    toggle = {
        tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        goals = {
            [true] = { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0) },
            [false] = { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, 10, 0.5, 0) }
        }
    }
}