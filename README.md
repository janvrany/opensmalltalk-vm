# TA Cog

This branch is home to *TA Cog*,
a tool for conscious understanding of the OpenSmalltalk VM.
As such, at the time of this writing
(ca. OpenPOWER-NA2020)
concerns of debugging (the process of gaining understanding)
dominate over concerns of downstream usage (such as speed in applications).
This is likely to change as adoption picks up.


The overriding design principle in *TA Cog* is that no part of the argument
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

*TA Cog* is a bridge between Cog and the TA toolchain
([MachineArithmetic][1] / ULD / [Pharo-ArchC][2] / Petrich / PIG2),
which is meant to serve as VM implementation substrate for several
other dialects (e.g. the Powerlang VM).
As such, design decisions concerning the shape of submodule APIs,
must be understood in light of this cross-dialect compatibility.

## Top-level README

This file is the *TA Cog* README; this is so that people can
save their precious time identifying what this branch is for.
The main OpenSmalltalkVM README is [OpenSmalltalkVM.md](OpenSmalltalkVM.md).

## How to build VMMaker.image, [thinshell][3] and [gem5][4]

**Note**: following has been tested on Debian Bullseye as of 2021-06-08.

1. Checkout this repository and external dependencies:

       ```
       git checkout -b ta-cog-POWER https://github.com/shingarov/opensmalltalk-vm.git
       git submodule update --init --recursive
       ```

2. Build:

      ```
      cd opensmalltalk-vm
      make
      ```

    This may take time, especially compilation of [gem5][4]

## How to run TA Cog for POWER using gem5

1. In one terminal, run [gem5][4] by typing:

      ```
      make run-g5
      ```

2. In second terminal, open `VMMaker.image`:

      ```
      ARCHC_PDL_DIR=3rdparty/pdl/ COG_READER_IMAGE=image/r.1.image ./pharo-ui VMMaker.image
      ```

    Then in workspace (playground) run:

      ```
      VMSimulationTest debug: #testPOWER.
      ```

After a while in first terminal (running [gem5][4]) you should see a lot of messages like:

```
46415000: system.cpu: T0 : @squeak.o+131360    : lis        r12, 29         : IntAlu :  D=0x00000000001d0000
46415500: system.cpu: T0 : @squeak.o+131364    : lwz        r13, 31672(r12) : MemRead :  D=0x00000000001d7b80 A=0x1d7bb8
46416000: system.cpu: T0 : @squeak.o+131368    : lis        r12, 29         : IntAlu :  D=0x00000000001d0000
46416500: system.cpu: T0 : @squeak.o+131372    : lwz        r11, 31664(r12) : MemRead :  D=0x00000000001d7b88 A=0x1d7bb0
46417000: system.cpu: T0 : @squeak.o+131376    : mr         r1, r22         : IntAlu :  D=0x0000000000831660
46417500: system.cpu: T0 : @squeak.o+131380    : li         r2, 0           : IntAlu :  D=0x0000000000000000
```

[1]: https://github.com/shingarov/MachineArithmetic
[2]: https://github.com/shingarov/Pharo-ArchC
[3]: https://github.com/shingarov/thinshell
[4]: http://www.gem5.org/