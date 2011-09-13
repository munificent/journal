# Utility functions used by the scripts here.
import os
import re
import shutil

def kill_dir(path):
    if os.path.isdir(path):
        shutil.rmtree(path)

def ensure_dir(path):
    if not os.path.isdir(path):
        os.makedirs(path)

def walk(dir, callback, extension=None):
    """ Walks a directory, and executes a callback on each file. """
    dir = os.path.abspath(dir)
    for file in [file for file in os.listdir(dir) if not file in [".",".."]]:
        nfile = os.path.join(dir, file)
        if extension == None or os.path.splitext(file)[1] == extension:
            callback(nfile)
        if os.path.isdir(nfile):
            walk(nfile, callback)

def linkify(s):
    """ Takes a string and turns it into a URL-friendly permalink form. """
    s = s.lower()
    s = re.sub('\s+', '-', s)
    s = re.sub('[^a-z0-9\-]', '', s)
    return s