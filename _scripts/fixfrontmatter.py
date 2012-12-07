# Removes the date from the front-matter and comments out the title.
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        # Comment out the categories
        content = re.sub('categories: ', '#categories: ', content)

        # Delete the date
        content = re.sub('date: (.*)\n', '', content)

        # Save the file back out
        with open(path, 'w') as output:
            output.write(content)

utils.walk('_posts', fix_file, '.md')
