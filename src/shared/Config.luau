-- Config.luau
-- Every tuning number for Warung Brainrot lives in this one module, so the
-- balance of the game can be changed without hunting through the services.
-- Server modules and the client all read from here; nothing else hard-codes
-- a price, a timer or a distance.

local Config = {}

-- Money and income
Config.StartingCash = 150 -- cash a player spawns with
Config.TickSeconds = 1 -- the income tick: every second, cash grows by the player's income rate

-- Conveyor spawning and movement
Config.SpawnIntervalSeconds = 4 -- a new brainrot walks onto the conveyor this often
Config.MaxBrainrotsOnConveyor = 8 -- the belt never holds more than this many
Config.ConveyorSpeedStuds = 3 -- studs per second along the 60-stud belt (about 20 s to cross)
Config.ConveyorStartZ = -30 -- north end of the belt, where brainrots appear
Config.ConveyorEndZ = 30 -- south end of the belt, where unsold brainrots despawn
Config.BuyDistanceStuds = 12 -- a buyer must stand this close to the brainrot

-- Base slots and locking
Config.BaseCount = 4 -- plots in the market, one per player
Config.StartingSlots = 6 -- brainrot slots each base begins with
Config.MaxSlots = 10 -- upgrades stop here
Config.FirstExtraSlotPrice = 500 -- slot 7 costs this; each further slot doubles
Config.LockDurationSeconds = 20 -- how long a locked base refuses thieves
Config.LockCooldownSeconds = 60 -- how long before the owner may lock again

-- Stealing
Config.StealHoldSeconds = 2.5 -- hold time on the steal prompt
Config.StealDistanceStuds = 12 -- a thief must stand this close to the target brainrot
Config.CarryRiseStuds = 3.4 -- a carried brainrot rides this far above the carrier's root

-- Hujan Krupuk event
Config.EventIntervalSeconds = 100 -- time between krupuk waves
Config.EventWarningSeconds = 5 -- banner warning before the wave sweeps

-- Rebirth
Config.RebirthThresholdEarned = 25000 -- lifetime earnings needed for one rebirth
Config.RebirthMultiplierStep = 0.5 -- each rebirth adds this much income multiplier

-- Mutations (rolled at spawn time)
Config.GoldChance = 0.05 -- 5% of spawns are Gold
Config.GoldRateMultiplier = 2
Config.DiamondChance = 0.01 -- 1% of spawns are Diamond
Config.DiamondRateMultiplier = 5

return Config
