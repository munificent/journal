# Utility functions used by the scripts here.
import os

def walk(dir, callback):
    """ walks a directory, and executes a callback on each file """
    dir = os.path.abspath(dir)
    for file in [file for file in os.listdir(dir) if not file in [".",".."]]:
        nfile = os.path.join(dir, file)
        callback(nfile)
        if os.path.isdir(nfile):
            walk(nfile, callback)
