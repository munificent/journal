#!/usr/bin/python

import codecs
import glob
import markdown
import re
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

    front, body = contents.split('\n---\n')

    # Parse the metadata
    fields = {}
    for line in front.split('\n'):
        print line
        name, value = re.match('(\w+)\s*=\s*(.+)', line).groups()
        fields[name] = value

    html = markdown.markdown(body, ['def_list', 'codehilite'])

    basename = os.path.relpath(path, 'posts')
    basename = basename.split('.')[0]

    title = 'TITLE HERE'

    # load the template page
    post = open('templates/post.html', 'r').read()

    # insert the content
    post = post.replace('$(title)', fields['title'])
    post = post.replace('$(content)', html)

    with codecs.open('html/%s.html' % basename, 'w', 'utf-8') as out:
        out.write(post)

    print basename

count = 0
def do_format(path):
    global count
    if os.path.splitext(path)[1] == '.md':
        count += 1
        format_file(path)

# clean out the output directory
utils.kill_dir('html')

# copy over the static content
shutil.copytree('static', 'html')

def strip_newline(line):
    return line.rstrip()

utils.walk('posts', do_format)
print 'Generated', count, 'HTML files.'
