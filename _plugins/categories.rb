module StuffWithStuff
  # Generate a hyperlinked list of all categories used in any posts with their
  # occurrence counts.
  class AllCategoriesTag < Liquid::Tag
    def render(context)
      # Sort the categories.
      categories = context.registers[:site].categories.keys.sort do |a, b|
        num_a = context.registers[:site].categories[a].size
        num_b = context.registers[:site].categories[b].size

        if num_a != num_b then
          # Sort by number of posts (descending).
          num_b <=> num_a
        else
          # Or by name if the count is the same.
          a <=> b
        end
      end

      html = "<ul>"
      categories.each do |category|
        num_posts = context.registers[:site].categories[category].size
        html << "<li>"
        html << "<a href=\"/category/#{category}\">#{category}</a> "
        html << "<small>(#{num_posts})</small>"
        html << "</li>"
      end
      html << "</ul>"
      html
    end
  end

  module CategoryLinksFilter
    def categorylinks(input)
      input.sort.map { |c| "<a href=\"/category/#{c}\">#{c}</a>" }.join(' ')
    end
  end
end

Liquid::Template.register_tag('allcategories', StuffWithStuff::AllCategoriesTag)
Liquid::Template.register_filter(StuffWithStuff::CategoryLinksFilter)
