#! /usr/bin/python3
# -*- coding: utf-8 -*-

import sys

def checkInput():
    if len(sys.argv) < 3:
        return({"err": 1, "file": "N/D", "msg": "Correct syntax is 'python3 " + sys.argv[0] + " [path/to/]<xmlfile> <param to search> [param_2] [param_n]'."})
        #return({"err": 1, "file": "N/D", "msg": "Correct syntax is 'python3 " + sys.argv[0] + " [path/to/]<xmlfile> [param1@path.to.node] [param2+param3@path.to.node]'."})

    source = sys.argv[1]

    import os
    if not os.path.isfile(source):
        return({"err": 2, "file": source, "msg": "File could not be reached."})

    import mimetypes
    try:
        t = mimetypes.guess_type(source)
    except:
        return({"err": 4, "file": source, "msg": "Could not read mime type from file."})

    if not t or t[0] != "application/xml":
        return({"err": 8, "file": source, "msg": "File is not a valid xml file."})

    return({"err": 0, "file": source, "parameters count": len(sys.argv) - 2, "parameters": sys.argv[2:]})

def parseXML(source):
    from lxml import etree
    root = etree.parse(source).getroot()
    print("# Root tag: {}.".format(root.tag))
    #print("# Direction: {}.".format(root["ProductDb"]["Product"]["CustomParameters"]["NCM"]))

    print("PID;NCM;CEST;CFOP")

    n, c, p = 0, 0, 0
    for node in root:
        n +=1
        if node.tag != "Product": continue
        pid = None
        #print("# Node tag: {}.".format(node.tag))
        for child in node.getchildren():
            c += 1
            if child.tag == "ProductCode":
                pid = child.text
                continue
            elif child.tag != "CustomParameters":
                continue

            ncm, cest, cfop = None, None, None
            for param in child.getchildren():
                p += 1
                if param.get("name") not in sys.argv: continue
                if param.get("name") == "NCM": ncm = param.get("value")
                elif param.get("name") == "CEST": cest = param.get("value")
                elif param.get("name") == "CFOP": cfop = param.get("value")
                #if p > 3: continue

            print("{};{};{};{}".format(pid, ncm, cest, cfop))
            #if c > 20: continue
        #if n > 5: break

valid = checkInput()
if valid["err"] > 0:
    print("# Error #{} on validating input [{}]: {}".format(valid["err"], valid["file"], valid["msg"]))
    sys.exit(valid["err"])

print("# Searching {} parameter/s from [{}]: {}...".format(valid["parameters count"], valid["file"], valid["parameters"]))

parseXML(valid["file"])

#print("# {} file/s expanded into [{}/], form [{}].".format(expanded["count"], expanded["destination"], valid["file"]))

#M# shell, command line, parameters, arguments, errors, error return, try, except, dictionary, dictionary return, mime, file type, mime type, check/validate file, xml into dictionary, xml parameters


# Root found: <Element ProductDb at 0x7f61563ab4c8>.
#Node: <Element Product at 0x7f61563ab488>
#Child: <Element ProductCode at 0x7f61563ab5c8>
#Child: <Element Barcode at 0x7f61563ab608>
#Child: <Element Secondary at 0x7f61563ab648>

