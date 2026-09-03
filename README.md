Power-Line Noise Detection, Analysis, and Location

ECEN 403 Capstone project focused on developing and validating a portable method for detecting and helping locate electrical arcing and sparking on power-line equipment.

Project Goal

Electrical arcing and sparking on power-system hardware can generate short-duration broadband RF noise. The goal of this project is to develop a system that can:

detect signatures associated with power-line arcing and sparking,

distinguish those events from background RF noise,

relate detected events to the power-system phase,

compare simulated signals with real SDR I/Q measurements, and

eventually help a user determine the direction or location of the noise source.

The final hardware architecture is intentionally not fixed yet. Processor, antenna, SDR or receiver, embedded hardware, and PCB choices will be based on measured algorithm and processing requirements.

Current Modeling Approach

The MATLAB and Simulink work is being developed incrementally.

v01: Basic 60 Hz Model

Created a 60 Hz sine-wave model and verified the simulation setup and solver resolution.

v02: Grid Frequency to Phase to Voltage

Replaced the direct sine source with a frequency-to-phase model:

grid frequency -> 2*pi -> integration -> phase -> sin(phase)

A small temporary frequency variation was added to verify that the generated waveform follows a changing grid frequency instead of assuming an exact 60.000 Hz source.

v03: Phase-Controlled Disturbance

Added a second source and gating logic to verify that a disturbance could be applied only during selected portions of the AC cycle.

v04: Two Events on the Positive Half-Cycle

Updated the logic based on sponsor feedback so that one event occurs on the rising segment and one on the falling segment of the positive half-cycle.

v05: Adjustable Onset and Quench Windows

Replaced the simple threshold method with explicit phase-angle windows. This makes the event timing adjustable without changing the model architecture.

v06: General Spark-Event Envelope

The current model uses two adjustable positive-half-cycle windows and a normalized disturbance amplitude.

Current starting windows, based on sponsor guidance:

rising-side window: 40° to 50°, centered at 45°

falling-side window: 130° to 140°, centered at 135°

The current +0.3 disturbance is a normalized test amplitude used to demonstrate the event envelope. It is not being claimed as the real physical spark voltage or current, or the final RF waveform.

What v06 Proves

The current model demonstrates that we can:

track the instantaneous grid phase,

define adjustable onset and quench angles,

create one event on the rising positive half-cycle,

create one event on the falling positive half-cycle,

keep the negative half-cycle undisturbed, and

keep the event timing synchronized with the modeled grid phase.

What It Does Not Prove Yet

The current model is not yet a complete physical RF spark model.

A real electrical discharge produces a very fast impulsive current or voltage event with broadband RF content. The present Simulink model is primarily a timing and envelope model. The detailed spark and noise signature must be refined using reference material and real SDR measurements.

Next Steps

Keep the phase-window model as the controllable event generator.

Analyze sponsor and reference data to refine onset and quench angles.

Analyze real SDR I/Q recordings and the reference spark model to characterize the received spark and noise signature.

Develop an initial detection algorithm using the controlled simulation.

Validate the detector against real SDR data.

Measure processing requirements before selecting the final processor and hardware architecture.

Progress toward directional and source-location testing with suitable RF antennas and receiver hardware.

Repository Structure

01_Project_Documents/
02_Modeling_and_Simulation/
    PowerLine_Spark_Model/
03_SDR_Data_Analysis/
04_Detection_Algorithm/
05_Hardware/
06_Altium_PCB/
07_Testing_and_Validation/
08_Presentations_and_Reports/

Team

Team 2: Power Line Noise Detection #2

Ali Hussein, Computer Engineering

MATLAB and Simulink

SDR and I/Q processing

detection algorithm

embedded and system integration

Reagan Carlton, Electrical Engineering

RF and antenna

power-system noise physics

references and measurement support

Abigail Purchla, Electrical Engineering

hardware

Altium and PCB

testing and validation

Sponsor: Dr. Tom Talley
Course Instructor: Dr. John Lusher II
Course: ECEN 403 Capstone, Texas A&M University

Tools

MATLAB and Simulink

RTL-SDR and SDR#

Altium Designer

Git and GitHub

Engineering Note

Values used during early simulation stages are intentionally treated as test parameters unless validated by reference data or measurement. The project separates simulated behavior, measured behavior, engineering assumptions, and sponsor or reference guidance so that later design decisions remain evidence-driven.