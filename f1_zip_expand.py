#! /usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import os

def checkInput():
    try:
        source = sys.argv[1]
    except:
        return({"err": 1, "file": "N/D", "msg": "Correct syntax is 'python3 " + sys.argv[0] + " [path/to/]<zipfile> [expand/dir]'."})

    if not os.path.isfile(source):
        return({"err": 2, "file": source, "msg": "File could not be reached."})

    import filetype
    try:
        t = filetype.guess(source)
    except:
        return({"err": 4, "file": source, "msg": "Could not read mime type from file."})

    if not t or t.mime != "application/zip":
        return({"err": 8, "file": source, "msg": "File is not a valid zip file."})

    return({"err": 0, "file": source})
 
def expand(source):
    try:
        destination = sys.argv[2]
    except:
        destination = "tmp"

    try:
        if not os.path.isdir(destination): os.makedirs(destination)
    except OSError as err:
        return({"err": 16, "msg": err})

    from zipfile import ZipFile
    try:
        with ZipFile(source, "r") as obj:
            obj.extractall(destination)
            return({"err": 0, "count": len(obj.infolist()), "destination": destination})
    except OSError as err:
        return({"err": 32, "msg": err})

valid = checkInput()
if valid["err"] > 0:
    print("# Error #{} on validating input [{}]: {}".format(valid["err"], valid["file"], valid["msg"]))
    sys.exit(valid["err"])

expanded = expand(valid["file"])
if expanded["err"] > 0:
    print("# Error #{} on expanding file [{}]: {}".format(expanded["err"], expanded["msg"]))
    sys.exit(expanded["err"])

print("# {} file/s expanded into [{}/], form [{}].".format(expanded["count"], expanded["destination"], valid["file"]))

#M# shell, command line, parameters, arguments, errors, error return, try, except, dictionary, dictionary return, mime, file type, mime type, unzip, expand, extract, check/validate file/dir, create dir 

