# Renames the post files based on their date.
import utils
import re

#   http://journal.stuffwithstuff.com/2008/02/09/

def fix_file(path):
    with open(path, 'r') as input:
        print path
        content = input.read()
        m = re.search('http://journal\.stuffwithstuff\.com/(20\d\d)/(\d\d)/(\d\d)', content)
        print m.group(1), m.group(2), m.group(3)

        # Save the file back out
        with open('new/%s-%s-%s.md' % (m.group(1), m.group(2), m.group(3)), 'w') as output:
            output.write(content)

utils.ensure_dir('new')
utils.walk('posts', fix_file, '.md')
