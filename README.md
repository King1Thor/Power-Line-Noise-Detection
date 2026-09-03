# Power-Line Noise Detection, Analysis, and Location

## ECEN 403 Capstone Project

**Texas A&M University**

This project focuses on developing and validating a portable system for detecting, analyzing, and helping locate electrical arcing and sparking on power-line equipment.

---

## Project Goal

Electrical arcing and sparking on power-system hardware can generate short-duration broadband RF noise.

Our goal is to develop a system that can:

- Detect signatures associated with power-line arcing and sparking
- Distinguish those events from background RF noise
- Relate detected events to the power-system phase
- Compare simulated signals with real SDR I/Q measurements
- Help determine the direction or location of the noise source

The final hardware architecture is not fixed yet. Processor, antenna, SDR or receiver, embedded hardware, and PCB choices will be selected after the signal-processing and detection requirements are better understood.

---

## How the System Is Intended to Work

```text
Power-line defect
       |
       v
Electrical arc or spark
       |
       v
Broadband RF emission
       |
       v
Antenna
       |
       v
SDR / Receiver
       |
       v
Signal Processing and Detection
       |
       v
Spark Detected
       |
       v
Direction / Location Assistance
```

---

## Current MATLAB and Simulink Progress

### v01: Basic 60 Hz Model

Created a basic 60 Hz sine-wave model and verified the Simulink setup.

Main goals:

- Confirm the power waveform
- Verify approximately six cycles in a 0.1 second simulation
- Improve waveform resolution by reducing the solver maximum step size

### v02: Grid Frequency to Phase to Voltage

Replaced the direct 60 Hz source with a frequency-to-phase model.

```text
Grid Frequency
      |
      v
    2*pi
      |
      v
 Integration
      |
      v
    Phase
      |
      v
  sin(phase)
      |
      v
Power Waveform
```

A small temporary frequency variation was added to verify that the waveform can follow a changing grid frequency instead of assuming an exact 60.000 Hz source.

### v03: Controlled Disturbance

Added a second source and gating logic.

Purpose:

- Prove that a disturbance can be added only during selected portions of the AC waveform
- Verify the basic switching and gating concept

### v04: Two Events on the Positive Half-Cycle

Updated the model based on sponsor feedback.

The disturbance was changed so that it occurs:

- Once on the rising portion of the positive half-cycle
- Once on the falling portion of the positive half-cycle
- Not on the negative half-cycle

### v05: Adjustable Onset and Quench Windows

Replaced the simple threshold method with explicit phase-angle windows.

This allows the model to control:

- Spark onset angle
- Spark quench angle
- Rising-side event location
- Falling-side event location

### v06: General Spark-Event Envelope

The current model uses two adjustable phase windows and a normalized disturbance amplitude.

Current starting windows based on sponsor guidance:

- **Rising-side window: 40° to 50°**
- **Center: 45°**
- **Falling-side window: 130° to 140°**
- **Center: 135°**

The current disturbance amplitude is:

```text
+0.3
```

This is a **normalized test value**. It is not being claimed as the real spark voltage, current, or RF amplitude.

---

## What v06 Currently Proves

The current model demonstrates that we can:

- Track grid phase
- Synchronize spark-event timing to the grid waveform
- Control onset and quench angles
- Generate one event on the rising positive half-cycle
- Generate one event on the falling positive half-cycle
- Keep the negative half-cycle undisturbed
- Change event timing without redesigning the model

---

## What v06 Does Not Prove Yet

v06 is **not yet the complete real-life RF spark waveform**.

A real electrical discharge creates a very fast electrical impulse that produces broadband RF energy.

The current model mainly represents:

```text
WHEN the spark event occurs
+
HOW LONG the event is active
```

It does not yet fully represent:

```text
WHAT the received real RF spark signature looks like
```

That part will be refined using reference material and real SDR measurements.

---

## Next Steps

### 1. Refine the Spark Model

Use sponsor guidance, reference material, and measured data to improve:

- Onset angles
- Quench angles
- Spark pulse behavior
- Received RF signature

### 2. Analyze Real SDR Data

Use the recorded complex I/Q data to study:

- Time-domain behavior
- Signal magnitude
- Spectrum
- Spectrogram
- Background versus spark events
- Repeating patterns related to the power-system phase

### 3. Develop the Detection Algorithm

Use the controlled Simulink model first to test detection ideas.

Possible detection features include:

- Short impulsive events
- Signal-energy increase
- Broadband RF behavior
- Repetition at expected grid-phase locations

### 4. Validate With Real Measurements

The detector must eventually be tested against real SDR recordings instead of simulation alone.

### 5. Evaluate Hardware Requirements

After the algorithm is proven, evaluate whether the final system should use:

- Laptop
- Raspberry Pi
- MCU
- FPGA
- Other embedded hardware

### 6. Develop Direction and Location Capability

The final system should help the user determine where the power-line noise source is located using suitable antenna and receiver hardware.

---

## Repository Structure

```text
Power-Line-Noise-Detection/
|
|-- 01_Project_Documents/
|
|-- 02_Modeling_and_Simulation/
|   |
|   `-- PowerLine_Spark_Model/
|       |-- Team2_PowerLine_Model_v01
|       |-- Team2_PowerLine_Model_v02
|       |-- Team2_PowerLine_Model_v03
|       |-- Team2_PowerLine_Model_v04
|       |-- Team2_PowerLine_Model_v05
|       `-- Team2_PowerLine_Model_v06
|
|-- 03_SDR_Data_Analysis/
|
|-- 04_Detection_Algorithm/
|
|-- 05_Hardware/
|
|-- 06_Altium_PCB/
|
|-- 07_Testing_and_Validation/
|
`-- 08_Presentations_and_Reports/
```

---

## Team

### Ali Hussein
**Computer Engineering**

Primary areas:

- MATLAB and Simulink
- SDR and I/Q processing
- Detection algorithm
- Embedded and system integration

### Reagan Carlton
**Electrical Engineering**

Primary areas:

- RF and antenna work
- Power-system noise physics
- References
- Measurement support

### Abigail Purchla
**Electrical Engineering**

Primary areas:

- Hardware
- Altium and PCB
- Testing
- Validation

---

## Project Leadership

**Sponsor:** Dr. Tom Talley

**Course Instructor:** Dr. John Lusher II

**Course:** ECEN 403 Capstone

**University:** Texas A&M University

---

## Main Tools

- MATLAB
- Simulink
- RTL-SDR
- SDR#
- Altium Designer
- Git
- GitHub

---

## Engineering Note

Early simulation values are treated as test parameters unless they are validated using sponsor guidance, references, or measured data.

The project separates:

- Simulation results
- Measured results
- Engineering assumptions
- Sponsor guidance
- Reference-supported values

This keeps later hardware and algorithm decisions evidence-driven.
