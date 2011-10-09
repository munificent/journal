<link href='http://fonts.googleapis.com/css?family=Varela+Round' rel='stylesheet' type='text/css'>
% if post is not UNDEFINED:
  <title>${post.title|h} | ${bf.config.blog.name}</title>
% else:
  <title>${bf.config.blog.name}</title>
% endif
<link rel="alternate" type="application/rss+xml" title="RSS 2.0" href="${bf.util.site_path_helper(bf.config.blog.path,'/feed')}" />
<link rel="alternate" type="application/atom+xml" title="Atom 1.0"
href="${bf.util.site_path_helper(bf.config.blog.path,'/feed/atom')}" />
<link rel='stylesheet' href='${bf.util.site_path_helper('style.css')}' type='text/css' />
<script type="text/javascript">
function toggleGrid() {
  var header = document.querySelector('.nav.top .column');
  var content = document.querySelector('.content .column');
  if (header.className == 'column grid') {
    header.className = 'column';
    content.className = 'column';
  } else {
    header.className = 'column grid';
    content.className = 'column grid';
  }
}
</script>