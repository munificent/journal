module Jekyll
  # Generate a hyperlinked list of all categories used in any posts with their
  # occurrence counts.
  class AllCategoriesTag < Liquid::Tag
    def render(context)
      html = ""
      categories = context.registers[:site].categories.keys
      categories.sort.each do |category|
        num_posts = context.registers[:site].categories[category].size
        html << "<li>"
        html << "<a href=\"/category/#{category}\">#{category}</a> <small>#{num_posts}</small>"
        html << "</li>"
      end
      html
    end
  end

  # Generate a comma-separated hyperlinked list of the tags used on the current
  # post.
  class PostCategoriesTag < Liquid::Tag
    def render(context)
      # See: http://stackoverflow.com/questions/7478731/how-do-i-detect-the-current-page-in-a-jekyll-tag-plugin
      page = context.environments.first["page"]
      html = ""
      page['categories'].sort.each do |category|
        if html != "" then html << ", " end
        html << "<a href=\"/category/#{category}\">#{category}</a>"
      end
      html
    end
  end

  # Include the post slug to template data. (Not used right now.)
=begin
  class Post
    alias orig_to_liquid to_liquid
    def to_liquid
      hash = self.orig_to_liquid
      hash['slug'] = self.slug
      hash
    end
  end
=end
end

Liquid::Template.register_tag('allcategories', Jekyll::AllCategoriesTag)
Liquid::Template.register_tag('postcategories', Jekyll::PostCategoriesTag)
