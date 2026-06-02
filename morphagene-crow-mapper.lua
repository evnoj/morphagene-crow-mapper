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

if (rising > falling * 2) {
    chout <= "rising";
} else if (falling > rising * 2) {
    chout <= "falling";
} else {
    chout <= "symmetric/other";        
}
chout <= ",";

if (rms < silenceThresh) {
    chout <= "silence";
} else {
    chout <= "signal";
}

chout <= IO.newline();

0 => rising; 0 => falling;
0.0 => sumSq; 0 => sampCount;
]]

local conditions = {
    {note=84, direction=rising},
    {note=83, direction=rising},
    {note=82, direction=rising},
    {note=81, direction=rising},
    {note=80, direction=rising},
    {note=79, direction=rising},
    {note=78, direction=rising},
    {note=77, direction=rising},
    {note=76, direction=rising},
    {note=75, direction=rising},
    {note=74, direction=rising},
    {note=73, direction=rising},
    {note=72, direction=rising},
    {note=71, direction=rising},
    {note=70, direction=rising},
    {note=69, direction=rising},
    {note=68, direction=rising},
    {note=67, direction=rising},
    {note=66, direction=rising},
    {note=65, direction=rising},
    {note=64, direction=rising},
    {note=63, direction=rising},
    {note=62, direction=rising},
    {note=61, direction=rising},
    {note=60, direction=rising},
    {note=59, direction=rising},
    {note=58, direction=rising},
    {note=57, direction=rising},
    {note=56, direction=rising},
    {note=55, direction=rising},
    {note=54, direction=rising},
    {note=53, direction=rising},
    {note=52, direction=rising},
    {note=51, direction=rising},
    {note=50, direction=rising},
    {note=49, direction=rising},
    {note=48, direction=rising},
    {note=47, direction=rising},
    {note=46, direction=rising},
    {note=45, direction=rising},
    {note=44, direction=rising},
    {note=43, direction=rising},
    {note=42, direction=rising},
    {note=41, direction=rising},
    {note=40, direction=rising},
    {note=39, direction=rising},
    {note=38, direction=rising},
    {note=37, direction=rising},
    {signal='silence'},
    {note=37, direction=falling},
    {note=38, direction=falling},
    {note=39, direction=falling},
    {note=40, direction=falling},
    {note=41, direction=falling},
    {note=42, direction=falling},
    {note=43, direction=falling},
    {note=44, direction=falling},
    {note=45, direction=falling},
    {note=46, direction=falling},
    {note=47, direction=falling},
    {note=48, direction=falling},
    {note=49, direction=falling},
    {note=50, direction=falling},
    {note=51, direction=falling},
    {note=52, direction=falling},
    {note=53, direction=falling},
    {note=54, direction=falling},
    {note=55, direction=falling},
    {note=56, direction=falling},
    {note=57, direction=falling},
    {note=58, direction=falling},
    {note=59, direction=falling},
    {note=60, direction=falling},
    {note=61, direction=falling},
    {note=62, direction=falling},
    {note=63, direction=falling},
    {note=64, direction=falling},
    {note=65, direction=falling},
    {note=66, direction=falling},
    {note=67, direction=falling},
    {note=68, direction=falling},
    {note=69, direction=falling},
    {note=70, direction=falling},
    {note=71, direction=falling},
    {note=72, direction=falling},
    {note=73, direction=falling},
    {note=74, direction=falling},
    {note=75, direction=falling},
    {note=76, direction=falling},
    {note=77, direction=falling},
    {note=78, direction=falling},
    {note=79, direction=falling},
    {note=80, direction=falling},
    {note=81, direction=falling},
    {note=82, direction=falling},
    {note=83, direction=falling},
    {note=84, direction=falling},
}

function chuck_run(script, adc, rate)
    local s =  io.popen("echo '"..script.."' | chuck --adc:"..adc.." --srate:"..rate.." /dev/stdin"):read()
    local freq,note,dir,sig = string.match(s, "(.+),(.+),(.+),(.+)")
    return tonumber(freq),tonumber(note),dir,sig
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

for _,cond in ipairs(conditions) do
    -- check condition
    local freq,note,dir,sig = chuck_run(chuck_script, adc_index, srate)
end
