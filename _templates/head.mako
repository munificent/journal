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
