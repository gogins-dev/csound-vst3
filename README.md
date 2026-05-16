# CsoundVST3
## By Michael Gogins
## https://michaelgogins.tumblr.com

All music and examples herein are licensed under the Creative Commons 
Attribution-NonCommercial-ShareAlike 4.0 International License  
(http://creativecommons.org/licenses/by-nc-sa/4.0/).

All code herein is licensed under the GNU Affero General Public License, 
version 3 (https://www.gnu.org/licenses/agpl-3.0.html).

This is the simplest plugin I could write that provides _all_ the 
functionality of Csound to digital audio workstations (DAWs) as a VST3 or 
AudioUnit plugin. There is also a standalone app version.
    
Note that Cabbage (https://github.com/rorywalsh/cabbage) provides a much more 
full-featured VST3 plugin version of Csound. _However, CsoundVST3 enables 
editing .csd text directly within DAW projects._ In many cases, this can 
greatly simplify and speed up the user's workflow.

## Introduction

CsoundVST3 enables the Csound audio programming language (https://csound.com/) 
to be used within digital audio workstations as a VST3 plugin instrument 
and/or signal processing effect.

CsoundVST3 has audio inputs, audio outputs, MIDI inputs, and MIDI outputs. 
The plugin hosts one .csd file, which can be edited from the plugin's user 
interface. The interface also displays Csound's runtime messages. Csound's 
score time is synchronized with the DAW's playback time, which can loop. This 
enables using Csound score events embedded in the .csd file to play in sync 
with the DAW's playback head. And that, in turn, brings _all_ of the technical 
resources of electroacoustic music, or computer music, or whatever you want 
to call it, into digital audio workstations.

CsoundVST3 has _all_ the power of command-line Csound. CsoundVST3 can read and 
write on the user's filesystem, load plugin opcodes, and execute system 
commands.

CsoundVST3's GUI does _not_ provide (as Cabbage does) user-defined widgets for 
controlling the Csound orchestra. However, such controls can be implemented in 
the DAW using MIDI control change messages.

Please log any bug reports or feature requests as a GitHub issue.

## macOS build objectives

These three modes are all supported by the CMake layout in `CsoundVST3/`:

1. **Build without signing or notarizing; run locally.** Leave the defaults (`CSOUND_AC_ENABLE_CODESIGN=OFF`, `CSOUND_AC_ENABLE_NOTARIZATION=OFF`). Configure and build with Ninja (or your IDE) and run or load plugins from the build tree under `CsoundVST3_artefacts/` (for example the Standalone `.app`). You do not need `archive_dist`, `sign_dist`, or `notarize_dist`.

2. **Build with signing and notarizing; run locally.** Turn `CSOUND_AC_ENABLE_CODESIGN` and `CSOUND_AC_ENABLE_NOTARIZATION` **ON**, supply your Apple signing and notary credentials, and build the `notarize_dist` target. The helper `CsoundVST3/clean-build-macos.bash` runs dist, signing, and the notarize target; by default it leaves notarization **OFF** in CMake for a shorter loop—pass `-DCSOUND_AC_ENABLE_NOTARIZATION=ON` through the script’s extra arguments when you want a full notarized zip locally. For a **system-installed Csound** that still pulls Homebrew libraries (for example `libsndfile`), local signing can use optional entitlements via `CSOUND_VST3_MACOS_ENTITLEMENTS` (see `clean-build-macos.bash`, or `--strict-codesign` there to match strict CI signing). Post-link ad-hoc signing with entitlements is controlled by `CSOUND_VST3_MACOS_POSTBUILD_ADHOC_SIGN` (default **ON** locally so incremental `ninja` runs stay runnable against Homebrew-linked Csound).

3. **Build with signing and notarizing on CI runners; no Csound bundled; end users use their own Csound 7.** Keep **`CSOUND_VST3_EMBED_CSOUND_FRAMEWORK=OFF`** (default). The GitHub Actions macOS job does **not** set `CSOUND_VST3_MACOS_ENTITLEMENTS` and forces **`CSOUND_VST3_MACOS_POSTBUILD_ADHOC_SIGN=OFF`**, so release artifacts are signed strictly for distribution. Binaries load **`CsoundLib64.framework` from `/Library/Frameworks`** via `@rpath` (see the post-link rewrite step in `CMakeLists.txt`). End users install a **binary-compatible Csound 7** (preferably an official build whose dependencies satisfy library validation when loaded from a signed host).

## Installation

NOTE: As of this release, CsoundVST3 requires that Csound version 7 already 
be installed on the user's system.

Download the installation archive from https://github.com/gogins/csound-vst3 
and unzip it.

Copy the CsoundVST3.vst3 directory and its contents to your user VST3 plugins 
directory. For example, on macOS, that would normally end up as 
~/Library/Audio/Plug-Ins/VST3/CsoundVST3.vst3.

To use the standalone version of CsoundVST3, copy CsoundVST3.app to your 
computer's Applications folder.

## Testing

To validate your build or installation on macOS, run CsoundVST3 as a plugin in 
your digital audio workstation. For example, on macOS with Reaper:

 1. Install Csound 7.
 2. Install Reaper.
 3. Open Reaper, and execute the _Track_ menu, _Insert Virtual Instumen on New Track_ command. Select CsoundVST3 as the virtual instrument.
 4. Use the track's _FX_ button to open CsoundVST3's editor. 
 5. Use CsoundVST3's _Open..._ button to load [https://github.com/gogins-dev/csound-vst3/blob/main/CsoundVST3/Resources/Examples/CsoundVST3.csd], or paste the raw file into the editor.
 6. Click on the _Save_ button.
 7. Click on the _Play_ button to recompile the Csound code and begin to run.
 8. Create a new MIDI item on the track, and open its editor. Write some notes, or just click on the MIDI item keyboard. You should hear CsoundVST playing the notes. 

## Usage

 1. Write a Csound .csd file that optionally outputs stereo audio, optionally 
    accepts stereo audio input, optionally accepts MIDI channel messages, and 
    optionally sends out MIDI channel messages. The `<CsOptions>` element 
    can map MIDI channel message fields to your Csound instrument pfields, 
    and should open MIDI inputs and, if needed, MIDI outputs, for example:
    
    -M0 -Q0 --midi-key=4 --midi-velocity=5 -m163 --daemon  
    
    Note that "-M" with a devoce number must used for MIDI input from the DAW, 
    and that "-Q" with a device number must be used for MIDI output to the 
    DAW. CsoundVST3 prints a list of available MIDI devices when it compiles 
    the .csd.
    
    The "--daemon" option ensures that the Csound orchestra will run 
    indefinitely within the DAW project.

    Your Csound instrument definitions may use mapped pfields and/or Csound's 
    MIDI input and output opcodes but, in any case, you must use a releasing 
    envelope. It is possible, but tricky, to use the same instrument 
    definitions for both MIDI performance and score-driven performance; but 
    in that case, you must not change the value of p3 to extend note durations, 
    rather, use the "xtratim" opcode for that purpose. Both when a Csound 
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
    "Open..." dialog, or paste the .csd code into the edit window.

 4. In some DAWs, configure the plugin not to forward any key events to the 
    host. In Reaper, open the FX editor, select the "FX" menu, and 
    enable the "Send all keyboard input to plug-in..." item.
 
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

## Release Notes 

### Version 2.0.0-beta

Ported to Csound version 7. Csound version 6 will no longer be supported in 
the main branch of this repository.

### Version 1.1.0-beta

Changed the build system from the Projucer to CMake, improved the README.

### Version 1.0.3-beta

A basic search and replace function has been added.

### Version 1.0.2-beta

Basic Csound syntax highlighting has been added.

### Version 1.0.1-beta

Internal audio and MIDI queues are now lock-free for more stable performance.

### Version 1.0.0-beta

This is the initial release.




