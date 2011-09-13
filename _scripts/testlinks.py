# Checks that our generated permalinks match the existing ones.
import utils
import re

# # [abc](http://journal.stuffwithstuff.com/2008/02/09/c-extension-methods-not-just-for-breakfast/ "abc")

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        m = re.search('\# \[([^\]]+)\]\(http://journal\.stuffwithstuff\.com/20\d\d/\d\d/\d\d/(\S+)/', content)
        perma = utils.linkify(m.group(1))
        if perma != m.group(2):
            print path
            print perma
            print m.group(2)
            print '---'

utils.walk('posts', fix_file, '.md')
