#!/bin/bash

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Navigate to the working directory
echo "Changing directory to get_private_traffic..."
cd get_private_traffic/Second_try_get_Critical_point || { echo "Failed to change directory"; exit 1; }

# Initial value to be replaced in the .od file
current_value=29000

for ((value=29000; value>=500; value-=500)); do
    echo "Updating private1_traffic30.od with value $value..."
    sed -i "s/$current_value/$value/g" get_private_traffic/Second_try_get_Critical_point/private1_traffic30.od
    current_value=$value  # Update the reference for the next iteration

    # Generate trips
    echo "Generating trips for $value..."
    od2trips -c od2trips1.config.xml -n zones5.taz.xml -d private1_traffic30.od -o 2_private1_for_${value}.trips.xml || { echo "Failed to generate trips"; exit 1; }

    # Generate route files
    echo "Generating route files for $value..."
    duarouter -n debrecen1.net.xml --route-files 2_private1_for_${value}.trips.xml -o 2_private1_${value}.rou.xml --ignore-errors --repair || { echo "Failed to generate route files"; exit 1; }

    # Run SUMO simulation
    echo "Running SUMO simulation for $value..."
    sim_output="2_sim_output_${value}.xml"
    sumo -n debrecen1.net.xml --additional pt_vtypes.xml,gtfs_publictransport.add.xml --routes gtfs_publictransport.rou.xml,2_private1_${value}.rou.xml --begin 21600 --end 36000 --tripinfo-output $sim_output || { echo "SUMO simulation failed"; exit 1; }

    echo "Simulation complete! Output file: $sim_output"

done

echo "All simulations completed!"

