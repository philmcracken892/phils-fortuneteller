Config = {}

Config.SpawnInterval = 30

Config.FortuneTellerModel = "cs_johnthebaptisingmadman"

Config.CandleModel = "p_candlebot01x"

-- Spawn locations using vector3 for coords
Config.SpawnLocations = {
    { coords = vector3(-236.01, 795.76, 122.43), heading = 90.0 },--- val
	{ coords = vector3(1306.12, -1278.61, 75.93), heading = 180.0 },--- rhodes
	{ coords = vector3(2704.04, -1412.22, 46.62), heading = 180.0 },--- st denis
}
-- Possible fortunes
Config.Fortunes = {
    { type = "good", text = "The spirits smile upon you... fortune follows your path.", reward = { money = 25, xp = 50 } },
    { type = "good", text = "A wave of good luck surrounds you. Expect unexpected wealth.", reward = { money = 50, xp = 100 } },
    { type = "bad",  text = "The cards turn dark... misfortune shadows your steps.", curse = "health_drain" },
	{ type = "bad",  text = "The cards turn dark... misfortune shadows your steps.", curse = "health_drain" },
    { type = "neutral", text = "The spirits are silent tonight. Your fate remains unchanged." },
}

Config.Curses = {
    slow = { description = "Your steps grow heavy, as if wading through molasses.", lifted = "The weight lifts from your limbs.", duration = 30000 },
    health_drain = { description = "You feel your life slipping away...", lifted = "The pain fades.", duration = 20000, damage = 50, interval = 2000 },

}
