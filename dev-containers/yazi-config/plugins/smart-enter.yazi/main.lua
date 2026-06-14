local is_dir = ya.sync(function()
    local h = cx.active.current.hovered
    return h and h.cha.is_dir or false
end)

return {
    entry = function()
        if is_dir() then
            ya.emit("enter", {})
            ya.emit("quit", {})
        else
            ya.emit("open", {})
        end
    end,
}
