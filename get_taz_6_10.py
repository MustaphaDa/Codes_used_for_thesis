import xml.etree.ElementTree as ET
import os

# List of input zone files
zone_files = ["zone11.xml", "zone22.xml", "zone33.xml"]
output_taz_file = "zones5.taz.xml"

# Dictionary to store edges for each zone
zones = {}

# Extract edges from each zone file
for zone_file in zone_files:
    zone_id = os.path.splitext(zone_file)[0]  # Get zone name from filename
    zones[zone_id] = []

    # Parse XML
    tree = ET.parse(zone_file)
    root = tree.getroot()

    # Find all edges inside the zone
    for edge in root.findall(".//edge"):
        edge_id = edge.get("id")
        if edge_id:
            zones[zone_id].append(edge_id)

# Generate TAZ XML file
with open(output_taz_file, "w") as f:
    f.write('<tazs>\n')
    for zone, edges in zones.items():
        # Convert list of edges to space-separated string
        edge_string = ' '.join(edges)
        # Write taz element with edges attribute
        f.write(f'    <taz id="{zone}" edges="{edge_string}"/>\n')
    f.write('</tazs>\n')

print(f"✅ Generated TAZ file: {output_taz_file}")