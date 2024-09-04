local TweenService = game:GetService("TweenService")


local tweens: { [Instance]: Tween } = {}


local TweenUtils = {}


function TweenUtils.create(instance: Instance, info: TweenInfo, goal: { [string]: any }): Tween
    local tween = TweenService:Create(instance, info, goal)

    tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
        if playbackState ~= Enum.PlaybackState.Completed then
            if playbackState ~= Enum.PlaybackState.Cancelled then
                return
            end
        end

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
