local MMLScores = {}
local scoreLoaders = {}

-- ============================================
-- 註冊樂譜的函數
-- ============================================
local function registerScore(scoreName, loaderFunc)
  if type(loaderFunc) ~= "function" then
    error("Loader must be a function for: " .. scoreName)
  end
  scoreLoaders[scoreName] = loaderFunc
end

-- ============================================
-- 批次註冊多個樂譜
-- ============================================
local function registerScores(scores)
  for scoreName, loaderFunc in pairs(scores) do
    registerScore(scoreName, loaderFunc)
  end
end

-- ============================================
-- 取得樂譜資料 (延遲載入)
-- ============================================
local function getScore(scoreName)
  local loader = scoreLoaders[scoreName]
  if loader then
    return loader()
  end
  return nil
end

-- ============================================
-- 檢查樂譜是否存在
-- ============================================
local function hasScore(scoreName)
  return scoreLoaders[scoreName] ~= nil
end

-- ============================================
-- 取得所有樂譜名稱清單
-- ============================================
local function listScores()
  local list = {}
  for scoreName, _ in pairs(scoreLoaders) do
    table.insert(list, scoreName)
  end
  table.sort(list) -- 排序方便查看
  return list
end

-- ============================================
-- 取得樂譜數量
-- ============================================
local function getScoreCount()
  local count = 0
  for _ in pairs(scoreLoaders) do
    count = count + 1
  end
  return count
end


-- ============================================
-- 根據樂器隨機取得組合後的 MML 字串
-- ============================================
local InstrumentAdditions = {
  GuitarSteel = {
    'MML.1',
    'MML.2',
    'MML.3',
    'MML.5',
  },
  GuitarDistortion = {
    'MML.1',
    'MML.2',
    'MML.3',
    'MML.5',
  },
  GuitarClean = {
    'MML.1',
    'MML.2',
    'MML.3',
    'MML.5',
  },
  Piano = {
    'MML.3',
    'MML.4',
    'MML.5',
    'MML.6',
    'MML.7',
  },
  BassFinger = {
    'MML.8',
    'MML.9',
    'MML.18',
    'MML.2',
  },
  BassPick = {
    'MML.8',
    'MML.9',
    'MML.18',
    'MML.2',
  },
  Keytar = {
    'MML.3',
    'MML.4',
    'MML.5',
    'MML.6',
    'MML.7',
  },
  Flute = {
    'MML.13',
    'MML.14',
    'MML.15',
    'MML.16',
  },
  Violin = {
    'MML.13',
    'MML.14',
    'MML.15',
    'MML.16',
  },
  Trumpet = {
    'MML.10',
    'MML.11',
    'MML.12',
    'MML.19',
  },
  Saxophone = {
    'MML.17',
    'MML.18',
    'MML.19',
    'MML.11',
  }
}

local function getRandomMMLForInstrument(instrument)
  local trackType = "melody" -- 預設使用 melody 軌道
  -- 1. 檢查樂器是否存在
  local scoreList = InstrumentAdditions[instrument]
  if not scoreList or #scoreList == 0 then
    return nil
  end

  -- 2. 隨機選擇一個樂譜名稱
  local randomIndex = ZombRand(#scoreList) + 1
  local scoreName = scoreList[randomIndex]
  -- 3. 取得樂譜資料
  local score = getScore(scoreName)
  if not score then
    return nil
  end

  -- 4. 檢查 trackType 是否存在
  if not score.mml or not score.mml[trackType] then
    return nil
  end

  local track = score.mml[trackType]

  -- 5. 組合 mml1, mml2, mml3
  local mml1 = track.mml1 or ""
  local mml2 = track.mml2 or ""
  local mml3 = track.mml3 or ""

  local combined = mml1 .. "," .. mml2 .. "," .. mml3
  return combined
end
-- ============================================
-- 匯出公開 API
-- ============================================
return {
  get = getScore,
  has = hasScore,
  list = listScores,
  count = getScoreCount,
  register = registerScore,
  registerBatch = registerScores,
  getRandomMML = getRandomMMLForInstrument,
}
