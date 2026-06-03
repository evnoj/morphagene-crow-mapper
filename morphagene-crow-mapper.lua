local dbg = require("debugger")

-- CONFIGURATION VARIABLES
-- the crow output
local crow_output = 1
-- the pitch tolerance when finding a CV that generates a pitch
-- I don't think morphagene is precise enough to go smaller than this
local tolerance = 0.02 -- 2 cents

-- UTILITIES
function sign(n)
    if n < 0 then
        return -1
    elseif n > 0 then
        return 1
    else
        return 0
    end
end

-- IO FUNCTIONS
function set_cv(v)
    os.execute("druid exec 'output["..crow_output.."].volts = "..v.."' > /dev/null")
end

-- chuck script that analyzes frequency (as midi note #) and "direction" of the saw wave
-- prints the note to stdout
-- negative means that it is reversed (rising saw wave)
-- 0 means silence (morphagene is stopped)
-- 666 means it couldn't identify the wave as either rising or falling
-- 1500 or -1500 means it couldn't identify a pitch
local chuck_script = [[
adc => Gain g => blackhole;
adc => PitchTrack pitch => blackhole;
pitch.overlap(5);
pitch.frame(4096);
0 => int rising;
0 => int falling;
0.0 => float sumSq;
0 => int sampCount;
0.003 => float silenceThresh; // ~-50 dBFS

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

250::ms => now;

Math.sqrt(sumSq / sampCount) => float rms;

// if unable to detect pitch, ftom reports -1500
Std.ftom(pitch.get()) => float note;

if (rms < silenceThresh) {
    chout <= 0;
} else if (rising > falling * 2) {
    chout <= -1 * note;
} else if (falling > rising * 2) {
    chout <= note;
} else {
    chout <= 666;
}

chout <= IO.newline();

0 => rising; 0 => falling;
0.0 => sumSq; 0 => sampCount;
]]

-- returns the midi note number
function chuck_run(adc, rate)
    local note =  io.popen("echo '"..chuck_script.."' | chuck --adc:"..adc.." --srate:"..rate.." /dev/stdin"):read()

    if not note then
        dbg()
    end

    return tonumber(note)
end

function measure_note()
    -- if adcs/dacs are added/removed while script runs (which can happen by accident w/ bluetooth or dumb macOS stuff) then this can fail, in which case user must set adc again
    local note_measured = nil
    while true do
        note_measured = chuck_run(adc_index, srate)

        if not note_measured then
            print("error while running chuck script, set adc index again")
            chuck_adc_setup()
        else
            break
        end
    end

    return note_measured
end

-- use this to check what the chuck script is returning while in the debugger
function chuck_check()
    print(io.popen("echo '"..chuck_script.."' | chuck --adc:"..adc_index.." --srate:"..srate.." /dev/stdin"):read())
end

-- set global adc_index and sample rate for the adc chuck uses
function chuck_adc_setup()
    local chuck_adcs = io.popen("chuck --probe", "r")
    for line in chuck_adcs:lines() do
        print(line)
    end

    print("enter the index of the ADC that the morphagene signal is coming in on:")
    adc_index = io.read("*n")

    print('enter the sample rate of the device (press "d" for default 48000):')
    srate = io.read("*n")

    if not srate then
        srate = 48000
    end
end

-- given a CV that is passing for the target note, finds the high and low that pass
function find_center(note_target, starting_cv)
    step_size = 0.001
    local cv = starting_cv

    while(true) do
        cv = cv + step_size
        set_cv(cv)
        local note_measured = measure_note()
        local err = note_target - note_measured
        if math.abs(err) >= tolerance then
            break
        end
    end
    local cv_high = cv - step_size

    cv = starting_cv
    while(true) do
        cv = cv - step_size
        set_cv(cv)
        local note_measured = measure_note()
        local err = note_target - note_measured
        if math.abs(err) >= tolerance then
            break
        end
    end
    local cv_low = cv + step_size

    return cv_high,cv_low
end

-- INIT
-- the midi notes to find CV for, negative means reverse playback, 0 means stopped
-- I couldn't get pitch detection to work with chuck for midi note less than ~35
local notes = {-84, -83, -82, -81, -80, -79, -78, -77, -76, -75, -74, -73, -72, -71, -70, -69, -68, -67, -66, -65, -64, -63, -62, -61, -60, -59, -58, -57, -56, -55, -54, -53, -52, -51, -50, -49, -48, -47, -46, -45, -44, -43, -42, -41, -40, -39, -38, -37, 0, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84}
local note_cv_map = {}

chuck_adc_setup()

local pass_threshold = 3
local step_threshold = 20
local weird_fail_threshold = 5
local weird_fail_markers ={[1500]=1, [-1500]=1, [666]=1}

-- limits are known
table.insert(note_cv_map, {note=-84, cv=0})
cv = 0

for i=2,#notes - 1 do
    note_target = notes[i]

    local step_direction = 1
    local steps = 0
    local passes = 0
    local step_size = 0.02
    local weird_fails = 0

    ::check_note::
    set_cv(cv)
    local note_measured = measure_note()

    if weird_fail_markers[note_measured] then
        weird_fails = weird_fails + 1
        if weird_fails > weird_fail_threshold then
            print("passed weird fail threshold, entering debugger")
            dbg()
            weird_fails = 0
        end
        goto check_note
    end

    local err = note_target - note_measured

    if math.abs(err) < tolerance then -- pass
        passes = passes + 1
        print("note "..note_target.." pass count "..passes)

        if passes == pass_threshold then
            print("passed "..note_target..", finding center")
            local cv_high,cv_low = find_center(note_target, cv)
            local center_cv = (cv_high + cv_low) / 2
            print("found center cv of "..center_cv.." for note "..note_target)

            table.insert(note_cv_map, {note=note_target, cv=center_cv})
        else -- check again
            goto check_note
        end
    else -- fail
        if sign(err) ~= step_direction then -- overshot
            step_size = step_size / 2
            step_direction = step_direction * -1

        end

        steps = steps + 1
        cv = cv + (step_size * step_direction)
        print("note "..note_target.." failed with cv "..cv.." on step "..steps)
        print("measured note: "..note_measured)

        if steps > step_threshold then
            print("steps exceeded threshold on note "..note_target)
            print("entering debugger, please set cv manually then continue")
            dbg()
            steps = 0
            step_direction = 1
            weird_fails = 0
        end

        goto check_note
    end
end
table.insert(note_cv_map, {note=84, cv=6.66})

-- save the table
local indent, eol = "    ", "\n"
local file, err = io.open('morphagene-note-cv-map.lua', "wb")
if err then
    print("error while opening file, entering debugger")
    dbg()
end

file:write("return {"..eol)

local idx = math.floor(#notes / 2) * -1
for _,t in ipairs(note_cv_map) do
    file:write(indent.."["..idx.."]="..t.cv..",")

    if idx == -48 then
        file:write(" -- +1 octave reverse")
    elseif idx == -36 then
        file:write(" -- 1x playback reverse")
    elseif idx == -24 then
        file:write(" -- -1 octave reverse")
    elseif idx == -12 then
        file:write(" -- -2 octaves reverse")
    elseif idx == 0 then
        file:write(" -- stopped")
    elseif idx == 12 then
        file:write(" -- -2 octaves")
    elseif idx == 24 then
        file:write(" -- -1 octave")
    elseif idx == 36 then
        file:write(" -- 1x playback")
    elseif idx == 48 then
        file:write(" -- +1 octave")
    end

    file:write(eol)
    idx = idx + 1
end

file:write("}"..eol)
file:close()
