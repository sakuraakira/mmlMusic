function addSkillBooks()
  SkillBook["Music"] = {};
  SkillBook["Music"].perk = Perks.Music;
  SkillBook["Music"].maxMultiplier1 = 3;
  SkillBook["Music"].maxMultiplier2 = 5;
  SkillBook["Music"].maxMultiplier3 = 8;
  SkillBook["Music"].maxMultiplier4 = 12;
  SkillBook["Music"].maxMultiplier5 = 16;
end

Events.OnGameStart.Add(addSkillBooks);
