local MusicNotes = {
    notes = { 'C', 'Cs', 'D', 'Ds', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'As', 'B' },
    -- 你的音檔範圍
    minOctave = 1, -- A1 開始
    maxOctave = 6, -- E6 結束
}

function MusicNotes.isValidNote(note, octave)
    if octave < 1 or octave > 6 then return false end
    if octave == 1 and note ~= 'A' and note ~= 'As' and note ~= 'B' then
        return false
    end
    if octave == 6 and note ~= 'C' and note ~= 'Cs' and note ~= 'D' and note ~= 'Ds' and note ~= 'E' then
        return false
    end
    return true
end

return MusicNotes
