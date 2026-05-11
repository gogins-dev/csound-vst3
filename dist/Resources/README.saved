<p>
<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" 
style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" />
</a>
<p>All music and examples herein are licensed under the  
<a rel="ccncsa4" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">
Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
<p>
<img alt="GNU Affero General License v3" 
style="border-width:0" src="https://www.gnu.org/graphics/agplv3-155x51.png" /> 
</p><p>All code herein is licensed under the  
<a rel="agplv3" href="https://www.gnu.org/licenses/agpl-3.0.html">
GNU Affero General Public License, version 3</a>.

# CsoundVST3
[Michael Gogins](https://michaelgogins.tumblr.com)

Note that [Cabbage](https://github.com/rorywalsh/cabbage) provides a much more 
full-featured VST3 plugin version of Csound. However, CsoundVST3 enables 
editing .csd text directly within DAW projects. In some cases, this can greatly 
simplify and speed up the user's workflow.

## Introduction

CsoundVS3 enables the [Csound audio programming language](https://csound.com/") 
to be used within digital audio workstations as a VST3 plugin instrument and 
signal processing effect.

CsoundVST3 has audio inputs, audio outputs, MIDI inputs, and MIDI outputs. 
The plugin hosts one .csd file, which can be edited from the plugin's user 
interface. The interface also displays Csound's runtime messages. Csound's 
score time is synchronized with the DAW's playback time, which can loop.

CsoundVST3 has _all_ the power of command-line Csound. CsoundVST3 can read and 
write on the user's filesystem, load plugin opcodes, and execute system 
commands.

CsoundVST3's GUI does _not_ provide user-defined widgets for controlling the 
Csound orchestra. However, such controls can be implemented in the DAW using 
MIDI control change messages.

Please log any bug reports or feature requests as a GitHub issue.

## Installation

Download the installation archive from 
<a href="https://github.com/gogins/csound-vst3">GitHub<a/> and unzip it.

Copy the CsoundVST3.vst3 directory and its contents to your user VST3 plugins 
directory. For example, in macOS, that would normally end up as 
`~/Library/Audio/Plug-Ins/VST3/CsoundVST3.vst3`.

## Usage

 1. Write a Csound .csd file that optionally outputs stereo audio, optionally 
    accepts stereo audio input, optionally accepts MIDI channel messages, and 
    optionally sends out MIDI channel messages. The `<CsOptions>` element 
    can map MIDI channel message fields to your Csound instrument pfields, 
    and should open MIDI inputs and, if needed, MIDI outputs, for example:
    ```
    -MN -QN --midi-key=4 --midi-velocity=5 -m163 -+msg_color=0 --daemon  
    ```
    Note that `-MN` must used for MIDI input in a DAW, and that `-QN` must be 
    used for MIDI output to the DAW. For standalone use, the actual device 
    number must be used in place of `N`. CsoundVST3 prints a list of available 
    MIDI devices when it compiles the .csd.
    
    The `--daemon` option ensures that the Csound orchestra will run 
    indefinitely within the DAW project.

    Your Csound instrument definitions may use mapped pfields and/or Csound's 
    MIDI input and output opcodes but, in any case, you must use a releasing 
    envelope. It is possible, but tricky, to use the same instrument 
    definitions for both MIDI performance and score-driven performance; but 
    in that case, you must not change the value of p3 to extend note durations, 
    rather, use the `xtratim` opcode for that purpose. Both when a Csound 
    score event with a positive p3 ends, and when a MIDI note with a negative 
    p3 receives its MIDI note off message, the releasing envelope will be 
    triggered and will properly end the note.

    You should ensure that your Csound orchestra outputs audio samples within 
    the interval [-1, +1]. This can be controlled by adjusting `0dbfs` in your 
    orchestra header.

    The CsoundVST3.csd example contains numerous instrument definitions 
    that work this way.

 2. In your DAW, create a new track using CsoundVST3 as a virtual instrument.

 3. Open the CsoundVST3 GUI and either open your .csd file using the
    _**Open...**_ dialog, or paste the .csd code into the edit window.

 4. In some DAWs, configure the plugin not to forward any key events to the 
    host. In Reaper, open the FX editor, select the __**FX**__ menu, and 
    enable the __**Send all keyboard input to plug-in...**__ item.
 
 5. Click on the **_Play_** button to make sure that the .csd compiles and
    runs. You can use a score in your DAW, or a MIDI controller, or a
    virtual keyboard to play notes using the .csd.

 7. Save your DAW project, and re-open it to make sure that your plugin 
    and its .csd have been loaded.

CsoundVST3 does not implement presets. The entire state of the plugin is the 
.csd file, which is saved and loaded as part of the DAW project. However, you 
can have as many CsoundVST3 plugins on as many tracks as you like, each with 
its own independent .csd file. 

If you need something like presets, you can map MIDI controllers to Csound 
control variables in your csd, and then you can save the state of your MIDI 
controllers in your DAW project.

## Release notes for version 0.1beta

This is the initial release.




