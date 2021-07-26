function AuctipusLinkEditBoxes(frame)
    for i=1, #frame.EditBoxes - 1 do
        frame.EditBoxes[i].nextFocus = frame.EditBoxes[i + 1]
    end
    for i=2, #frame.EditBoxes do
        frame.EditBoxes[i].prevFocus = frame.EditBoxes[i - 1]
    end
    frame.EditBoxes[#frame.EditBoxes].nextFocus = frame.EditBoxes[1]
    frame.EditBoxes[1].prevFocus = frame.EditBoxes[#frame.EditBoxes]

    for i, e in ipairs(frame.EditBoxes) do
        e:SetScript("OnEscapePressed", function() e:ClearFocus() end)
        e:SetScript("OnTabPressed",
            function(f)
                if IsShiftKeyDown() then
                    f.prevFocus:SetFocus()
                else
                    f.nextFocus:SetFocus()
                end
            end
        )
    end
end
