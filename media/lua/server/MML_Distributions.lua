if not isServer() then return end

require 'Items/SuburbsDistributions'
require 'Items/ProceduralDistributions'
require "Vehicles/VehicleDistributions"

---------------------------------------
-- 小工具：安全插入（不會因 nil 當掉）
---------------------------------------
local function addProc(listName, fullType, weight)
  local list = ProceduralDistributions.list[listName]
  if not list then return end
  list.items = list.items or {}
  table.insert(list.items, fullType)
  table.insert(list.items, weight)
end

local function addVehicle(containerName, fullType, weight)
  local vc = VehicleDistributions[containerName]
  if not vc then return end
  vc.items = vc.items or {}
  table.insert(vc.items, fullType)
  table.insert(vc.items, weight)
end

local Instrument = {
  "GuitarAcoustic",
  "Banjo",
  "GuitarElectricBlack",
  "GuitarElectricBlue",
  "GuitarElectricRed",
  "GuitarElectricBassBlack",
  "GuitarElectricBassBlue",
  "GuitarElectricBassRed",
  "Keytar",
  "Flute",
  "Saxophone",
  "Trumpet",
  "Violin"
}

local Sheets = {
  "MMLSheet.Courage",
  "MMLSheet.Unravel",
  "MMLSheet.Tokyo_teddy_bear",
  "MMLSheet.Bluebird",
  "MMLSheet.Magnet",
  "MMLSheet.God_knows",
  "MMLSheet.Senbonzakura",
  "MMLSheet.Butterfly",
  "MMLSheet.ThoughMySongHasNoShape",
  "MMLSheet.TheGame",
}

addProc("PostOfficeBooks", "MMLSheet.MusicSkill_Book1", 2)
addProc("PostOfficeBooks", "MMLSheet.MusicSkill_Book2", 1)
addProc("PostOfficeBooks", "MMLSheet.MusicSkill_Book3", 0.5)
addProc("PostOfficeBooks", "MMLSheet.MusicSkill_Book4", 0.2)
addProc("PostOfficeBooks", "MMLSheet.MusicSkill_Book5", 0.1)
addProc("PostOfficeBooks", "MMLSheet.BlankSheetBook", 0.1)
addProc("PostOfficeBooks", "MMLSheet.BlankSheet", 0.5)

addProc("BookstoreBooks", "MMLSheet.MusicSkill_Book1", 10)
addProc("BookstoreBooks", "MMLSheet.MusicSkill_Book2", 8)
addProc("BookstoreBooks", "MMLSheet.MusicSkill_Book3", 6)
addProc("BookstoreBooks", "MMLSheet.MusicSkill_Book4", 4)
addProc("BookstoreBooks", "MMLSheet.MusicSkill_Book5", 2)
addProc("BookstoreBooks", "MMLSheet.BlankSheetBook", 2)
addProc("BookstoreBooks", "MMLSheet.BlankSheet", 1)

addProc("LibraryBooks", "MMLSheet.MusicSkill_Book1", 8)
addProc("LibraryBooks", "MMLSheet.MusicSkill_Book2", 6)
addProc("LibraryBooks", "MMLSheet.MusicSkill_Book3", 4)
addProc("LibraryBooks", "MMLSheet.MusicSkill_Book4", 2)
addProc("LibraryBooks", "MMLSheet.MusicSkill_Book5", 1)
addProc("LibraryBooks", "MMLSheet.BlankSheetBook", 2)
addProc("LibraryBooks", "MMLSheet.BlankSheet", 4)

addProc("LivingRoomShelf", "MMLSheet.MusicSkill_Book1", 2)
addProc("LivingRoomShelf", "MMLSheet.MusicSkill_Book2", 1)
addProc("LivingRoomShelf", "MMLSheet.MusicSkill_Book3", 0.5)
addProc("LivingRoomShelf", "MMLSheet.MusicSkill_Book4", 0.2)
addProc("LivingRoomShelf", "MMLSheet.MusicSkill_Book5", 0.1)
addProc("LivingRoomShelf", "MMLSheet.BlankSheetBook", 0.01)
addProc("LivingRoomShelf", "MMLSheet.BlankSheet", 1)

addProc("ClassroomMisc", "MMLSheet.MusicSkill_Book1", 2)
addProc("ClassroomMisc", "MMLSheet.MusicSkill_Book2", 1)
addProc("ClassroomMisc", "MMLSheet.MusicSkill_Book3", 0.5)
addProc("ClassroomMisc", "MMLSheet.MusicSkill_Book4", 0.2)
addProc("ClassroomMisc", "MMLSheet.MusicSkill_Book5", 0.1)
addProc("ClassroomMisc", "MMLSheet.BlankSheetBook", 0.05)
addProc("ClassroomMisc", "MMLSheet.BlankSheet", 2)


addProc("ClassroomShelves", "MMLSheet.MusicSkill_Book1", 2)
addProc("ClassroomShelves", "MMLSheet.MusicSkill_Book2", 1)
addProc("ClassroomShelves", "MMLSheet.MusicSkill_Book3", 0.5)
addProc("ClassroomShelves", "MMLSheet.MusicSkill_Book4", 0.2)
addProc("ClassroomShelves", "MMLSheet.MusicSkill_Book5", 0.1)
addProc("ClassroomShelves", "MMLSheet.BlankSheetBook", 0.05)
addProc("ClassroomShelves", "MMLSheet.BlankSheet", 2)

addProc("LivingRoomShelfNoTapes", "MMLSheet.MusicSkill_Book1", 2)
addProc("LivingRoomShelfNoTapes", "MMLSheet.MusicSkill_Book2", 1)
addProc("LivingRoomShelfNoTapes", "MMLSheet.MusicSkill_Book3", 0.5)
addProc("LivingRoomShelfNoTapes", "MMLSheet.MusicSkill_Book4", 0.2)
addProc("LivingRoomShelfNoTapes", "MMLSheet.MusicSkill_Book5", 0.1)
addProc("LivingRoomShelfNoTapes", "MMLSheet.BlankSheetBook", 0.05)
addProc("LivingRoomShelfNoTapes", "MMLSheet.BlankSheet", 2)

addProc("MagazineRackMixed", "MMLSheet.BlankSheet", 0.8)
addProc("CrateRandomJunk", "MMLSheet.BlankSheet", 0.5)
addProc("FilingCabinetGeneric", "MMLSheet.BlankSheet", 0.5)

addProc("Antiques", "Flute", 4)
addProc("Antiques", "Saxophone", 4)
addProc("Antiques", "Trumpet", 4)
addProc("Antiques", "Keytar", 4)

addProc("MusicStoreSpeaker", "MMLSheet.BlankSheetBook", 5)
addProc("MusicStoreSpeaker", "MMLSheet.BlankSheet", 20)
addProc("BookstoreMisc", "MMLSheet.BlankSheet", 5)
addProc("BandMerchShelves", "MMLSheet.BlankSheet", 5)
addProc("BandMerchShelves", "MMLSheet.BlankSheetBook", 1)
addProc("SchoolLockers", "MMLSheet.BlankSheetBook", 0.01)
addProc("SchoolLockers", "MMLSheet.BlankSheet", 0.1)

for _, name in ipairs(Instrument) do
  addProc("BandPracticeInstruments", name, 8)
  addProc("ClosetInstruments", name, 8)
  addProc("CrateInstruments", name, 8)
  addProc("CrateRandomJunk", name, 0.5)
  addProc("WardrobeMan", name, 0.02)
  addProc("WardrobeManClassy", name, 0.04)
  addProc("LockerClassy", name, 0.04)
  addProc("SchoolLockers", name, 0.01)
end

for _, name in ipairs(Sheets) do
  addProc("ClassroomShelves", name, 0.05)
  addProc("ClassroomMisc", name, 0.05)
  addProc("PostOfficeBooks", name, 0.05)
  addProc("BookstoreBooks", name, 0.02)
  addProc("LibraryBooks", name, 0.01)
  addProc("BandMerchShelves", name, 2)
  addProc("BandPracticeInstruments", name, 2)
  addProc("ClosetInstruments", name, 2)
  addProc("CrateInstruments", name, 2)
  addProc("SchoolLockers", name, 0.01)
end
