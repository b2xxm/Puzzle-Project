local ReplicatedStorage = game:GetService("ReplicatedStorage")


local shared = ReplicatedStorage.Shared


local Types = require(shared.Types)


type Board = Types.Board


local submissions: { [Player]: Board } = {}


local Submissions = {}
Submissions.list = submissions


function Submissions.add(player: Player, solution: Board): ()
    submissions[player] = solution
end


function Submissions.remove(player: Player): ()
    submissions[player] = nil
end


function Submissions.clear(): ()
    table.clear(submissions)
end


function Submissions.getCount(): number
    local count = 0

    for _ in submissions do
        count += 1
    end

    return count
end


function Submissions.get(player: Player): Board?
    return submissions[player]
end


return Submissions