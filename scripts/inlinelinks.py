# Replaces links in footnote form with their inline form.
# TODO(bob): This looks like it works, but I haven't run it an committed the
# changes yet. Want to get some markdown processing running first so I can make
# sure the results look OK.
import utils
import re

#   [50]: http://en.wikipedia.org/wiki/Algebraic_data_type

def fix_file(path):
    # Make a map of all of the footnote links.
    links = {}
    content = ''
    with open(path, 'r') as input:
        for line in input:
            # See if this line is a footnote link.
            m = re.search('   \[([0-9]+)\]: (http://[\w\./\%\-]+)(?: \(([^\)]+)\))?$', line)
            if m:
                # Yup, key it's number.
                num, link, desc = m.groups('')
                links[num] = (link, desc)
            else:
                # Not a link line, so add it
                content += line

    # Now replace all of the footnoted links with inline ones.
    for num, pair in links.iteritems():
        def replace_link(m):
            if pair[1] != '':
                return '[%s](%s "%s")' % (m.group(1), pair[0], pair[1])
            else:
                return '[%s](%s)' % (m.group(1), pair[0])

        pattern = '\[([^\]]+)\]\[%s\]' % (num)
        content = re.sub(pattern, replace_link, content)

    # Save the file back out
    with open(path, 'w') as output:
        output.write(content)

utils.walk('posts', fix_file)
