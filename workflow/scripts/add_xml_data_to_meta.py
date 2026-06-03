import json
import argparse
import re
from pathlib import Path
from lxml import etree

def add_csa_data_to_meta(json_path: str, protocol_path: str):
    with open(json_path, "r") as f:
         meta = json.load(f)
    protocol_name = meta["StudyDescription"].split(" ")[-1]
    xml_search_pattern = "*" + protocol_name + "*/*.xml"
    protocol_path = Path(protocol_path)
    xml_path_list = sorted(protocol_path.rglob(xml_search_pattern, case_sensitive=False))
    if len(xml_path_list) > 0:
        xml_path = xml_path_list[0]
        xml_tree = etree.parse(xml_path)
        xml_root = xml_tree.getroot()
