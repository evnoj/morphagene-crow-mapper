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

while (true) {
    // re-init each time to avoid reporting prev pitch 
    adc => PitchTrack pitch => blackhole;
    pitch.overlap(5);
    pitch.frame(4096);

    250::ms => now;

    Math.sqrt(sumSq / sampCount) => float rms;
    pitch.get() => float freq;

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
}
]]

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

local chuck = io.popen("echo '"..chuck_script.."' | chuck --adc:"..adc_index.." --srate:"..srate.." /dev/stdin")

for line in chuck:lines() do
    print(line)
end
