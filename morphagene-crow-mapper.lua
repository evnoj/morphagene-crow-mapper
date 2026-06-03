local dbg = require("debugger")

-- chuck script that analyzes frequency and "direction" of the saw wave
-- direction is -1 for backwards (rising saw), 1 for forwards (falling saw), 0 for stopped
-- prints to stdout a single line like:
-- freq,note,direction
local chuck_script = [[
adc => Gain g => blackhole;

0 => int rising;
0 => int falling;
0.0 => float sumSq;
0 => int sampCount;

fun void sampleLoop() {
    0.0 => float prev;
    while (true) {
        1::samp => now;
        g.last() => float cur;
        if (cur > prev) rising++;
        else if (cur < prev) falling++;
        cur => prev;
        cur * cur +=> sumSq;
        sampCount++;
    }
}
spork ~ sampleLoop();

0.003 => float silenceThresh; // ~-50 dBFS

// re-init each time to avoid reporting prev pitch 
adc => PitchTrack pitch => blackhole;
pitch.overlap(5);
pitch.frame(4096);

250::ms => now;

Math.sqrt(sumSq / sampCount) => float rms;
pitch.get() => float freq;

chout <= freq <= ",";
// if unable to detect pitch, ftom reports -1500
chout <= Std.ftom(freq) <= ",";

if (rms < silenceThresh) {
    chout <= 0;
} else if (rising > falling * 2) {
    chout <= -1;
} else if (falling > rising * 2) {
    chout <= 1;
} else {
    chout <= "symmetric/other";        
}

chout <= IO.newline();

0 => rising; 0 => falling;
0.0 => sumSq; 0 => sampCount;
]]

--- Save a table to disk.
-- Saves tables, numbers, booleans and strings.
-- Inside table references are saved.
-- Does not save userdata, metatables, functions and indices of these.
-- Based on http://lua-users.org/wiki/SaveTableToFile by ChillCode.
-- @tparam table tbl Table to save.
-- @tparam string filename Location to save to.
-- @return On failure, returns an error msg.
function tab_save(tbl, filename)
  local charS, charE = "   ", "\n"
  local file, err = io.open(filename, "wb")
  if err then return err end

  -- initiate variables for save procedure
  local tables, lookup = { tbl }, { [tbl] = 1 }
  file:write("return {"..charE)

  for idx, t in ipairs(tables) do
    file:write("-- Table: {"..idx.."}"..charE)
    file:write("{"..charE)
    local thandled = {}

    for i, v in ipairs(t) do
      thandled[i] = true
      local stype = type(v)
      -- only handle value
      if stype == "table" then
        if not lookup[v] then
          table.insert(tables, v)
          lookup[v] = #tables
        end
        file:write(charS.."{"..lookup[v].."},"..charE)
      elseif stype == "string" then
        file:write(charS..string.format("%q", v)..","..charE)
      elseif stype == "number" then
        file:write(charS..tostring(v)..","..charE)
      elseif stype == "boolean" then
        file:write(charS..tostring(v)..","..charE)
      end
    end

    for i, v in pairs(t) do
      -- escape handled values
      if (not thandled[i]) then

        local str = ""
        local stype = type(i)
        -- handle index
        if stype == "table" then
          if not lookup[i] then
             table.insert(tables, i)
             lookup[i] = #tables
          end
          str = charS.."[{"..lookup[i].."}]="
        elseif stype == "string" then
          str = charS.."["..string.format("%q", i).."]="
        elseif stype == "number" then
          str = charS.."["..tostring(i).."]="
        elseif stype == "boolean" then
          str = charS.."["..tostring(i).."]="
        end

        if str ~= "" then
          stype = type(v)
          -- handle value
          if stype == "table" then
            if not lookup[v] then
              table.insert(tables, v)
              lookup[v] = #tables
            end
            file:write(str.."{"..lookup[v].."},"..charE)
          elseif stype == "string" then
            file:write(str..string.format("%q", v)..","..charE)
          elseif stype == "number" then
            file:write(str..tostring(v)..","..charE)
          elseif stype == "boolean" then
            file:write(str..tostring(v)..","..charE)
          end
        end
      end
    end
    file:write("},"..charE)
  end
  file:write("}")
  file:close()
end

condition_set = {
    {note=84, dir=-1},
    {note=83, dir=-1},
    {note=82, dir=-1},
    {note=81, dir=-1},
    {note=80, dir=-1},
    {note=79, dir=-1},
    {note=78, dir=-1},
    {note=77, dir=-1},
    {note=76, dir=-1},
    {note=75, dir=-1},
    {note=74, dir=-1},
    {note=73, dir=-1},
    {note=72, dir=-1},
    {note=71, dir=-1},
    {note=70, dir=-1},
    {note=69, dir=-1},
    {note=68, dir=-1},
    {note=67, dir=-1},
    {note=66, dir=-1},
    {note=65, dir=-1},
    {note=64, dir=-1},
    {note=63, dir=-1},
    {note=62, dir=-1},
    {note=61, dir=-1},
    {note=60, dir=-1},
    {note=59, dir=-1},
    {note=58, dir=-1},
    {note=57, dir=-1},
    {note=56, dir=-1},
    {note=55, dir=-1},
    {note=54, dir=-1},
    {note=53, dir=-1},
    {note=52, dir=-1},
    {note=51, dir=-1},
    {note=50, dir=-1},
    {note=49, dir=-1},
    {note=48, dir=-1},
    {note=47, dir=-1},
    {note=46, dir=-1},
    {note=45, dir=-1},
    {note=44, dir=-1},
    {note=43, dir=-1},
    {note=42, dir=-1},
    {note=41, dir=-1},
    {note=40, dir=-1},
    {note=39, dir=-1},
    {note=38, dir=-1},
    {note=37, dir=-1},
    {dir=0},
    {note=37, dir=1},
    {note=38, dir=1},
    {note=39, dir=1},
    {note=40, dir=1},
    {note=41, dir=1},
    {note=42, dir=1},
    {note=43, dir=1},
    {note=44, dir=1},
    {note=45, dir=1},
    {note=46, dir=1},
    {note=47, dir=1},
    {note=48, dir=1},
    {note=49, dir=1},
    {note=50, dir=1},
    {note=51, dir=1},
    {note=52, dir=1},
    {note=53, dir=1},
    {note=54, dir=1},
    {note=55, dir=1},
    {note=56, dir=1},
    {note=57, dir=1},
    {note=58, dir=1},
    {note=59, dir=1},
    {note=60, dir=1},
    {note=61, dir=1},
    {note=62, dir=1},
    {note=63, dir=1},
    {note=64, dir=1},
    {note=65, dir=1},
    {note=66, dir=1},
    {note=67, dir=1},
    {note=68, dir=1},
    {note=69, dir=1},
    {note=70, dir=1},
    {note=71, dir=1},
    {note=72, dir=1},
    {note=73, dir=1},
    {note=74, dir=1},
    {note=75, dir=1},
    {note=76, dir=1},
    {note=77, dir=1},
    {note=78, dir=1},
    {note=79, dir=1},
    {note=80, dir=1},
    {note=81, dir=1},
    {note=82, dir=1},
    {note=83, dir=1},
    {note=84, dir=1},
}

local condition_checkers = {
    note = function(desired, measured)
        local diff_abs = math.abs(desired - measured)
        local tolerance = 0.02

        if diff_abs < tolerance then
            return true
        else
            return false
        end
    end,
    freq = function(desired, measured)
        local diff_abs = math.abs(desired - measured)
        local tolerance = 0.02

        if diff_abs < tolerance then
            return true
        else
            return false
        end
    end,
    dir = function(desired, measured)
        if desired == measured then
            return true
        else
            return false
        end
    end,
}

function chuck_run(script, adc, rate)
    local s =  io.popen("echo '"..script.."' | chuck --adc:"..adc.." --srate:"..rate.." /dev/stdin"):read()
    if not s then
        dbg()
    end

    local freq,note,dir = string.match(s, "(.+),(.+),(.+)")
    return {
        freq = tonumber(freq),
        note = tonumber(note),
        dir = tonumber(dir),
    }
end

-- use this to check what the chuck script is returning while in the debugger
function chuck_check()
    print(io.popen("echo '"..chuck_script.."' | chuck --adc:"..adc_index.." --srate:"..srate.." /dev/stdin"):read())
end

-- INIT

local chuck_adcs = io.popen("chuck --probe", "r")
for line in chuck_adcs:lines() do
    print(line)
end

print("enter the index of the ADC that the morphagene signal is coming in on:")
local adc_index = io.read("*n")

print('enter the sample rate of the device (press "d" for default 48000):')
local srate = io.read("*n")

if not srate then
    srate = 48000
end

local cv = 0

local pass_threshold = 3
local step_size = 0.01
local step_direction_swap_threshold = 20
local absolute_step_threshold = 100
for i,conditions in ipairs(condition_set) do
    local step_direction = 1
    local steps = 0
    local passes = 0

    ::check_condition::
    os.execute("druid exec 'output[1].volts = "..cv.."'")
    local measured = chuck_run(chuck_script, adc_index, srate)
    local pass = true
    for condition,desired in pairs(conditions) do
        pass = pass and condition_checkers[condition](desired, measured[condition])
    end
    if not pass then
        steps = steps + 1
        if steps > absolute_step_threshold then
            print("steps exceeded threshold on condition "..i)
            print("cv was "..cv)
            print("entering debugger, please set cv manually then continue")
            dbg()
        elseif steps > step_direction_swap_threshold then
            step_direction = step_direction * -1
        end

        print("condition "..i.." failed with cv "..cv.." on step "..steps)
        if conditions.note then
            print("desired note: "..conditions.note)
            print("measured note: "..measured.note)
        end

        cv = cv + (step_size * step_direction)
        goto check_condition
    else
        passes = passes + 1
        print("condition "..i.." pass count "..passes)

        if passes == pass_threshold then
            print('passed '..i)
            conditions.volts = cv
        else
            goto check_condition
        end
    end
end

tab_save(condition_set, 'morphagene-crow-map.lua')
