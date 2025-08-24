#!/usr/bin/env python3

import sys
import math
import xml.etree.ElementTree as ET

def calculate_distance(x: float, y: float, cx: float, cy: float) -> float:
    return math.hypot(x - cx, y - cy)

def parse_edge_shapes(input_file: str, center_x: float, center_y: float):
    tree = ET.parse(input_file)
    root = tree.getroot()

    zone1_edges, zone2_edges, zone3_edges = [], [], []

    for edge in root.findall("edge"):
        shape_str = edge.get("shape")
        if not shape_str:
            continue

        x, y = map(float, shape_str.split()[0].split(","))
        dist = calculate_distance(x, y, center_x, center_y)

        if dist <= 2000:
            zone1_edges.append(edge.attrib["id"])
        elif dist <= 5000:
            zone2_edges.append(edge.attrib["id"])
        else:
            zone3_edges.append(edge.attrib["id"])

    return zone1_edges, zone2_edges, zone3_edges

def save_edges_to_xml(edge_ids, filename):
    root = ET.Element("edges")
    for eid in edge_ids:
        ET.SubElement(root, "edge", id=eid)
    ET.ElementTree(root).write(filename, encoding="utf-8", xml_declaration=True)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python get_zones.py <input_file> <CENTER_X> <CENTER_Y>")
        sys.exit(1)

    input_file = sys.argv[1]

    try:
        center_x = float(sys.argv[2])
        center_y = float(sys.argv[3])
    except ValueError:
        print("CENTER_X and CENTER_Y must be valid numbers.")
        sys.exit(1)

    zone1, zone2, zone3 = parse_edge_shapes(input_file, center_x, center_y)

    save_edges_to_xml(zone1, "zone1.xml")
    save_edges_to_xml(zone2, "zone2.xml")
    save_edges_to_xml(zone3, "zone3.xml")

    print("✔ Zone files created: zone1.xml, zone2.xml, zone3.xml")

