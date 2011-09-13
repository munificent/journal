# Comma separate tags.
import utils
import re
import os.path

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()

        basename = os.path.relpath(path, '_posts')
        basename = basename.split('.')[0]
        date = basename.replace('-', '/')
        print date

        def fixcommas(g):
            return 'tags: ' + g.group(1).replace(' ', ', ') + '\n'

        # Parse the title and link
        content = re.sub('tags: ([^\n]+)\n',
            fixcommas,
            content)

        # Save the file back out
        with open(path, 'w') as output:
            output.write(content)

utils.walk('_posts', fix_file, '.md')
