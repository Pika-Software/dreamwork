---@class dreamwork.std.math
local math = dreamwork.std.math

-- Source code of functions
-- https://github.com/Facepunch/garrysmod/pull/1755
-- https://web.archive.org/web/20201212082306/https://easings.net/
-- https://web.archive.org/web/20201218211606/https://raw.githubusercontent.com/ai/easings.net/master/src/easings.yml

local math_pi = math.pi
local math_cos = math.cos
local math_sin = math.sin
local math_sqrt = math.sqrt

local c1 = 1.70158
local c3 = c1 + 1
local c2 = c1 * 1.525
local c4 = (2 * math_pi) / 3
local c5 = (2 * math_pi) / 4.5
local n1 = 7.5625
local d1 = 2.75

--- [SHARED AND MENU]
---
--- The math easing functions.
---
---@class dreamwork.std.math.ease
local ease = math.ease or {}
math.ease = ease

--- [SHARED AND MENU]
---
--- Eases in using `math.sin`.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.sineIn( fraction )
    return 1 - math_cos( (fraction * math_pi) * 0.5 )
end

--- [SHARED AND MENU]
---
--- Eases out using `math.sin`.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.sineOut( fraction )
    return math_sin( (fraction * math_pi) * 0.5 )
end

--- [SHARED AND MENU]
---
--- Eases in and out using `math.sin`.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.sineInOut( fraction )
    return -(math_cos( math_pi * fraction ) - 1) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in by squaring the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quadIn( fraction )
    return fraction ^ 2
end

--- [SHARED AND MENU]
---
--- Eases out by squaring the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quadOut( fraction )
    return 1 - (1 - fraction) * (1 - fraction)
end

--- [SHARED AND MENU]
---
--- Eases in and out by squaring the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quadInOut( fraction )
    return fraction < 0.5 and 2 * fraction ^ 2
        or 1 - ((-2 * fraction + 2) ^ 2) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in by cubing the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.cubicIn( fraction )
    return fraction ^ 3
end

--- [SHARED AND MENU]
---
--- Eases out by cubing the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.cubicOut( fraction )
    return 1 - ((1 - fraction) ^ 3)
end

--- [SHARED AND MENU]
---
--- Eases in and out by cubing the fraction.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.cubicInOut( fraction )
    return fraction < 0.5 and 4 * fraction ^ 3
        or 1 - ((-2 * fraction + 2) ^ 3) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in by raising the fraction to the power of 4.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quartIn( fraction )
    return fraction ^ 4
end

--- [SHARED AND MENU]
---
--- Eases out by raising the fraction to the power of 4.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quartOut( fraction )
    return 1 - ((1 - fraction) ^ 4)
end

--- [SHARED AND MENU]
---
--- Eases in and out by raising the fraction to the power of 4.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quartInOut( fraction )
    return fraction < 0.5 and 8 * fraction ^ 4
        or 1 - ((-2 * fraction + 2) ^ 4) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in by raising the fraction to the power of 5.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quintIn( fraction )
    return fraction ^ 5
end

--- [SHARED AND MENU]
---
--- Eases out by raising the fraction to the power of 5.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quintOut( fraction )
    return 1 - ((1 - fraction) ^ 5)
end

--- [SHARED AND MENU]
---
--- Eases in and out by raising the fraction to the power of 5.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.quintInOut( fraction )
    return fraction < 0.5 and 16 * fraction ^ 5
        or 1 - ((-2 * fraction + 2) ^ 5) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in using an exponential equation with a base of 2 and where the fraction is used in the exponent.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.expoIn( fraction )
    return fraction == 0 and 0 or (2 ^ (10 * fraction - 10))
end

--- [SHARED AND MENU]
---
--- Eases out using an exponential equation with a base of 2 and where the fraction is used in the exponent.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.expoOut( fraction )
    return fraction == 1 and 1 or 1 - (2 ^ (-10 * fraction))
end

--- [SHARED AND MENU]
---
--- Eases in and out using an exponential equation with a base of 2 and where the fraction is used in the exponent.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.expoInOut( fraction )
    return fraction == 0 and 0
        or fraction == 1 and 1
        or fraction < 0.5 and (2 ^ (20 * fraction - 10)) * 0.5 or (2 - (2 ^ (-20 * fraction + 10))) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in using a circular function.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.circIn( fraction )
    return 1 - math_sqrt( 1 - (fraction ^ 2) )
end

--- [SHARED AND MENU]
---
--- Eases out using a circular function.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.circOut( fraction )
    return math_sqrt( 1 - ((fraction - 1) ^ 2) )
end

--- [SHARED AND MENU]
---
--- Eases in and out using a circular function.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.circInOut( fraction )
    return fraction < 0.5 and (1 - math_sqrt( 1 - ((2 * fraction) ^ 2) )) * 0.5
        or (math_sqrt( 1 - ((-2 * fraction + 2) ^ 2) ) + 1) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in by reversing the direction of the ease slightly before returning.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.backIn( fraction )
    return c3 * fraction ^ 3 - c1 * fraction ^ 2
end

--- [SHARED AND MENU]
---
--- Eases out by reversing the direction of the ease slightly before finishing.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.backOut( fraction )
    return 1 + c3 * ((fraction - 1) ^ 3) + c1 * ((fraction - 1) ^ 2)
end

--- [SHARED AND MENU]
---
--- Eases in and out by reversing the direction of the ease slightly before returning on both ends.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.backInOut( fraction )
    return fraction < 0.5 and (((2 * fraction) ^ 2) * ((c2 + 1) * 2 * fraction - c2)) * 0.5
        or (((2 * fraction - 2) ^ 2) * ((c2 + 1) * (fraction * 2 - 2) + c2) + 2) * 0.5
end

--- [SHARED AND MENU]
---
--- Eases in like a rubber band.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.elasticIn( fraction )
    return fraction == 0 and 0
        or fraction == 1 and 1
        or -(2 ^ (10 * fraction - 10)) * math_sin( (fraction * 10 - 10.75) * c4 )
end

--- [SHARED AND MENU]
---
--- Eases out like a rubber band.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.elasticOut( fraction )
    return fraction == 0 and 0 or fraction == 1 and 1
        or (2 ^ (-10 * fraction)) * math_sin( (fraction * 10 - 0.75) * c4 ) + 1
end

--- [SHARED AND MENU]
---
--- Eases in and out like a rubber band.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.elasticInOut( fraction )
    return fraction == 0 and 0 or fraction == 1 and 1
        or fraction < 0.5 and -((2 ^ (20 * fraction - 10)) * math_sin( (20 * fraction - 11.125) * c5 )) * 0.5
        or ((2 ^ (-20 * fraction + 10)) * math_sin( (20 * fraction - 11.125) * c5 )) * 0.5 + 1
end

--- [SHARED AND MENU]
---
--- Eases out like a bouncy ball.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
local function ease_bounceOut( fraction )
    if (fraction < 1 / d1) then
        return n1 * fraction ^ 2
    elseif (fraction < 2 / d1) then
        fraction = fraction - (1.5 / d1)
        return n1 * fraction ^ 2 + 0.75
    elseif (fraction < 2.5 / d1) then
        fraction = fraction - (2.25 / d1)
        return n1 * fraction ^ 2 + 0.9375
    else
        fraction = fraction - (2.625 / d1)
        return n1 * fraction ^ 2 + 0.984375
    end
end

--- [SHARED AND MENU]
---
--- Eases in like a bouncy ball.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.bounceIn( fraction )
    return 1 - ease_bounceOut( 1 - fraction )
end

ease.bounceOut = ease_bounceOut

--- [SHARED AND MENU]
---
--- Eases in and out like a bouncy ball.
---
---@param fraction number Fraction of the progress to ease, from 0 to 1.
---@return number eased The eased number.
function ease.bounceInOut( fraction )
    return fraction < 0.5 and (1 - ease_bounceOut( 1 - 2 * fraction )) * 0.5
        or (1 + ease_bounceOut( 2 * fraction - 1 )) * 0.5
end
