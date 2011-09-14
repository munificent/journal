## Powered by <a href="http://www.blogofile.com">Blogofile</a>
##
## RSS feeds for <a href="${bf.util.site_path_helper(bf.config.blog.path,'feed')}">Entries</a>
## % if bf.config.blog.disqus.enabled:
## <a href="http://${bf.config.blog.disqus.name}.disqus.com/latest.rss">Comments</a>.
## % endif

<div class="nav bottom">
<div class="column">
<table>
  <tr>
    <td>
% if post is not UNDEFINED:
      <h1>This Post</h1>
      <p>Posted on <strong>${post.date.strftime("%B %d, %Y")}</strong>.</p>
      <%
         tag_links = []
         for tag in post.categories:
             tag_links.append("<a href='%s'>%s</a>" % (tag.path, tag.name))
      %>
      <p>Tagged ${", ".join(tag_links)}.</p>
      <p>
        <a href="http://www.reddit.com/submit" onclick="window.location = 'http://www.reddit.com/submit?url=' + encodeURIComponent(window.location); return false"> <img src="http://www.reddit.com/static/spreddit1.gif" alt="submit to reddit" border="0" /> </a>
        <a href="http://twitter.com/share" class="twitter-share-button" data-count="none" data-via="munificentbob">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>
        <g:plusone size="small" count="false"></g:plusone>

        <script type="text/javascript">
          (function() {
            var po = document.createElement('script');
            po.type = 'text/javascript'; po.async = true;
            po.src = 'https://apis.google.com/js/plusone.js';
            var s = document.getElementsByTagName('script')[0];
            s.parentNode.insertBefore(po, s);
          })();
        </script>
      </p>
      <h1>Posts by Date</h1>
      <ul>
        $(years)
      </ul>
% endif

    </td>
    <td>
      <h1>Posts by Tag</h1>
      <ul>
        $(alltags)
      </ul>
    </td>
    <td>
      <h1>Other Stuff</h1>
      <ul>
        <li>Code at <a href="http://github.com/munificent">github</a></li>
        <li>Code at <a href="http://bitbucket.org/munificent">bitbucket</a></li>
        <li>Photos at <a href="http://www.flickr.com/photos/bobisbob/">flickr</a></li>
        <li>Video at <a href="http://vimeo.com/bobisbob">vimeo</a></li>
        <li>Blurbs at <a href="http://twitter.com/munificentbob">twitter</a></li>
        <li>Posts at <a href="http://plus.google.com/100798142896685420545">google+</a></li>
        <li>My <a href="http://www.stuffwithstuff.com/bob-nystrom.html">r&eacute;sum&eacute;</a></li>
      </ul>
      <h1>Contact</h1>
      <p>You can email me at <code>robert</code> at <code>stuffwithstuff.com</code>.</p>
      <p>&copy; 2008-2011 Robert Nystrom.</p>
    </td>
  </tr>
</table>
</div>
</div>