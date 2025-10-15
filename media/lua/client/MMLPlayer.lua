-- MMLPlayer.lua
local MMLPlayer = {}
local MMLParser = require("MMLParser")
local MusicPlayer = require("MusicPlayer")

-- 全局設定
MMLPlayer.activePlayers = {}
MMLPlayer.soundRange = nil

-- ============================================================
-- 全局設定函數
-- ============================================================
function MMLPlayer.setRange(range)
    MMLPlayer.soundRange = range
    print("[MMLPlayer] Sound range set to: " .. range)
end

function MMLPlayer.getRange()
    return MMLPlayer.soundRange or 40
end

-- ============================================================
-- 創建新的播放器實例
-- ============================================================
function MMLPlayer:new(instrument)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.instrument = instrument or "Piano"
    o.tracks = {}
    o.totalDuration = 0
    o.isPlaying = false
    o.startTime = 0
    o.updateFunc = nil
    o.sourcePlayer = nil
    o.originalMML = ""
    o.playerId = nil
    o.activeNotes = {}

    return o
end

-- ============================================================
-- 輔助函數:trim 字符串
-- ============================================================
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end


-- ============================================================
-- 統一入口:loadMML
-- 支援單字符串或逗號分隔的多軌字符串
-- ============================================================
function MMLPlayer:loadMML(mmlInput)
    if not mmlInput or mmlInput == "" then
        print("[MMLPlayer] Error: Empty MML input")
        return false
    end

    -- 將輸入字符串按逗號分割成最多 3 個 track
    local rawTracks = {}
    for token in mmlInput:gmatch("([^,]+)") do
        table.insert(rawTracks, trim(token))
        if #rawTracks >= 3 then break end
    end

    -- 補齊到 3 個 track
    while #rawTracks < 3 do
        table.insert(rawTracks, "")
    end

    -- ========== 提取 Track 1 的 tempo ==========
    local tempoToken = nil
    local track1 = rawTracks[1]
    if track1 and track1 ~= "" then
        tempoToken = track1:match('[tT]%s*%d+')
        if tempoToken then
            tempoToken = tempoToken:gsub('%s+', '') -- 移除空白: "t 120" -> "t120"
        end
    end

    -- 如果 Track 1 沒有 tempo,檢查 Track 2/3 (但會被忽略)
    if not tempoToken then
        for i = 2, 3 do
            local t = rawTracks[i]:match('[tT]%s*%d+')
            if t then
                print(string.format(
                    "[MMLPlayer] Warning: Tempo in Track %d will be ignored (only Track 1 tempo is used)", i))
                break
            end
        end
    end
    -- ============================================

    -- ========== 清理並補充預設值 ==========
    self.tracks = {}
    self.totalDuration = 0
    local sharedTempo = { value = 120 } -- 共享的 tempo reference
    local anyNotes = 0

    for i = 1, 3 do
        local s = rawTracks[i] or ""

        -- 移除所有 tempo 指令 (稍後只在 Track 1 加回)
        s = s:gsub('[tT]%s*%d+', '')
        s = trim(s)

        -- 檢查並補充 l4 和 o4
        local hasL = s:match('^%s*[lL]%d+') ~= nil
        local hasO = false

        if hasL then
            local lToken = s:match('^%s*([lL]%d+)')
            local rest = s:sub((lToken and #lToken or 0) + 1)
            hasO = rest:match('^%s*[oO]%d+') ~= nil
        else
            hasO = s:match('^%s*[oO]%d+') ~= nil
        end

        if not hasL then
            s = "l4 " .. s
        end

        -- 重新檢查是否有 o
        local checkO = (s:match('^%s*[lL]%d+%s*([oO]%d+)') or s:match('^%s*[oO]%d+'))
        if not checkO then
            s = "o4 " .. s
        end

        -- ========== 只在 Track 1 前面加上 tempo ==========
        local parseInput = s
        if i == 1 and tempoToken and parseInput ~= "" then
            parseInput = tempoToken .. " " .. parseInput
        end
        -- ==============================================

        -- ========== 創建 parser 並解析 ==========
        local parser
        if i == 1 then
            -- Track 1: 創建自己的 tempo reference
            parser = MMLParser:new()
            sharedTempo = parser.tempoRef -- 獲取 Track 1 的 tempo 引用
        else
            -- Track 2/3: 共享 Track 1 的 tempo
            parser = MMLParser:new(sharedTempo)
        end

        local seq, dur = {}, 0
        if parseInput ~= "" then
            seq, dur = parser:parse(parseInput, self.instrument)

            -- 確保 note.played 欄位存在
            for _, note in ipairs(seq) do
                note.played = false
            end

            anyNotes = anyNotes + #seq

            if dur and dur > self.totalDuration then
                self.totalDuration = dur
            end
        end

        table.insert(self.tracks, {
            sequence = seq or {},
            totalDuration = dur or 0,
            currentIndex = 1
        })
        -- ========================================
    end

    -- ========== 儲存標準化後的 MML 字符串 ==========
    local displayTracks = {}
    for i = 1, 3 do
        local s = rawTracks[i]:gsub('[tT]%s*%d+', '')
        s = trim(s)

        if s == "" then
            displayTracks[i] = ""
        else
            local hasL = s:match('^%s*[lL]%d+') ~= nil
            local checkO = nil

            if hasL then
                local lToken = s:match('^%s*([lL]%d+)')
                local rest = s:sub((lToken and #lToken or 0) + 1)
                checkO = rest:match('^%s*[oO]%d+')
            else
                checkO = s:match('^%s*[oO]%d+')
            end

            if not hasL then s = "l4 " .. s end
            if not checkO then s = "o4 " .. s end

            displayTracks[i] = trim(s)
        end
    end

    local combinedDisplay = ""
    if tempoToken and tempoToken ~= "" then
        combinedDisplay = tempoToken .. " " .. table.concat(displayTracks, ",")
    else
        combinedDisplay = table.concat(displayTracks, ",")
    end
    self.originalMML = combinedDisplay
    -- ============================================

    print(string.format("[MMLPlayer] Loaded %d tracks, %d total notes, duration: %.2fs",
        #self.tracks, anyNotes, self.totalDuration / 1000))

    return anyNotes > 0
end

-- 小別名：保持與舊 UI/呼叫端相容
function MMLPlayer:loadMMLFromCombined(mmlInput)
    return self:loadMML(mmlInput)
end

-- ============================================================
-- 獲取原始 MML 字符串(用於網絡同步)
-- ============================================================
function MMLPlayer:getMMLString()
    return self.originalMML
end

-- ============================================================
-- 設定音源玩家
-- ============================================================
function MMLPlayer:setSourcePlayer(player)
    self.sourcePlayer = player
end

-- ============================================================
-- 開始播放
-- ============================================================
function MMLPlayer:play()
    local haveNotes = false
    for _, t in ipairs(self.tracks) do
        if #t.sequence > 0 then
            haveNotes = true
            break
        end
    end

    if not haveNotes then
        print("[MMLPlayer] No notes to play!")
        return false
    end

    if self.isPlaying then
        print("[MMLPlayer] Already playing!")
        return false
    end

    self.isPlaying = true
    self.startTime = GetCurrentTimeInMs()
    self.activeNotes = {}

    -- 重置每個 track 的播放狀態與索引
    for _, t in ipairs(self.tracks) do
        t.currentIndex = 1
        for _, note in ipairs(t.sequence) do
            note.played = false
        end
    end

    -- 設定音源玩家
    local player = getPlayer()
    if self.sourcePlayer == nil then
        self.sourcePlayer = player
    end

    self.playerId = self.sourcePlayer:getOnlineID()
    MMLPlayer.activePlayers[self.playerId] = self

    print(string.format("[MMLPlayer] Starting playback (Player: %s, Instrument: %s)",
        self.playerId, self.instrument))

    -- 發送到服務器
    if isClient() and self.sourcePlayer == player then
        local MMLClientSendCommands = require("MMLClientSendCommands")
        MMLClientSendCommands.sendStartMML(
            self.playerId,
            self.instrument,
            self.originalMML,
            {
                x = player:getX(),
                y = player:getY(),
                z = player:getZ()
            }
        )
    end

    -- 註冊更新函數
    self.updateFunc = function()
        self:update()
    end
    Events.OnPostRender.Add(self.updateFunc)

    return true
end

-- ============================================================
-- 每幀更新(播放調度) - 處理多個 track 並同步啟動
-- ============================================================
function MMLPlayer:update()
    if not self.isPlaying then return end

    local currentTime = GetCurrentTimeInMs() - self.startTime
    local player = getPlayer()
    local musicPlayer = MusicPlayer.getInstance()

    -- 計算音量(基於距離)
    if self.sourcePlayer and self.sourcePlayer ~= player then
        local distance = player:DistTo(
            self.sourcePlayer:getX(),
            self.sourcePlayer:getY()
        )

        local maxRange = MMLPlayer.getRange()

        if distance > maxRange then
            self:stop()
            return
        end
    end

    -- 遍歷 track 排程播放(各 track 的 startTime 都是相對同一個 start)
    for _, t in ipairs(self.tracks) do
        local seq = t.sequence
        while t.currentIndex <= #seq do
            local noteData = seq[t.currentIndex]
            if not noteData then break end
            if currentTime >= (noteData.startTime or 0) then
                if not noteData.played then
                    local key = self:playNote(noteData)
                    noteData.played = true
                    table.insert(self.activeNotes, {
                        key = key,
                        note = noteData.note,
                        endTime = (noteData.startTime or 0) + (noteData.duration or 0)
                    })
                end
                t.currentIndex = t.currentIndex + 1
            else
                break
            end
        end
    end

    -- 停止應結束的音符(以 key 停止)
    for i = #self.activeNotes, 1, -1 do
        local activeNote = self.activeNotes[i]
        if currentTime >= activeNote.endTime then
            self:stopNote(activeNote.key)
            table.remove(self.activeNotes, i)
        end
    end

    -- 檢查是否播放完畢:所有 track 的索引都到末尾,且沒有活躍音符
    local finished = true
    for _, t in ipairs(self.tracks) do
        if t.currentIndex <= #t.sequence then
            finished = false
            break
        end
    end

    if finished and #self.activeNotes == 0 then
        self:stop()
        print("[MMLPlayer] Playback finished!")
    end
end

-- ============================================================
-- 播放單個音符
-- ============================================================
function MMLPlayer:playNote(noteData)
    local musicPlayer = MusicPlayer.getInstance()

    local key = musicPlayer:playNote(
        self.playerId,
        self.instrument,
        noteData.note,
        false
    )

    return key
end

-- ============================================================
-- 停止單個音符
-- ============================================================
function MMLPlayer:stopNote(key)
    local musicPlayer = MusicPlayer.getInstance()
    if key == nil then return end
    if musicPlayer.stopNoteByKey then
        musicPlayer:stopNoteByKey(key)
    else
        musicPlayer:stopNote(self.playerId, key)
    end
end

-- ============================================================
-- 停止播放
-- ============================================================
function MMLPlayer:stop()
    if not self.isPlaying then return end

    self.isPlaying = false

    -- 停止所有剩餘音符(使用 key)
    local musicPlayer = MusicPlayer.getInstance()
    for _, activeNote in ipairs(self.activeNotes) do
        if musicPlayer.stopNoteByKey then
            musicPlayer:stopNoteByKey(activeNote.key)
        else
            musicPlayer:stopNote(self.playerId, activeNote.note)
        end
    end
    self.activeNotes = {}

    -- 移除更新函數
    if self.updateFunc then
        Events.OnPostRender.Remove(self.updateFunc)
        self.updateFunc = nil
    end

    -- 從全局追蹤中移除
    if self.playerId then
        MMLPlayer.activePlayers[self.playerId] = nil
    end

    -- 發送停止命令
    if isClient() and self.sourcePlayer == getPlayer() then
        local MMLClientSendCommands = require("MMLClientSendCommands")
        MMLClientSendCommands.sendStopMML(self.playerId)
    end

    print("[MMLPlayer] Stopped playback")
end

-- ============================================================
-- 檢查是否正在播放
-- ============================================================
function MMLPlayer:isPlayingMusic()
    return self.isPlaying
end

-- ============================================================
-- 獲取播放進度(0.0 - 1.0)
-- ============================================================
function MMLPlayer:getProgress()
    if self.totalDuration <= 0 then return 0 end
    local currentTime = GetCurrentTimeInMs() - self.startTime
    return math.min(1.0, currentTime / self.totalDuration)
end

-- ============================================================
-- 獲取剩餘時間(秒)
-- ============================================================
function MMLPlayer:getRemainingTime()
    if not self.isPlaying then return 0 end
    local currentTime = GetCurrentTimeInMs() - self.startTime
    local remaining = math.max(0, self.totalDuration - currentTime)
    return remaining / 1000
end

-- ============================================================
-- 工具函數
-- ============================================================
function GetCurrentTimeInMs()
    return Calendar.getInstance():getTimeInMillis()
end

-- ============================================================
-- 全局函數:停止所有播放
-- ============================================================
function MMLPlayer.stopAll()
    for playerId, player in pairs(MMLPlayer.activePlayers) do
        player:stop()
    end
    print("[MMLPlayer] Stopped all playback")
end

-- ============================================================
-- 全局函數:獲取活動播放器數量
-- ============================================================
function MMLPlayer.getActivePlayerCount()
    local count = 0
    for _ in pairs(MMLPlayer.activePlayers) do
        count = count + 1
    end
    return count
end

-- ============================================================
-- 嘗試解析多個 MML 字符串,回傳每軌解析細節
-- ============================================================
function MMLPlayer:parseTracks(mmlArray)
    -- 讓驗證流程與播放一致：只採用 Track 1 的 tempo，並讓 2/3 軌共享 tempo
    local results = {}
    local rawTracks = {}

    for i = 1, 3 do
        local s = (mmlArray and mmlArray[i]) or ""
        -- 與 loadMML 一樣先淨化、去頭尾空白
        s = trim(s)
        rawTracks[i] = s or ""
    end

    -- 取出 Track 1 的 tempo（若有），並標準化格式
    local tempoToken = nil
    local track1 = rawTracks[1]
    if track1 ~= "" then
        tempoToken = track1:match('[tT]%s*%d+')
        if tempoToken then
            tempoToken = tempoToken:gsub('%s+', '')
        end
    end

    -- 建立共享 tempo 的 parser
    local sharedTempo = { value = 120 }
    local parsers = {}

    for i = 1, 3 do
        local s = rawTracks[i] or ""

        -- 移除各軌上的 tempo 指令（只保留 Track 1 的）
        s = s:gsub('[tT]%s*%d+', '')
        s = trim(s)

        -- 若缺少 L/O，補上與 loadMML 相同的預設
        local hasL = s:match('^%s*[lL]%d+') ~= nil
        local checkO
        if hasL then
            local lToken = s:match('^%s*([lL]%d+)')
            local rest = s:sub((lToken and #lToken or 0) + 1)
            checkO = rest:match('^%s*[oO]%d+')
        else
            checkO = s:match('^%s*[oO]%d+')
        end
        if not hasL then s = "l4 " .. s end
        if not checkO then s = "o4 " .. s end

        -- 只在 Track 1 前面加回 tempo
        local parseInput = s
        if i == 1 and tempoToken and parseInput ~= "" then
            parseInput = tempoToken .. " " .. parseInput
        end

        -- Track 1 建立 tempoRef，其他軌共享
        local parser
        if i == 1 then
            parser = MMLParser:new()
            sharedTempo = parser.tempoRef
        else
            parser = MMLParser:new(sharedTempo)
        end

        -- 解析，並捕捉錯誤
        local ok, seq, dur = pcall(function()
            local seq1, dur1 = parser:parse(parseInput, self.instrument)
            return seq1 or {}, dur1 or 0
        end)

        if ok then
            results[i] = { ok = true, notes = #seq, duration = dur }
        else
            results[i] = { ok = false, err = tostring(seq) }
        end
    end

    return results
end

return MMLPlayer
