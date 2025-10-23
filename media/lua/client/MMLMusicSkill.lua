-- MMLMusicSkill.lua

MMLMusicSkill = {}
MMLMusicSkill.perkID = "Music"            -- 內部 ID
MMLMusicSkill.displayName = "Music Skill" -- UI 顯示名稱
MMLMusicSkill.parent = "Crafting"         -- 父分類

function MMLMusicSkill.registerPerk()
  local musicianTrait = TraitFactory.addTrait("musician", getText("UI_trait_Musician"), 2,
    getText("UI_trait_Musiciandesc"), false, false)
  musicianTrait:addXPBoost(Perks.Music, 2)
  if getActivatedMods():contains("ModernMayhem") ~= true then
    local Singer = ProfessionFactory.addProfession(
      "singer",
      getText("UI_prof_Singer"),
      "profession_singer",
      3,
      getText("UI_prof_singerdesc")
    )
    Singer:addXPBoost(Perks.Music, 2)
    Singer:addXPBoost(Perks.Lightfoot, 2)

    local profList = ProfessionFactory.getProfessions()
    for i = 1, profList:size() do
      local prof = profList:get(i - 1)
      BaseGameCharacterDetails.SetProfessionDescription(prof)
    end
  end
end

-- 為指定角色增加 Music 經驗（自動檢測使用哪種系統）
function MMLMusicSkill.addXP(character, xpAmount)
  if not character or not xpAmount or xpAmount == 0 then return end
  local toAdd = xpAmount
  character:getXp():AddXP(Perks.Music, toAdd)
end

-- 取得指定角色的 Music 等級
function MMLMusicSkill.getLevel(character)
  if not character then return 0 end
  local lvl = character:getPerkLevel(Perks.Music)
  if lvl == 0 then return 2 end
  return lvl * 2.5
end

-- 便利函式：回傳 Perk ID
function MMLMusicSkill.getPerkID()
  return MMLMusicSkill.perkID
end

return MMLMusicSkill
