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
-- 匯出公開 API
-- ============================================
return {
  get = getScore,
  has = hasScore,
  list = listScores,
  count = getScoreCount,
  register = registerScore,
  registerBatch = registerScores
}
