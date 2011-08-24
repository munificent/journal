#!/usr/bin/python

import codecs
import glob
import markdown
import re
import os
import shutil
import sys
from datetime import datetime

import utils

posts = []

class Post:
    def __init__(self, path):
        # Read the post
        contents = ''
        with codecs.open(path, 'r', 'utf-8') as input:
            contents = input.read()

        front, body = contents.split('\n---\n')

        # Parse the metadata
        self.info = {}
        for line in front.split('\n'):
            name, value = re.match('(\w+)\s*=\s*(.+)', line).groups()
            self.info[name] = value

        self.body = body

        # Parse the date from the path
        self.year, self.month, self.date = re.search('(20\d\d)-(\d\d)-(\d\d)', path).groups()

        # Auto-generate permalink if not given one
        if not 'permalink' in self.info:
            self.info['permalink'] = utils.linkify(self.info['title'])

        basename = os.path.relpath(path, 'posts')
        self.basename = basename.split('.')[0]

    def output(self):
        global post_template

        html = markdown.markdown(self.body, ['def_list', 'codehilite'])

        # Insert the content
        post = post_template
        post = post.replace('$(title)', self.info['title'])
        post = post.replace('$(content)', html)

        with codecs.open('html/%s.html' % self.basename, 'w', 'utf-8') as out:
            out.write(post)

def read_post(path):
    global posts
    posts.append(Post(path))

def get_years(posts):
    '''Walks through the posts and gets the list of unique years.'''
    years = set()
    for post in posts:
        years.add(post.year)
    years = list(years)
    years.sort()
    return years

last_length = 0
def write_line(text):
    global last_length

    # Clear the previous line
    if last_length > 0:
        print ("\r" + (" " * last_length) + "\r"),

    print text,
    sys.stdout.flush()
    last_length = len(text)

# clean out the output directory
utils.kill_dir('html')

# copy over the static content
shutil.copytree('static', 'html')

# load the template page
post_template = open('templates/post.html', 'r').read()

def strip_newline(line):
    return line.rstrip()

utils.walk('posts', read_post, '.md')
i = 1
for post in posts:
    post.output()
    write_line('%s/%s' % (i, len(posts)))
    i += 1

write_line('Processed %s posts.' % (len(posts),))
