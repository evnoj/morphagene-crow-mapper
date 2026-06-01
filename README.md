A lua script to map crow voltage values to Morphagene pitches. Load a saw wave onto Morphagene, plugin the output into your audio interface to monitor pitch and waveshape, plug a crow output into the varispeed CV input, then run the script and it will create a Lua table mapping voltage values to musical notes. This then enables crow to control the pitch of Morphagene to hit in-tune equal temperament relationships to the pitch of the source material

dependencies:
- [ChucK](https://chuck.stanford.edu/release/)
    - the `chuck` command must be available on your `PATH`
    - the default ChucK plugins ("chugins") must be installed, these are installed with the ChucK download linked above but does not come with all ChucK installations, ex. homebrew has a ChucK formula but does not come with the chugins

# instructions
Load `c4-saw-falling-10s.wav` onto your Morphagene, and load the reel.

plug the desired crow output into the varispeed CV input, turn the varispeed knob fully counterclockwise and the attunuverter fully clockwise, then run the script like `lua morphagene-crow-mapper.lua`
