# Replaces blogofile-style code blocks with liquid ones.
import utils
import re

def fix_file(path):
    content = ''

    empty_lines = ''
    indent = None
    # Language of current code block or None if not in code.
    language = None

    with open(path, 'r') as input:
        print path
        for line in input:
            if line.strip() == '':
                empty_lines += '\n'
            elif language:
                # See if this line ends the code block.
                if line.startswith(indent):
                    content += empty_lines
                    empty_lines = ''
                    content += line[len(indent):]
                else:
                    content += '{% endhighlight %}\n'
                    content += empty_lines
                    empty_lines = ''
                    content += line
                    indent = None
                    language = None
            else:
                content += empty_lines
                empty_lines = ''
                # See if this line starts a code block.
                m = re.search('((    )+):::(.*)\n$', line)
                if m:
                    indent = m.group(1)
                    language = m.group(3)
                    content += '{% highlight ' + language + ' %}\n'
                else:
                    content += line

    # Save the file back out
    with open(path, 'w') as output:
        output.write(content)

utils.walk('_posts', fix_file)
