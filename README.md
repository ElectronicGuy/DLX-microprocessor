# DLX-microprocessor
Design, simulation, logic synthesis and place&amp;route of a DLX micropocessor

![](https://img.shields.io/badge/Development-Stopped-red)

This project was part of the "MicroElectronics Systems" course of Politecnico di Torino, attended in 2018.
It includes:
- datapath with 5 pipeline stages, dependency management (hazard detection) and advanced jump/branch handling. 
- hardwired control unit
- windowed register file, to support function calls
- signed multiplier based on Booth's high radix encoding
- parallel prefix network adder, composed of a sparse tree for carry bits generation and carry select adder (CSA) for sum bits generation
