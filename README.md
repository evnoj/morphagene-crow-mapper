A Lua script to map voltage values to [Morphagene](https://www.makenoisemusic.com/modules/morphagene/) pitches. Intended for use with with the [monome crow](https://monome.org/docs/crow/) to enable crow to play Morphagene in tune. Load a saw wave onto Morphagene, plugin the output into your audio interface to monitor pitch and waveshape, plug a crow output into the varispeed CV input, then run the script and it will create a Lua table mapping voltage values to musical notes. This then enables crow to control the pitch of Morphagene to hit in-tune equal temperament relationships to the pitch of the source material

> to use this script with a different CV output module, change the `set_cv()` function in the script

# dependencies
- [ChucK](https://chuck.stanford.edu/release/)
    - the `chuck` command must be available on your `PATH`
    - the default ChucK plugins ("chugins") must be installed, these are installed with the ChucK download linked above but does not come with all ChucK installations, ex. homebrew has a ChucK formula but does not come with the chugins

# instructions
1. Clone this repo and `cd` into it
2. Load `c4-saw-falling-10s.wav` onto your Morphagene, and load the reel
3. Turn **varispeed** and **slide** fully ccw, and **gene size** to ~9 o' clock
4. Turn the varispeed CV attenuverter fully clockwise
5. Turn **morph** to ~9 o clock spot for seamless looping (right varispeed indicator should be yellow)
6. Plug the desired crow output into the varispeed CV input
  - If not using output 1, be sure to change `crow_output` at the top of the script
7. Get the output of morphagene into your audio interface, and ensure that the interface is sending only the signal from Morphagene to your computer (i.e. other inputs are muted or unplugged)
8. Run the script like `lua morphagene-crow-mapper.lua`
  - The script takes a bit over an hour to run. While the script is running, don't plug or unplug audio devices into your computer
  - There are some errors that can occur while the script is running, and if so, it either prompts for input or drops into an interactive debugger so that you can resolve the issue. The debugger is [debugger.lua](https://codeberg.org/slembcke/debugger.lua), enter `h` at the debugger for a list of commands, you'll probably want to also use:
    - `t` to view the stack trace and what frame you're in
    - `u` and `d` to move up/down frames
    - `l` to view local variables
    - `e` to execute code in the current frame
      - ex. `e cv=0` sets the `cv` variable, which is the control voltage that will be sent from crow's output
9. When the script completes, it writes the table to `morphagene-note-cv-map.lua` in the directory that the script was run from

# LLM disclosure
I used significant LLM assistance to write the ChucK code that does the audio analysis. I wanted the audio analysis to be simple and able to be done via shell commands, so I had an LLM write minimal PoCs for whatever audio tools it could think of. ChucK appeared the simplest, and I used manual edits and an LLM to iterate on it.

I wrote all the Lua.
