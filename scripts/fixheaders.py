# Knocks a level off the header tags.
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        content = re.sub('\#\#', '#', content, re.MULTILINE)

        # Save the file back out
        with open(path, 'w') as output:
            output.write(content)

utils.walk('posts', fix_file, '.md')
