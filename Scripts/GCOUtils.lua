--=====================================================================================--
--	FILE:	 GCOUtils.lua
--  Gedemon (2017)
--=====================================================================================--

print ("Loading GCOUtils.lua...")

-----------------------------------------------------------------------------------------
-- Defines
-----------------------------------------------------------------------------------------

-- This should be the first loading file (to do : make sure of that !), do some cleaning if Events.LeaveGameComplete hasn't fired on returning to main menu or loading a game...
ExposedMembers.SaveLoad_Initialized = nil
ExposedMembers.Utils_Initialized = nil

-----------------------------------------------------------------------------------------
-- Initialize Functions
-----------------------------------------------------------------------------------------

GCO = {}
function InitializeUtilityFunctions() 	-- Get functions from other contexts
	if ExposedMembers.SaveLoad_Initialized and ExposedMembers.Utils_Initialized then -- can't use GameEvents.ExposedFunctionsInitialized.TestAll() because it will be called before all required test are added to the event...
		GCO = ExposedMembers.GCO		-- contains functions from other contexts
		Events.GameCoreEventPublishComplete.Remove( InitializeUtilityFunctions )
		print ("Exposed Functions from other contexts initialized...")
	end
end
Events.GameCoreEventPublishComplete.Add( InitializeUtilityFunctions )

-----------------------------------------------------------------------------------------
-- Maths
-----------------------------------------------------------------------------------------
function Round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function Shuffle(t)
  local n = #t
 
  while n >= 2 do
    -- n is now the last pertinent index
    local k = math.random(n) -- 1 <= k <= n
    -- Quick swap
    t[n], t[k] = t[k], t[n]
    n = n - 1
  end
 
  return t
end

function GetSize(t)

	if type(t) ~= "table" then
		return 1 
	end

	local n = #t 
	if n == 0 then
		for k, v in pairs(t) do
			n = n + 1
		end
	end 
	return n
end

----------------------------------------------
-- Civilizations
----------------------------------------------

function CreateEverAliveTableWithDefaultValue(value)
	local t = {}
	for i, playerID in ipairs(PlayerManager.GetWasEverAliveIDs()) do
		t[playerID] = value
	end
	return t
end


----------------------------------------------
-- Units
----------------------------------------------

-- return unique key for units table [unitID,playerID]
function GetUnitKey(unit)
	if unit then
		local ownerID = unit:GetOwner()
		local unitID = unit:GetID()
		local unitKey = unitID..","..ownerID
		return unitKey
	else
		print("- WARNING: unit is nil for GetUnitKey()")
	end
end
ExposedMembers.GetUnitKey = GetUnitKey -- to use in UnitFlagManager.lua (no need to delay initialization, UI context are loaded after script context)

function GetUnitFromKey ( unitKey )
	if ExposedMembers.UnitData[unitKey] then
		local unit = UnitManager.GetUnit(ExposedMembers.UnitData[unitKey].playerID, ExposedMembers.UnitData[unitKey].unitID)
		if unit then
			return unit
		else
			print("- WARNING: unit is marked alive but is nil for GetUnitFromKey(), marking as dead")
			print("--- UnitId = " .. ExposedMembers.UnitData[unitKey].UnitID ..", playerID = " .. ExposedMembers.UnitData[unitKey].playerID )
			ExposedMembers.UnitData[unitKey].Alive = false
		end
	else
		print("- WARNING: ExposedMembers.UnitData[unitKey] is nil for GetUnitFromKey()")
	end
end

function GetPersonnelReserve(unitType)
	return Round((GameInfo.Units[unitType].Personnel * GameInfo.GlobalParameters["UNIT_RESERVE_RATIO"].Value / 1000) * 10)
end

function GetVehiclesReserve(unitType)
	return Round((GameInfo.Units[unitType].Vehicles * GameInfo.GlobalParameters["UNIT_RESERVE_RATIO"].Value / 1000) * 10)
end

function GetHorsesReserve(unitType)
	return Round((GameInfo.Units[unitType].Horses * GameInfo.GlobalParameters["UNIT_RESERVE_RATIO"].Value / 1000) * 10)
end

function GetMaterielReserve(unitType)
	return Round(GameInfo.Units[unitType].Materiel -- 100% stock for materiel reserve
end

function GetFoodConsumption(unitData)
	local foodConsumption1000 = 0
	foodConsumption1000 = foodConsumption1000 + ((unitData.Personnel + unitData.PersonnelReserve)*GameInfo.GlobalParameters["FOOD_CONSUMPTION_PERSONNEL_FACTOR"].Value)
	foodConsumption1000 = foodConsumption1000 + ((unitData.Horses + unitData.HorsesReserve)*GameInfo.GlobalParameters["FOOD_CONSUMPTION_HORSES_FACTOR"].Value)
	-- value belows may be nil
	if unitData.Wounded then
		foodConsumption1000 = foodConsumption1000 + (unitData.Wounded *GameInfo.GlobalParameters["FOOD_CONSUMPTION_WOUNDED_FACTOR"].Value)
	end
	if unitData.Prisonners then	
		foodConsumption1000 = foodConsumption1000 + (unitData.Prisonners *GameInfo.GlobalParameters["FOOD_CONSUMPTION_PRISONNERS_FACTOR"].Value)
	end	
	return math.max(1, Round( foodConsumption1000 / 1000 ))
end

function GetFoodConsumptionString(unitData)
	local str = ""
	local totalPersonnel = unitData.Personnel + unitData.PersonnelReserve
	if totalPersonnel > 0 then 
		local personnelFood = (totalPersonnel*GameInfo.GlobalParameters["FOOD_CONSUMPTION_PERSONNEL_FACTOR"].Value)/1000
		str = str .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_FOOD_CONSUMPTION_PERSONNEL", personnelFood, totalPersonnel) 
	end	
	local totalHorses = unitData.Horses + unitData.HorsesReserve
	if totalHorses > 0 then 
		local horsesFood = (totalHorses*GameInfo.GlobalParameters["FOOD_CONSUMPTION_HORSES_FACTOR"].Value)/1000
		str = str .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_FOOD_CONSUMPTION_HORSES", horsesFood, totalHorses ) 
	end
	
	-- value belows may be nil
	if unitData.Wounded and unitData.Wounded > 0 then 
		local woundedFood = (unitData.Wounded*GameInfo.GlobalParameters["FOOD_CONSUMPTION_WOUNDED_FACTOR"].Value)/1000
		str = str .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_FOOD_CONSUMPTION_WOUNDED", woundedFood, unitData.Wounded ) 
	end
	if unitData.Prisonners then			
		local prisonnersFood = (unitData.Prisonners*GameInfo.GlobalParameters["FOOD_CONSUMPTION_PRISONNERS_FACTOR"].Value)/1000
		str = str .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_FOOD_CONSUMPTION_PRISONNERS", prisonnersFood, unitData.Prisonners )
	end	
	return str
end

function GetBaseFoodStock(unitType)
	local unitData = {} 
	unitData.Personnel 			= GameInfo.Units[unitType].Personnel
	unitData.Horses 			= GameInfo.Units[unitType].Horses
	unitData.PersonnelReserve	= GetPersonnelReserve(unitType)
	unitData.HorsesReserve 		= GetHorsesReserve(unitType)	
	return GetFoodConsumption(unitData)*5 -- set enough stock for 5 turns
end

function GetTotalPrisonners(data)
	local prisonners = 0
	for playerID, number in pairs(data.Prisonners) do
		prisonners = prisonners + number
	end	
	return prisonners
end

function GetPrisonnersStringByCiv(data)
	local sortedPrisonners = {}
	for playerID, number in pairs(data.Prisonners) do
		table.insert(sortedPrisonners, {playerID = playerID, Number = number})
	end	
	table.sort(sortedPrisonners, function(a,b) return a.Number>b.Number end)
	local numLines = tonumber(GameInfo.GlobalParameters["MAX_PRISONNERS_LINE_IN_UNIT_FLAG"].Value)
	local str = ""
	local other = 0
	local iter = 1
	for i, t in ipairs(sortedPrisonners) do
		if (iter <= numLines) or (#sortedPrisonners == numLines + 1) then
			local playerConfig = PlayerConfigurations[t.playerID]
			local civAdjective = Locale.Lookup(GameInfo.Civilizations[playerConfig:GetCivilizationTypeID()].Adjective)
			if t.Number > 0 then str = str .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_PRISONNERS_NATIONALITY", t.Number, civAdjective) end
		else
			other = other + t.Number
		end
		iter = iter + 1
	end
	if other > 0 then str = str .. "[NEWLINE]" .. Locale.Lookup("LOC_UNITFLAG_PRISONNERS_OTHER_NATIONALITY", other) end
	return str
end

function GetMaxTransfertTable(unit)
	local maxTranfert = {}
	local unitType = unit:GetType()
	local unitInfo = GameInfo.Units[unit:GetType()]
	maxTranfert.Personnel = GameInfo.GlobalParameters["MAX_PERSONNEL_TRANSFERT_FROM_RESERVE"].Value
	maxTranfert.Materiel = GameInfo.GlobalParameters["MAX_MATERIEL_TRANSFERT_FROM_RESERVE"].Value
	return maxTranfert
end

function AddCombatInfoTo(Opponent)

	Opponent.unit = UnitManager.GetUnit(Opponent.playerID, Opponent.unitID)
	if Opponent.unit then
		Opponent.unitType = Opponent.unit:GetType()
		Opponent.unitKey = GetUnitKey(Opponent.unit)
		Opponent.IsLandUnit = GameInfo.Units[Opponent.unitType].Domain == "DOMAIN_LAND"
		-- Max number of prisonners can't be higher than the unit's operationnal number of personnel or the number of remaining valid personnel x10
		Opponent.MaxPrisonners = math.min(GameInfo.Units[Opponent.unitType].Personnel, (ExposedMembers.UnitData[Opponent.unitKey].Personnel+ExposedMembers.UnitData[Opponent.unitKey].PersonnelReserve)*10)
		local diff = (Opponent.MaxPrisonners - GCO.GetTotalPrisonners(ExposedMembers.UnitData[Opponent.unitKey]))
		if diff > 0 then
			Opponent.MaxCapture = GCO.Round(diff * GameInfo.GlobalParameters["CAPTURE_RATIO_FROM_PRISONNERS_CAPACITY"].Value/100)
		else
			Opponent.MaxCapture = 0
		end
		Opponent.AntiPersonnel = GameInfo.Units[Opponent.unitType].AntiPersonnel
	end	

	return Opponent
end

function AddFrontLineCasualtiesInfoTo(Opponent)

	if Opponent.IsDead then

		Opponent.FinalHP = 0
		Opponent.PersonnelCasualties 	= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Personnel
		Opponent.VehiclesCasualties 	= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Vehicles
		Opponent.HorsesCasualties 		= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Horses
		Opponent.MaterielCasualties 	= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Materiel

		-- "Kill" the unit
		ExposedMembers.UnitData[Opponent.unitKey].Personnel = 0
		ExposedMembers.UnitData[Opponent.unitKey].Vehicles  = 0
		ExposedMembers.UnitData[Opponent.unitKey].Horses	= 0
		ExposedMembers.UnitData[Opponent.unitKey].Materiel 	= 0
		ExposedMembers.UnitData[Opponent.unitKey].Alive 	= false
	else
		Opponent.PersonnelCasualties 	= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Personnel 	- ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.FinalHP].Personnel
		Opponent.VehiclesCasualties 	= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Vehicles 	- ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.FinalHP].Vehicles
		Opponent.HorsesCasualties 		= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Horses		- ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.FinalHP].Horses
		Opponent.MaterielCasualties		= ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.InitialHP].Materiel 	- ExposedMembers.UnitHitPointsTable[Opponent.unitType][Opponent.FinalHP].Materiel

		-- Remove casualties from frontline
		ExposedMembers.UnitData[Opponent.unitKey].Personnel = ExposedMembers.UnitData[Opponent.unitKey].Personnel  	- Opponent.PersonnelCasualties
		ExposedMembers.UnitData[Opponent.unitKey].Vehicles  = ExposedMembers.UnitData[Opponent.unitKey].Vehicles  	- Opponent.VehiclesCasualties 
		ExposedMembers.UnitData[Opponent.unitKey].Horses	= ExposedMembers.UnitData[Opponent.unitKey].Horses	  	- Opponent.HorsesCasualties 			
		ExposedMembers.UnitData[Opponent.unitKey].Materiel 	= ExposedMembers.UnitData[Opponent.unitKey].Materiel 	- Opponent.MaterielCasualties 		
	end

	return Opponent
end

function AddCasualtiesInfoByTo(OpponentA, OpponentB)

	-- Send wounded to the rear, bury the dead, take prisonners
	if OpponentA.AntiPersonnel then
		OpponentB.Dead = Round(OpponentB.PersonnelCasualties * OpponentA.AntiPersonnel / 100)
	else
		OpponentB.Dead = Round(OpponentB.PersonnelCasualties * GameInfo.GlobalParameters["DEFAULT_ANTIPERSONNEL_RATIO"].Value / 100)
	end	
	if OpponentA.CanTakePrisonners then	
		if OpponentA.CapturedPersonnelRatio then
			OpponentB.Captured = Round((OpponentB.PersonnelCasualties - OpponentB.Dead) * OpponentA.CapturedPersonnelRatio / 100)
		else
			OpponentB.Captured = Round((OpponentB.PersonnelCasualties - OpponentB.Dead) * GameInfo.GlobalParameters["DEFAULT_CAPTURED_PERSONNEL_RATIO"].Value / 100)
		end	
		if OpponentA.MaxCapture then
			OpponentB.Captured = math.min(OpponentA.MaxCapture, OpponentB.Captured)
		end
	else
		OpponentB.Captured = 0
	end	
	OpponentB.Wounded = OpponentB.PersonnelCasualties - OpponentB.Dead - OpponentB.Captured
	
	-- Salvage Vehicles
	OpponentB.VehiclesLost = GCO.Round(OpponentB.VehiclesCasualties / 2) -- hardcoded for testing, to do : get Anti-Vehicule stat (anti-tank, anti-ship, anti-air...) from opponent, maybe use also era difference (asymetry between weapon and protection used)
	OpponentB.DamagedVehicles = OpponentB.VehiclesCasualties - OpponentB.VehiclesLost
	
	-- They Shoot Horses, Don't They?
	OpponentB.HorsesLost = OpponentB.HorsesCasualties -- some of those may be captured by the opponent ?
	
	-- Materiel too is a full lost
	OpponentB.MaterielLost = OpponentB.MaterielCasualties
				
	-- Apply Casualties	transfert
	ExposedMembers.UnitData[OpponentB.unitKey].WoundedPersonnel = ExposedMembers.UnitData[OpponentB.unitKey].WoundedPersonnel 	+ OpponentB.Wounded
	ExposedMembers.UnitData[OpponentB.unitKey].DamagedVehicles 	= ExposedMembers.UnitData[OpponentB.unitKey].DamagedVehicles 	+ OpponentB.DamagedVehicles
	
	-- Update Stats
	ExposedMembers.UnitData[OpponentB.unitKey].TotalDeath			= ExposedMembers.UnitData[OpponentB.unitKey].TotalDeath 		+ OpponentB.Dead
	ExposedMembers.UnitData[OpponentB.unitKey].TotalVehiclesLost	= ExposedMembers.UnitData[OpponentB.unitKey].TotalVehiclesLost 	+ OpponentB.VehiclesLost
	ExposedMembers.UnitData[OpponentB.unitKey].TotalHorsesLost 		= ExposedMembers.UnitData[OpponentB.unitKey].TotalHorsesLost 	+ OpponentB.HorsesLost

	return OpponentB
end

----------------------------------------------
-- Initialize functions for other contexts
----------------------------------------------

function Initialize()
	if not ExposedMembers.GCO then ExposedMembers.GCO = {} end
	ExposedMembers.GCO.Round = Round
	ExposedMembers.GCO.Shuffle = Shuffle
	ExposedMembers.GCO.GetSize = GetSize
	ExposedMembers.GCO.GetUnitKey = GetUnitKey
	ExposedMembers.GCO.GetUnitFromKey = GetUnitFromKey
	ExposedMembers.GCO.GetMaxTransfertTable = GetMaxTransfertTable
	ExposedMembers.GCO.AddCombatInfoTo = AddCombatInfoTo
	ExposedMembers.GCO.AddFrontLineCasualtiesInfoTo = AddFrontLineCasualtiesInfoTo
	ExposedMembers.GCO.AddCasualtiesInfoByTo = AddCasualtiesInfoByTo
	ExposedMembers.GCO.GetTotalPrisonners = GetTotalPrisonners
	ExposedMembers.GCO.GetPrisonnersStringByCiv = GetPrisonnersStringByCiv
	ExposedMembers.GCO.CreateEverAliveTableWithDefaultValue = CreateEverAliveTableWithDefaultValue
	ExposedMembers.GCO.GetPersonnelReserve = GetPersonnelReserve
	ExposedMembers.GCO.GetVehiclesReserve = GetVehiclesReserve
	ExposedMembers.GCO.GetHorsesReserve = GetHorsesReserve
	ExposedMembers.GCO.GetMaterielReserve = GetMaterielReserve
	ExposedMembers.GCO.GetFoodConsumption = GetFoodConsumption
	ExposedMembers.GCO.GetBaseFoodStock = GetBaseFoodStock
	ExposedMembers.Utils_Initialized = true
end
Initialize()


-----------------------------------------------------------------------------------------
-- Cleaning on exit
-----------------------------------------------------------------------------------------
function Cleaning()
	print ("Cleaning GCO stuff on LeaveGameComplete...")
	ExposedMembers.SaveLoad_Initialized = nil
	ExposedMembers.Utils_Initialized = nil
	ExposedMembers.UnitData = nil
	ExposedMembers.GCO = nil
	ExposedMembers.GetUnitKey = nil
	ExposedMembers.UI = nil
	ExposedMembers.CombatTypes = nil
	ExposedMembers.UnitHitPointsTable = nil
end
Events.LeaveGameComplete.Add(Cleaning)