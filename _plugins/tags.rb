# place this file in your plugins directory and add the tag to your sidebar
#$ cat source/_includes/custom/asides/categories.html
#<section>
#  <h1>Categories</h1>
#  <ul id="categories">
#    {% category_list %}
#  </ul>
#</section>

module Jekyll
  # Generate a hyperlinked list of all tags used in any posts with their
  # occurrence counts.
  class AllTagsTag < Liquid::Tag
    def render(context)
      html = ""
      tags = context.registers[:site].tags.keys
      tags.sort.each do |tag|
        num_posts = context.registers[:site].tags[tag].size
        html << "<li>"
        html << "<a href=\"/category/#{tag}\">#{tag}</a> <small>#{num_posts}</small>"
        html << "</li>"
      end
      html
    end
  end

  # Generate a comma-separated hyperlinked list of the tags used on the current
  # post.
  class PostTagsTag < Liquid::Tag
    def render(context)
      # See: http://stackoverflow.com/questions/7478731/how-do-i-detect-the-current-page-in-a-jekyll-tag-plugin
      page = context.environments.first["page"]
      html = ""
      page['tags'].sort.each do |tag|
        if html != "" then html << ", " end
        html << "<a href=\"/category/#{tag}\">#{tag}</a>"
      end
      html
    end
  end
end

Liquid::Template.register_tag('alltags', Jekyll::AllTagsTag)
Liquid::Template.register_tag('posttags', Jekyll::PostTagsTag)
