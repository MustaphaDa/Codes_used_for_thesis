import requests

# Define the Overpass API endpoint
overpass_url = "http://overpass-api.de/api/interpreter"

# Overpass query to get full map (roads + public transport) of Debrecen
overpass_query = """
[out:xml];
area[name="Debrecen"]->.searchArea;
(
  node(area.searchArea);
  way(area.searchArea);
  relation(area.searchArea);
);
out body;
>;
out skel qt;
"""

print("Downloading full OSM map (including public transport) for Debrecen...")

# Send request to Overpass API
response = requests.post(overpass_url, data={'data': overpass_query})

# Check if the request was successful
if response.status_code == 200:
    # Save the result to a file
    with open("debrecen_full.osm", "wb") as file:
        file.write(response.content)
    print("Full map successfully downloaded and saved as 'debrecen_full.osm'")
else:
    print(f"Failed to download data. HTTP Status Code: {response.status_code}")
