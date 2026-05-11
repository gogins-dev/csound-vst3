<CsoundSynthesizer>
<CsLicense>
This is an extremely basic proof that CsoundVST3 can use Csound's MIDI output 
opcodes to send MIDI output to any MIDI input. This has been tested by using 
the standalone app version of CsoundVST3 to send MIDI channel messages to the 
MidiView program on macOS. The code is adapted from an example by Iain 
McCurdy.
</CsLicense>
<CsOptions>
-Q1 -m163 -daemon
</CsOptions>
<CsInstruments>
ksmps = 32 ;no audio so sr and nchnls irrelevant

  instr 1
; arguments for midiout are read from p-fields
istatus   init      p4
ichan     init      p5
idata1    init      p6
idata2    init      p7
          midiout   istatus, ichan, idata1, idata2; send raw midi data
          turnoff   ; turn instrument off to prevent reiterations of midiout
  endin

</CsInstruments>
<CsScore>
;p1 p2 p3   p4 p5 p6 p7
i 1 0 0.01 144 1  60 100 ; note on
i 1 2 0.01 144 1  60   0 ; note off (using velocity zero)

i 1 3 0.01 144 1  60 100 ; note on
i 1 5 0.01 128 1  60 100 ; note off (using 'note off' status byte)
</CsScore>
</CsoundSynthesizer>
;example by Iain McCurdy