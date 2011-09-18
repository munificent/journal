<div class="nav bottom">
<div class="column">
<table>
  <tr>
    <td>
% if post is not UNDEFINED:
      <h1>About the Post</h1>
      <p>Posted on <a href="${bf.util.site_path_helper(bf.config.blog.path,'archive')}">${post.date.strftime("%B %d, %Y")}</a>.</p>
      <%
         tag_links = []
         for tag in post.categories:
             tag_links.append("<a href='%s'>%s</a>" % (tag.path, tag.name))
      %>
      <p>Tagged ${", ".join(tag_links)}.</p>
      <p>
      <script type="text/javascript">
        reddit_url = "${post.permalink|h}/";
        reddit_title = "${post.title|h}";
      </script>
      <script type="text/javascript" src="http://www.reddit.com/static/button/button1.js"></script></p>
      <p>
      <a href="https://twitter.com/share" class="twitter-share-button" data-url="${post.permalink|h}" data-text="${post.title|h}" data-count="horizontal" data-via="munificentbob">Tweet</a><script type="text/javascript" src="//platform.twitter.com/widgets.js"></script>
      </p>
      <p><div class="g-plusone" data-size="small" data-annotation="inline" data-width="200" href="${post.permalink|h}"></div>
        <script type="text/javascript">
          (function() {
            var po = document.createElement('script');
            po.type = 'text/javascript';
            po.async = true;
            po.src = 'https://apis.google.com/js/plusone.js';
            var s = document.getElementsByTagName('script')[0];
            s.parentNode.insertBefore(po, s);
          })();
        </script>
      </p>
% else:
      <h1>Post Tags</h1>
      <ul>
      % for tag, count in bf.config.blog.all_categories:
        <li><a href="${tag.path}">${tag.name}</a> <small>${count}</small></li>
      % endfor
      </ul>
% endif
    </td>
    <td>
      <h1>About the Blog</h1>
      <p>The <a href="${bf.util.site_path_helper(bf.config.blog.path,'archive')}">archives</a> have older posts.</p>
      <p>This blog is built using <a href="http://www.blogofile.com">blogofile</a>. The source repo for it is <a href="https://github.com/munificent/journal">here</a>.</p>
    </td>
    <td>
      <h1>About Me</h1>
      <p>I've got other stuff you can see here:</p>
      <ul>
        <li>Code at <a href="http://github.com/munificent">github</a></li>
        <li>Code at <a href="http://bitbucket.org/munificent">bitbucket</a></li>
        <li>Photos at <a href="http://www.flickr.com/photos/bobisbob/">flickr</a></li>
        <li>Video at <a href="http://vimeo.com/bobisbob">vimeo</a></li>
        <li>Blurbs at <a href="http://twitter.com/munificentbob">twitter</a></li>
        <li>Posts at <a href="http://plus.google.com/100798142896685420545">google+</a></li>
        <li>My <a href="http://www.stuffwithstuff.com/bob-nystrom.html">r&eacute;sum&eacute;</a></li>
      </ul>
      <p>You can email me at <code>robert</code> at <code>stuffwithstuff.com</code>.</p>
      <p>&copy; 2008-2011 Robert Nystrom.</p>
    </td>
  </tr>
</table>
</div>
</div>