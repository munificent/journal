#!/usr/bin/python

import codecs
import glob
import markdown
import os
import shutil
from datetime import datetime

import utils

def html_path(pattern):
    return 'html/' + pattern + '.html'

def format_file(path):
    contents = ''
    with codecs.open(path, 'r', 'utf-8') as input:
        contents = input.read()

    html = markdown.markdown(contents, ['def_list', 'codehilite'])

    basename = os.path.relpath(path, 'posts')
    basename = basename.split('.')[0]
    print basename

    utils.ensure_dir('html')

    with codecs.open('html/%s.html' % basename, 'w', 'utf-8') as out:
        out.write(html)

count = 0
def do_format(path):
    global count
    if os.path.splitext(path)[1] == '.md':
        count += 1
        format_file(path)

# clean out the output directory
utils.kill_dir('html')

# copy over the static content
#shutil.copytree('static', 'html')

def strip_newline(line):
    return line.rstrip()

utils.walk('posts', do_format)
print 'Generated', count, 'HTML files.'
