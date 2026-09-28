# Subsystem Ownership and Interfaces

## Ali Hussein - SDR, Raspberry Pi 4, Controls/UI, DSP/Detection

Primary responsibilities:
- SDR configuration and digital I/Q acquisition
- MATLAB signal processing and detector development
- Raspberry Pi 4 deployment/integration
- Buttons, GPIO, status LEDs, and optional display/UI
- Candidate-event detection and 60 Hz phase analysis

Interface boundary:
- Input begins at the SDR / digital I/Q side
- Receives RF from Abigail's RF front end
- Receives regulated power from Reagan's power/PCB subsystem

## Reagan Carlton - Spark/RF Characterization, Power, PCB Integration

Primary responsibilities:
- Spark source and RF characterization work
- Battery / power-source selection
- Buck converter / voltage regulation
- Power budget and power distribution
- PCB schematic, layout, connectors, BOM, and fabrication files

Interface boundary:
- Provides regulated power and board-level connections to the RF front end, SDR, Raspberry Pi, and controls

## Abigail Purchla - Antenna and RF Front End

Primary responsibilities:
- Antenna design/selection
- RF filtering
- LNA/amplification if needed
- Matching, protection, and RF-front-end schematics
- RF-front-end testing and measurements

Interface boundary:
- Input begins at the antenna
- Output ends at the RF signal delivered to the SDR input

## Shared Integration

System flow:

Antenna -> RF Front End -> SDR -> Raspberry Pi 4 -> DSP/Detection -> Controls/UI

Power flow:

Battery -> Regulation/Buck Converter -> PCB Power Distribution -> RF Front End / SDR / Raspberry Pi / Controls

This folder is for interface definitions, system block diagrams, integration tests, and shared component information.
