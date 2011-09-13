# Removes duplicate newlines.
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()

        content = content.replace('\n\n\n', '\n\n')
        content = content.replace('\n\n\n', '\n\n')
        content = content.replace('\n\n\n', '\n\n')

        # Save the file back out
        with open(path, 'w') as output:
            output.write(content)

utils.walk('posts', fix_file, '.md')
