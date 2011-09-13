# Converts my hacked front matter to YAML.
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        # Parse the title and link
#        m = re.search('\# \[([^\]]+)\]\(http://journal\.stuffwithstuff\.com/20\d\d/\d\d/\d\d/(\S+)/', content)
        if 'permalink = ' in content:
            m = re.match('^title = ([^\n]+)\npermalink = ([^\n]+)\ntags = ([^\n]+)\n',
                content)
            print m.group(1), m.group(2), m.group(3)
        else:
            m = re.match('^title = ([^\n]+)\ntags = ([^\n]+)\n',
                content)
            print m.group(1), m.group(2)

'''
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
'''

utils.walk('_posts', fix_file, '.md')
