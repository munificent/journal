# Parses the post tags from the markdown..
import utils
import re

def fix_file(path):
    with open(path, 'r') as input:
        content = input.read()
        tags = re.findall('"View all posts in ([^""]+)"', content)
        tagline = ' '.join(tags)
        print tagline

        # Save the file back out
        content = 'tags = ' + tagline + '\n---\n' + content
        with open(path, 'w') as output:
            output.write(content)

utils.walk('posts', fix_file, '.md')
