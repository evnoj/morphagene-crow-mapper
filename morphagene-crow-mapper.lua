local threshold = 440.0  -- Hz
local log = {}

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


local chuck = io.popen([[echo '
while (true) {
    250::ms => now;
    <<< Std.rand2(0,9) >>>;
}
' | chuck --adc:]]..adc_index.." --srate:"..srate.." /dev/stdin")

for line in chuck:lines() do
    print(line)
end
