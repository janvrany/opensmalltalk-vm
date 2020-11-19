# TA Cog

This branch is home to Tacog,
a tool for conscious understanding of the OpenSmalltalk VM.
As such, at the time of this writing
(ca. OpenPOWER-NA2020)
concerns of debugging (the process of gaining understanding)
dominate over concerns of downstream usage (such as speed in applications).
This is likely to change as adoption picks up.


The overriding design principle in Tacog is that no part of the argument
why a construction works, is left implicit in the programmer's brain;
so every argument must be repeatable by machine.
The adherence to this principle will increase in the future.


At the same time, we wanted to stick with a real (not toy) Smalltalk,
to avoid the common pitfalls characteristic of academic VM projects.
For this reason, we took \[an admittedly arbitrary snapshot of\]
the OpenSmalltalk VM as our starting point, and to always keep it running
at every step along the transformation chain.


The fact that the codebase in its current state does not fully conform
to the project's overall design, is simply a reflection of this
pragmatic engineering reality.


Tacog is a bridge between Cog and the TA toolchain
(MachineArithmetic / ULD / Pharo-ArchC / Petrich / PIG2),
which is meant to server as VM implementation substrate for several
other dialects (e.g. the Powerlang VM).
As such, design decisions concerning the shape of submodule APIs,
must be understood in light of this cross-dialect compatibility.

## Top-level README

This file is the Tacog README; this is so that people can
save their precious time identifying what this branch is for.
The main OpenSmalltalkVM README is OpenSmalltalkVM.md.

## How to load

### ...into Pharo

````
Metacello new
  baseline: 'VMMaker';
  repository: 'github://shingarov/opensmalltalk-vm:baseline-for-hackathon';
  load.
````
Don't forget to follow the
[instructions to install ISA descriptions](https://github.com/shingarov/Pharo-ArchC/blob/pure-z3/README.md).

After that, you can try:
````
ArchCOpalTest finishLoading.
ClyPDLEnvironmentPlugin initialize.
````
and verify if the browser shows the "tools" icon next to the assembly methods in `ArchCOpalTest`.
