# Removes markdown titles.
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        # Parse the title and link
        content = re.sub('\n+\# \[([^\]]+)\]\(http://journal\.stuffwithstuff\.com/20\d\d/\d\d/\d\d/(\S+)/\)\n+', '\n', content)

        # Save the file back out
        with open(path, 'w') as output:
            output.write(content)

utils.walk('posts', fix_file, '.md')
