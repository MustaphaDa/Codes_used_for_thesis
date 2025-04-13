# Codes_used_for_thesis

This repository contains the code and configuration files used to run traffic simulations using **SUMO (Simulation of Urban MObility)** for my thesis project.

## 📄 Description of Files

- **Get_table.py**:  
  This Python script takes two input files — `tripinfo.xml` (representing the normal scenario) and `tripinfo_with_private1.xml` (representing the scenario with private vehicles). It extracts the arrival time of each vehicle from both files, compares them, and generates a table showing:
  - Vehicle ID
  - Actual arrival time
  - Expected arrival time

- **Get_taz_6_10.py**:  
  Generates a TAZ (Traffic Assignment Zone) file based on the zoning scheme used in Simulation 1.

- **get_zones.py**:  
  Generates three XML files: `zone1.xml`, `zone2.xml`, and `zone3.xml`, each representing a different zone based on the zoning design used in the simulations.

- **GetMap.py**:  
  A Python script that downloads the map of Debrecen for use in the simulation.

- **run_simulation.sh**:  
  A shell script that automates the simulation process. It allows running multiple simulations with control over simulation time.

- **run_simulation_10_exactitude.sh**:  
  A shell script that automation script. This version follows the zoning scheme used in the "cleaning curve" experiment.

---