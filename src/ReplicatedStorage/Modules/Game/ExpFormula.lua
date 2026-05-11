------------------//VARIABLES
local ExpFormula = {}

------------------//FUNCTIONS
function ExpFormula.get_required_exp(level: number): number
	if level <= 10 then
		return 100
	elseif level <= 25 then
		return 500
	elseif level <= 50 then
		return 2000
	elseif level <= 100 then
		return 8000
	elseif level <= 200 then
		return 30000
	elseif level <= 300 then
		return 100000
	else
		return 400000
	end
end

function ExpFormula.add_exp(level: number, exp: number, addedExp: number, levelCap: number): {level: number, exp: number, levelsGained: number}
	local nextLevel = level
	local nextExp = exp + addedExp
	local levelsGained = 0

	while nextLevel < levelCap do
		local requiredExp = ExpFormula.get_required_exp(nextLevel)
		if nextExp < requiredExp then
			break
		end

		nextExp -= requiredExp
		nextLevel += 1
		levelsGained += 1
	end

	if nextLevel >= levelCap then
		nextExp = 0
	end

	return {
		level = nextLevel,
		exp = nextExp,
		levelsGained = levelsGained,
	}
end

------------------//INIT
return ExpFormula
