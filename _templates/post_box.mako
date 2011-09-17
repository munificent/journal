<%page args="post"/>

<%
 tag_links = []
 for tag in post.categories:
     tag_links.append("<a href='%s'>%s</a>" % (tag.path, tag.name))
%>
<div class="post-box">
<h2><a href="${post.permapath()}" rel="bookmark" title="Permanent Link to ${post.title}">${post.title}</a></h2>
<p>Posted on ${post.date.strftime("%Y/%m/%d")}. Tagged ${", ".join(tag_links)}.</p>
</div>
