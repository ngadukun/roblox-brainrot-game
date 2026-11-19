-- BrainrotData.luau
-- The cast of Warung Brainrot: ten absurd Indonesian night-market characters
-- on a rarity ladder, cheapest first. Each entry carries everything the
-- factory and the conveyor need: buy price, income per second, spawn weight,
-- body colour and the colour its rarity is written in.
--
-- Spawn weights add up to 100, so a weight reads as a rough percentage of
-- conveyor traffic before mutations are rolled.

local BrainrotData = {}

BrainrotData.Cast = {
	{
		Name = "Krupuk Terbang",
		Rarity = "Common",
		IncomePerSecond = 2,
		Price = 30,
		SpawnWeight = 30,
		BodyColor = { 245, 238, 214 }, -- cream white, like a rice cracker
		RarityColor = { 210, 210, 210 },
	},
	{
		Name = "Es Teh Manis",
		Rarity = "Common",
		IncomePerSecond = 4,
		Price = 75,
		SpawnWeight = 22,
		BodyColor = { 196, 132, 62 }, -- sweet tea brown
		RarityColor = { 210, 210, 210 },
	},
	{
		Name = "Gorengan Sakti",
		Rarity = "Rare",
		IncomePerSecond = 9,
		Price = 200,
		SpawnWeight = 16,
		BodyColor = { 232, 178, 44 }, -- fried gold
		RarityColor = { 84, 148, 255 },
	},
	{
		Name = "Kopi Tubruk Titan",
		Rarity = "Rare",
		IncomePerSecond = 15,
		Price = 450,
		SpawnWeight = 12,
		BodyColor = { 92, 56, 32 }, -- dark tubruk coffee
		RarityColor = { 84, 148, 255 },
	},
	{
		Name = "Nasi Padang Raksasa",
		Rarity = "Epic",
		IncomePerSecond = 30,
		Price = 1000,
		SpawnWeight = 8,
		BodyColor = { 203, 44, 34 }, -- chilli red
		RarityColor = { 176, 92, 255 },
	},
	{
		Name = "Becak Terbang",
		Rarity = "Epic",
		IncomePerSecond = 55,
		Price = 2200,
		SpawnWeight = 5,
		BodyColor = { 38, 178, 160 }, -- tosca green pedicab
		RarityColor = { 176, 92, 255 },
	},
	{
		Name = "Komodo Berkepala Dua",
		Rarity = "Legendary",
		IncomePerSecond = 110,
		Price = 5000,
		SpawnWeight = 3.5,
		BodyColor = { 96, 128, 56 }, -- moss green
		RarityColor = { 255, 156, 44 },
	},
	{
		Name = "Garuda Emas",
		Rarity = "Mythic",
		IncomePerSecond = 250,
		Price = 12000,
		SpawnWeight = 2,
		BodyColor = { 255, 196, 32 }, -- gold
		RarityColor = { 255, 84, 112 },
	},
	{
		Name = "Kujang Petir",
		Rarity = "Brainrot God",
		IncomePerSecond = 600,
		Price = 30000,
		SpawnWeight = 1,
		BodyColor = { 128, 64, 216 }, -- lightning purple
		RarityColor = { 196, 92, 255 },
	},
	{
		Name = "Tung-Tung Sahur",
		Rarity = "Secret",
		IncomePerSecond = 1500,
		Price = 75000,
		SpawnWeight = 0.5,
		BodyColor = { 30, 44, 96 }, -- deep sahur-night blue
		RarityColor = { 92, 220, 255 },
	},
}

-- Name lookup, built once from the cast list so callers can ask for a
-- character by the name the tour or a prompt gives them.
BrainrotData.ByName = {}
for _, def in ipairs(BrainrotData.Cast) do
	BrainrotData.ByName[def.Name] = def
end

function BrainrotData.getDefinitionByName(name)
	return BrainrotData.ByName[name]
end

-- Pick the next cast member by spawn weight with the given Random: common
-- faces most of the time, the Tung-Tung Sahur almost never. The conveyor
-- asks here so the ladder's odds live beside the ladder itself.
function BrainrotData.pickWeightedDefinition(random)
	local totalWeight = 0
	for _, def in ipairs(BrainrotData.Cast) do
		totalWeight = totalWeight + def.SpawnWeight
	end
	local roll = random:NextNumber() * totalWeight
	local running = 0
	for _, def in ipairs(BrainrotData.Cast) do
		running = running + def.SpawnWeight
		if roll <= running then
			return def
		end
	end
	return BrainrotData.Cast[1]
end

return BrainrotData
