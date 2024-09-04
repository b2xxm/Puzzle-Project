local TweenService = game:GetService("TweenService")


local tweens: { [Instance]: Tween } = {}


local TweenUtils = {}


function TweenUtils.create(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
    local tween = TweenService:Create(instance, info, goal)

    tween.Completed:Once(function(_: Enum.PlaybackState)
        tween:Destroy()
        
        tweens[instance] = nil
    end)
    
    tweens[instance] = tween

    return tween
end


function TweenUtils.cancel(instance: Instance): ()
    if not instance then
        return
    end

    local tween = tweens[instance]

    if tween then
        tween:Cancel()
    end
end


return TweenUtils
