#!/bin/bash

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate || { echo "Failed to activate virtual environment"; exit 1; }

# Navigate to the working directory
echo "Changing directory to get_private_traffic..."
cd get_private_traffic/clean_curve_by_log_scal || { echo "Failed to change directory"; exit 1; }

# Initial value to be replaced in the .od file
current_value=34000

# Loop over values from 54000 down to (decreasing by 2000)
for ((value=97000; value>=65000; value-=4000)); do
    echo "Updating private1_traffic30.od with value $value..."
    sed -i "s/$current_value/$value/g" private1_traffic30.od
    current_value=$value  # Update the reference for the next iteration

    # Run 10 simulations for each value
    for ((sim=1; sim<=10; sim++)); do
        echo "Starting simulation #$sim for value $value..."

        # Generate trips
        trip_file="4_${value}_${sim}_private1_for.trips.xml"
        echo "Generating trips for $value (Simulation #$sim)..."
        od2trips -c od2trips1.config.xml -n zones5.taz.xml -d private1_traffic30.od -o "$trip_file" || { echo "Failed to generate trips"; exit 1; }

        # Generate route files
        route_file="4_${value}_${sim}_private1.rou.xml"
        echo "Generating route files for $value (Simulation #$sim)..."
        duarouter -n debrecen1.net.xml --route-files "$trip_file" -o "$route_file" --ignore-errors --repair || { echo "Failed to generate route files"; exit 1; }

        # Modify fix_depart_times.py script dynamically
        fixed_route_file="4_${value}_${sim}_fixed_private1.rou.xml"
        echo "Updating fix_depart_times.py for $value (Simulation #$sim)..."
        sed -i "s|input_file = .*|input_file = '$route_file'|" fix_depart_times.py
        sed -i "s|output_file = .*|output_file = '$fixed_route_file'|" fix_depart_times.py

        # Run fix_depart_times.py
        echo "Running fix_depart_times.py for $value (Simulation #$sim)..."
        python3 fix_depart_times.py || { echo "Failed to run fix_depart_times.py"; exit 1; }

        # Run SUMO simulation
        sim_output="4_${value}_${sim}_sim_output.xml"
        echo "Running SUMO simulation #$sim for $value..."
        sumo -n debrecen1.net.xml --additional pt_vtypes.xml,gtfs_publictransport.add.xml \
             --routes gtfs_publictransport.rou.xml,"$fixed_route_file" \
             --begin 21600 --end 36000 --tripinfo-output "$sim_output" || { echo "SUMO simulation failed for $value (run #$sim)"; exit 1; }

        echo "Simulation #$sim complete! Output file: $sim_output"
    done

    echo "All 10 simulations completed for value $value."
done

echo "All simulations for all values completed!"

