#!/bin/bash

# Automated SUMO Workflow Script
# This script automates the entire process from map download to simulation

set -e  # Exit on any error
shopt -s lastpipe


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=()
    
    if ! command_exists python3; then
        missing_deps+=("python3")
    fi
    
    if ! command_exists netconvert; then
        missing_deps+=("netconvert (SUMO)")
    fi
    
    if ! command_exists sumo; then
        missing_deps+=("sumo")
    fi
    
    if ! command_exists od2trips; then
        missing_deps+=("od2trips (SUMO)")
    fi
    
    if ! command_exists duarouter; then
        missing_deps+=("duarouter (SUMO)")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_error "Please install SUMO and Python3 before running this script"
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Function to get user input
get_user_input() {
    print_status "Getting user configuration..."
    
    # Get city name
    while true; do
        read -p "Enter the city name (e.g., Budapest, Pecs): " CITY_NAME
        if [[ -n "$CITY_NAME" ]]; then
            break
        fi
        print_warning "City name cannot be empty"
    done
    
    # Get GTFS file location
    while true; do
        read -p "Enter the path to GTFS zip file: " GTFS_PATH
        if [[ -f "$GTFS_PATH" ]]; then
            break
        fi
        print_warning "GTFS file not found at: $GTFS_PATH"
    done
    
    # Get simulation date
    while true; do
        read -p "Enter simulation date (YYYYMMDD, e.g., 20231229): " SIM_DATE
        if [[ "$SIM_DATE" =~ ^[0-9]{8}$ ]]; then
            break
        fi
        print_warning "Date must be in YYYYMMDD format"
    done
    
    # Get transport modes
    read -p "Enter transport modes (default: bus): " TRANSPORT_MODES
    TRANSPORT_MODES=${TRANSPORT_MODES:-bus}
    
    # Get simulation parameters
    read -p "Enter number of parallel jobs (default: 4): " MAX_JOBS
    MAX_JOBS=${MAX_JOBS:-4}
    
    # Get x_center and y_center 
    while true; do
    read -p "Enter CENTER_X coordinate (e.g., 4153868.14): " CENTER_X
    if [[ "$CENTER_X" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        break
    fi
    print_warning "Invalid format. Please enter a numeric X coordinate."
done

while true; do
    read -p "Enter CENTER_Y coordinate (e.g., 18753391.265): " CENTER_Y
    if [[ "$CENTER_Y" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        break
    fi
    print_warning "Invalid format. Please enter a numeric Y coordinate."
done
    
    read -p "Enter number of simulations per value (default: 10): " SIMS_PER_VALUE
    SIMS_PER_VALUE=${SIMS_PER_VALUE:-10}
    
    print_success "Configuration completed"
}

# Function to check for required external scripts
check_external_scripts() {
    print_status "Checking for required external scripts..."
    
    local required_scripts=("get_zones.py" "get_taz.py" )
    local missing_scripts=()
    
    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$script" ]]; then
            missing_scripts+=("$script")
        fi
    done
    
    if [ ${#missing_scripts[@]} -ne 0 ]; then
        print_error "Missing required external scripts: ${missing_scripts[*]}"
        print_error "Please ensure get_zones.py and get_taz.py are in the current directory"
        exit 1
    fi
    
    # Make external scripts executable
    chmod +x get_zones.py get_taz.py
    
    print_success "External scripts found and made executable"
}

# Function to create necessary Python scripts
create_python_scripts() {
    print_status "Creating necessary Python scripts..."
    
    # Create get_map.py
    cat > get_map.py << 'EOF'
#!/usr/bin/env python3
import requests

def download_osm_map(city_name):
    # Define the Overpass API endpoint
    overpass_url = "http://overpass-api.de/api/interpreter"

    # Overpass query to get full map (roads + public transport) of the given city
    overpass_query = f"""
    [out:xml];
    area["name"="{city_name}"]->.searchArea;
    (
      node(area.searchArea);
      way(area.searchArea);
      relation(area.searchArea);
    );
    out body;
    >;
    out skel qt;
    """

    print(f"Downloading full OSM map (including public transport) for {city_name}...")

    # Send request to Overpass API
    response = requests.post(overpass_url, data={'data': overpass_query})

    # Check if the request was successful
    if response.status_code == 200:
        filename = f"{city_name}.osm"
        with open(filename, "wb") as file:
            file.write(response.content)
        print(f"Full map successfully downloaded and saved as '{filename}'")
    else:
        print(f"Failed to download data. HTTP Status Code: {response.status_code}")


if __name__ == "__main__":
    city = input("Enter city name: ").strip()
    download_osm_map(city)
EOF


    print_status "get_zones.py and get_taz.py should be provided separately"
    print_status "These scripts will be called by the main workflow"

    # Make scripts executable
    chmod +x get_map.py
    
    print_success "Python scripts created successfully"
}

# Function to create configuration files
create_config_files() {
    print_status "Creating configuration files..."
    

    # Create initial OD matrix
    cat > private_traffic.od << 'EOF'
$O;D2
*From-Time To-Time
06.00 10.00
*Factor
1.00
*some
*additional
*comments
    zone2	zone1	10000	
    zone3	zone1   10000
EOF

    # Create od2trips configuration
    cat > od2trips.config.xml << 'EOF'
<configuration>

	<input>
		<taz-files value="zones.taz.xml"/>
		<od-matrix-files value="private_traffic.od"/>
	</input>

</configuration>

EOF
    print_success "Configuration files created"
}


# Main workflow function
run_workflow() {
    print_status "Starting automated SUMO workflow..."
    
    # Set file names based on city name
    OSM_FILE="${CITY_NAME}.osm"
    NET_FILE="${CITY_NAME}_full.net.xml"
    
    # Step 1: Download map (with existence check)
    print_status "Step 1: Checking for existing OSM map..."
    if [[ -f "$OSM_FILE" ]]; then
        print_skip "OSM file already exists: $OSM_FILE"
    else
        print_status "Downloading OSM map for $CITY_NAME..."
        echo "$CITY_NAME" | python3 get_map.py
        
        if [[ ! -f "$OSM_FILE" ]]; then
            print_error "OSM file not found: $OSM_FILE"
            exit 1
        fi
        print_success "OSM map downloaded successfully"
    fi
    
    # Step 2: Convert OSM to SUMO network (with existence check)
    print_status "Step 2: Checking for existing SUMO network..."
    if [[ -f "$NET_FILE" ]]; then
        print_skip "Network file already exists: $NET_FILE"
    else
        print_status "Converting OSM to SUMO network..."
        netconvert --osm-files "$OSM_FILE" -o "$NET_FILE" \
                   --ptstop-output osm_ptstops.xml \
                   --ptline-output osm_ptlines.xml \
                   --ignore-errors \
                   --remove-edges.isolated \
                   --ramps.guess \
                   --junctions.join
        
        if [[ ! -f "$NET_FILE" ]]; then
            print_error "Failed to create network file: $NET_FILE"
            exit 1
        fi
        print_success "Network file created successfully"
    fi

    # Step 3: Create zones (with existence check)
    print_status "Step 3: Checking for existing zones..."
    # Check for the three zone files that get_zones.py creates
    if [[ -f "zone1.xml" && -f "zone2.xml" && -f "zone3.xml" ]]; then
        print_skip "Zone files already exist: zone1.xml, zone2.xml, zone3.xml"
    else
        print_status "Creating traffic zones..."
        python3 get_zones.py "$NET_FILE" "$CENTER_X" "$CENTER_Y"
        
        # Check if all three zone files were created
        if [[ ! -f "zone1.xml" || ! -f "zone2.xml" || ! -f "zone3.xml" ]]; then
            print_error "Failed to create all zone files (zone1.xml, zone2.xml, zone3.xml)"
            exit 1
        fi
        print_success "Zones files created successfully"
    fi
    
    # Step 4: Create TAZ file (with existence check)
    print_status "Step 4: Checking for existing TAZ file..."
    if [[ -f "zones.taz.xml" ]]; then
        print_skip "TAZ file already exists: zones.taz.xml"
    else
        print_status "Creating TAZ file..."
        python3 get_taz.py
        
        if [[ ! -f "zones.taz.xml" ]]; then
            print_error "Failed to create TAZ file"
            exit 1
        fi
        print_success "TAZ file created successfully"
    fi
    
    # Step 5: Process GTFS data (with existence check)
    print_status "Step 5: Checking for existing GTFS output files..."
    if [[ -f "pt_vtypes.xml" && -f "gtfs_publictransport.rou.xml" && -f "gtfs_publictransport.add.xml" ]]; then
        print_skip "GTFS output files already exist (pt_vtypes.xml, gtfs_publictransport.rou.xml, gtfs_publictransport.add.xml)"
    else
        print_status "Processing GTFS data..."
        python3 /usr/share/sumo/tools/import/gtfs/gtfs2pt.py \
            -n "$NET_FILE" \
            --gtfs "$GTFS_PATH" \
            --date "$SIM_DATE" \
            --modes "$TRANSPORT_MODES" \
            --vtype-output pt_vtypes.xml \
            --route-output gtfs_publictransport.rou.xml \
            --additional-output gtfs_publictransport.add.xml
        
        if [[ ! -f "pt_vtypes.xml" || ! -f "gtfs_publictransport.rou.xml" || ! -f "gtfs_publictransport.add.xml" ]]; then
            print_error "Failed to create GTFS output files"
            exit 1
        fi
        print_success "GTFS processing completed successfully"
    fi
    
    print_success "Preprocessing completed successfully!"
    
    # Step 6: Run simulations
    print_status "Step 6: Running simulations..."
    run_simulations
}

# Function to run simulations
# Function to run simulations
run_simulations() {
    set +e
    print_status "📊 Starting simulation batch..."

    MAX_JOBS=$(nproc)
    BASE_SEED=12345

    # 🔢 Generate value ranges
    VALUES=()
    for ((v=1000; v<=33000; v+=1000)); do VALUES+=($v); done
    for ((v=36000; v<=64000; v+=2000)); do VALUES+=($v); done

    mkdir -p od_variants

    print_status "📁 Creating OD matrix variants..."
    for value in "${VALUES[@]}"; do
        cp private_traffic.od "od_variants/private_${value}.od"
        sed -i "s/10000/$value/g" "od_variants/private_${value}.od"
    done
    print_success "✅ OD variants created"

    NET_FILE=$(ls *.net.xml | head -1)
    if [[ -z "$NET_FILE" ]]; then
        print_error "❌ Network file not found!"
        exit 1
    fi

    job_count=0

    for value in "${VALUES[@]}"; do
        for ((sim=1; sim<=SIMS_PER_VALUE; sim++)); do
            (
                SEED=$((BASE_SEED + sim + value))
                od_file="od_variants/private_${value}.od"
                trip_file="4_${value}_${sim}_private_for.trips.xml"
                route_file="4_${value}_${sim}_private.rou.xml"
                sim_output="4_${value}_${sim}_${CITY_NAME}_sim_output.xml"

                print_status "🔵 Starting simulation #$sim for value=$value, seed=$SEED"

                # Generate trips
                print_status "🛠 Generating trips..."
                od2trips -c od2trips.config.xml -n zones.taz.xml -d "$od_file" --seed "$SEED" -o "$trip_file" || {
                    print_error "❌ Failed to generate trips"; exit 1; }

                # Generate routes
                print_status "🛣 Generating route file..."
                duarouter -n "$NET_FILE" --route-files "$trip_file" --seed "$SEED" -o "$route_file" --ignore-errors --repair || {
                    print_error "❌ Failed to generate routes"; exit 1; }

                # Run SUMO simulation
                print_status "🚦 Running SUMO simulation..."
                sumo -n "$NET_FILE" \
                     --additional pt_vtypes.xml,gtfs_publictransport.add.xml \
                     --routes gtfs_publictransport.rou.xml,"$route_file" \
                     --begin 21600 --end 36000 \
                     --seed "$SEED" \
                     --tripinfo-output "$sim_output" \
                     --ignore-route-errors || {
                    print_error "❌ SUMO failed for value=$value sim=$sim"; exit 1; }

                print_success "✅ Completed: value=$value sim=$sim"
            ) &

            ((job_count++))
            if (( job_count % MAX_JOBS == 0 )); then
                wait
            fi
        done

        wait
        print_success "🎯 Finished all $SIMS_PER_VALUE simulations for value=$value"
    done

    wait
    print_success "🏁 All simulations for all values completed!"
}


# Main execution
main() {
    echo "========================================="
    echo "    Automated SUMO Workflow Script      "
    echo "========================================="
    echo
    
    check_dependencies
    check_external_scripts
    get_user_input
    create_python_scripts
    create_config_files
    run_workflow
    
    print_success "Workflow completed successfully!"
    print_status "Output files are available in the current directory"
}

# Run main function
main "$@"
