import xml.etree.ElementTree as ET
import math

def calculate_distance(x, y, center_x, center_y):
    return math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)

def parse_edge_shapes(input_file, center_x, center_y):
    tree = ET.parse(input_file)
    root = tree.getroot()
    
    zone1_edges = []  # 0 - 2km
    zone2_edges = []  # 2km - 8km
    zone3_edges = []  # 8km+
    
    for edge in root.findall('edge'):
        if 'shape' in edge.attrib:
            shape = edge.attrib['shape'].split()
            coords = [tuple(map(float, coord.split(','))) for coord in shape]
            
            # Take the first point of the edge as reference
            x, y = coords[0]
            distance = calculate_distance(x, y, center_x, center_y)
            
            if distance <= 2000:
                zone1_edges.append(edge.attrib['id'])
            elif 2000 < distance <= 5000:
                zone2_edges.append(edge.attrib['id'])
            else:
                zone3_edges.append(edge.attrib['id'])
    
    return zone1_edges, zone2_edges, zone3_edges

def save_edges_to_xml(edges, filename):
    root = ET.Element('edges')
    for edge_id in edges:
        ET.SubElement(root, 'edge', id=edge_id)
    
    tree = ET.ElementTree(root)
    tree.write(filename)

if __name__ == "__main__":
    INPUT_FILE = "debrecen1.net.xml"
    CENTER_X, CENTER_Y = 21101.75, 14385.89
    
    zone1, zone2, zone3 = parse_edge_shapes(INPUT_FILE, CENTER_X, CENTER_Y)
    
    save_edges_to_xml(zone1, "zone1.xml")
    save_edges_to_xml(zone2, "zone2.xml")
    save_edges_to_xml(zone3, "zone3.xml")
    
    print("Zone files created: zone1.xml, zone2.xml, zone3.xml")
