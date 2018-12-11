module Jekyll
  class TagsAndCategories < Generator
    def generate(site)
      site.categories.each do |category|
        build_pages(site, "category", category)
      end

      site.tags.each do |tag|
        build_pages(site, "tag", tag)
      end
    end

    # Do the actual generation.
    def build_pages(site, type, posts)
      posts[1] = posts[1].sort_by {|p| -p.date.to_f}
      paginate(site, type, posts)
    end

    def paginate(site, type, posts)
      pages = Paginate::Pager.calculate_pages(posts[1], site.config["paginate"].to_i)
      (1..pages).each do |num_page|
        # Change the pagination path so this works
        old_paginate_path = site.config["paginate_path"]
        site.config["paginate_path"] = "/blog/#{type}/#{posts[0].downcase}/page/:num/"

        pager = Paginate::Pager.new(site, num_page, posts[1], pages)
        path = "/blog/#{type}/#{posts[0].downcase}"
        if num_page > 1
          path = path + "/page/#{num_page}"
        end
        new_page = GroupSubPage.new(site, site.source, path)
        new_page.pager = pager
        site.pages << new_page

        # Revert the pagination page back
        site.config["paginate_path"] = old_paginate_path
      end
    end
  end

  class GroupSubPage < Page
    def initialize(site, base, dir)
      @site = site
      @base = base
      @dir = dir
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, "_layouts"), "blog-index.html")
    end
  end
end