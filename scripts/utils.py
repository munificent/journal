# Utility functions used by the scripts here.
import os
import shutil

def kill_dir(path):
    if os.path.isdir(path):
        shutil.rmtree(path)

def ensure_dir(path):
    if not os.path.isdir(path):
        os.makedirs(path)

def walk(dir, callback):
    """ walks a directory, and executes a callback on each file """
    dir = os.path.abspath(dir)
    for file in [file for file in os.listdir(dir) if not file in [".",".."]]:
        nfile = os.path.join(dir, file)
        callback(nfile)
        if os.path.isdir(nfile):
            walk(nfile, callback)
