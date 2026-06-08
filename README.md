# Optimization of 2.45 GHz Microstrip Patch Antenna Using Artificial Neural Networks
This project presents an ANN-assisted approach for optimizing the radiation efficiency of a 2.45 GHz microstrip patch antenna. The antenna was designed and simulated in CST Studio Suite, where the radiating patch was divided into an 11 × 11 slot matrix comprising 121 controllable slots. Multiple slot-removal configurations were analyzed to generate a training dataset containing antenna structures and their corresponding S11 values.

A Feed Forward Artificial Neural Network (FFANN) was developed in MATLAB to learn the relationship between slot configurations and antenna performance. An optimization algorithm was then implemented to predict antenna structures that satisfy user-defined efficiency requirements while maintaining acceptable impedance matching (S11 ≤ −10 dB).

The ANN-predicted antenna configurations were validated using CST simulations, demonstrating the capability of machine learning to reduce repetitive electromagnetic simulations and accelerate the antenna design process.
# Key Features
Design and simulation of a 2.45 GHz microstrip patch antenna in CST Studio Suite.
11 × 11 slot-based antenna optimization framework (121 controllable slots).
CST dataset generation using multiple slot-removal configurations.
Feed Forward ANN implementation in MATLAB for S11 prediction.
Efficiency-driven antenna structure optimization.
CST validation of ANN-predicted antenna designs.
Reduction in design time compared to conventional trial-and-error optimization.
# Tools & Technologies
CST Studio Suite
MATLAB
Artificial Neural Networks (ANN)
Electromagnetic Simulation
Antenna Design & Optimization
