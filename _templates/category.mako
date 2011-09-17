<%inherit file="site.mako" />
<div class="content">
<div class="column">
<h1>Posts tagged &ldquo;${category}&rdquo;</h1>
% for post in posts:
  <%include file="post_box.mako" args="post=post" />
% endfor
</div>
</div>
