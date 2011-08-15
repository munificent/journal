# Parses the titles and permalinks from markdown.
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        # Parse the title and link
        m = re.search('\# \[([^\]]+)\]\(http://journal\.stuffwithstuff\.com/20\d\d/\d\d/\d\d/(\S+)/', content)

        # Add the title
        result = 'title = ' + m.group(1) + '\n'

        perma = utils.linkify(m.group(1))
        if perma != m.group(2):
            result = result + 'permalink = ' + m.group(2) + '\n'
            print path
            print perma
            print m.group(2)
            print '---'

        result = result + content

        # Save the file back out
        with open(path, 'w') as output:
            output.write(result)

utils.walk('posts', fix_file, '.md')
