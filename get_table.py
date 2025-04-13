import xml.etree.ElementTree as ET
import pandas as pd

def extract_trip_data(file):
    """Extracts trip data (vehicle ID, arrival time) from SUMO tripinfo.xml."""
    tree = ET.parse(file)
    root = tree.getroot()
    trip_data = {}

    for trip in root.findall('tripinfo'):
        vehicle_id = trip.get('id')
        arrival_time = float(trip.get('arrival'))
        trip_data[vehicle_id] = arrival_time
    
    return trip_data

# Load data
public_only = extract_trip_data("tripinfo.xml")
with_private = extract_trip_data("tripinfo_with_private1.xml")

# Identify public vehicles (non-numeric IDs)
public_vehicles = {vid: arr for vid, arr in public_only.items() if not vid.isdigit()}

# Prepare data for Excel
data = []
for vid in public_vehicles:
    if vid in with_private:
        expected_arrival = public_vehicles[vid]
        actual_arrival = with_private[vid]
        delay = actual_arrival - expected_arrival
        data.append([vid, expected_arrival, actual_arrival, delay])

# Create DataFrame
df = pd.DataFrame(data, columns=["Vehicle ID", "Expected Arrival", "Actual Arrival", "Delay"])

# Save as Excel file
df.to_excel("public_transport2_delay.xlsx", index=False)

print("Excel file 'public_transport_delay.xlsx' generated successfully!")
