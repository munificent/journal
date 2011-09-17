################################################################################
## Archives controller
##
## Writes out yearly, monthly, and daily archives.
## Each archive is navigable to the next and previous archive
## in which posts were made.
################################################################################

import operator

from blogofile.cache import bf
import chronological

blog = bf.config.controllers.blog


def run():
    write_archive()

def sort_into_archives():
    for post in blog.posts:
        link = post.date.strftime("%Y")
        try:
            blog.archived_posts[link].append(post)
        except KeyError:
            blog.archived_posts[link] = [post]

    for archive, posts in sorted(
        blog.archived_posts.items(), key=operator.itemgetter(0), reverse=True):
        name = posts[0].date.strftime("%Y")
        blog.archive_links.append((archive, name, len(posts)))
        blog.archive_years.append(name)

def write_archive():
    """ Write a single chronological listing page"""
    page_dir = bf.util.path_join(blog.path, "archive")
    fn = bf.util.path_join(page_dir, "index.html")
    env = {
        "years": blog.archive_years,
        "posts": blog.archived_posts
    }
    bf.writer.materialize_template("chronological.mako", fn, env)
