# Renames the post files to Jekyll-style.
import os.path

import utils
import re

#   http://journal.stuffwithstuff.com/2008/02/09/

def fix_file(path):
    with open(path, 'r') as input:
        print path

        m = re.search('(.*)\.markdown', os.path.basename(path))
        date = m.group(1)

        content = input.read()
        m = re.search('title: "(.*)"', content)
        perm = utils.linkify(m.group(1))

        # Save the file back out
        with open('new/%s-%s.md' % (date, perm), 'w') as output:
            output.write(content)

utils.ensure_dir('new')
utils.walk('_posts', fix_file, '.markdown')
