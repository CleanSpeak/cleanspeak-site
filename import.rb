# frozen_string_literal: true

require 'fileutils'
require 'open-uri'
require 'nokogiri'
require 'rubygems'
require 'safe_yaml'
require 'sequel'
require 'unidecode'


def self.process_post(post, db, options)
  title = post[:title]
  title = clean_entities(title) if options[:clean_entities]

  slug = post[:slug]
  slug = sluggify(title) if !slug || slug.empty?

  date = post[:date] || Time.now
  name = format("%02d-%02d-%02d-%s.%s", date.year, date.month, date.day, slug, "html")
  content = post[:content].to_s
  content = clean_entities(content) if options[:clean_entities]

  # Fix more tag
  content.sub!("<p><!--more--></p>", "<!--more-->")

  categories = []
  tags = []

  cquery =
      "SELECT
       terms.name AS `name`,
       ttax.taxonomy AS `type`
     FROM
       wp_terms AS `terms`,
       wp_term_relationships AS `trels`,
       wp_term_taxonomy AS `ttax`
     WHERE
       trels.object_id = '#{post[:id]}' AND
       trels.term_taxonomy_id = ttax.term_taxonomy_id AND
       terms.term_id = ttax.term_id"

  db[cquery].each do |term|
    if term[:type] == "category"
      categories << if options[:clean_entities]
                      clean_entities(term[:name])
                    else
                      term[:name]
                    end
    elsif term[:type] == "post_tag"
      tags << if options[:clean_entities]
                clean_entities(term[:name])
              else
                term[:name]
              end
    end
  end

  # Select the user meta data for the image and name
  uquery = "SELECT meta_key, meta_value FROM wp_usermeta WHERE user_id = #{post[:author_id]}"
  author_first_name = ""
  author_last_name = ""
  author_image_uri = ""
  db[uquery].each do |meta|
    if meta[:meta_key] == 'first_name'
      author_first_name = meta[:meta_value]
    elsif meta[:meta_key] == 'last_name'
      author_last_name = meta[:meta_value]
    elsif meta[:meta_key] == 'image'
      author_image_uri = download_image(meta[:meta_value])
    end
  end

  # Get the relevant fields as a hash, delete empty fields and
  # convert to YAML for the header.
  data = {
      "layout"            => "blog-post",
      "title"             => title.to_s,
      "author"            => "#{author_first_name} #{author_last_name}",
      "author_image"      => author_image_uri,
      "excerpt_separator" => "<!--more-->",
      "categories"        => categories,
      "tags"              => tags
  }.delete_if { |_k, v| v.nil? || v == "" }.to_yaml

  filename = "_posts/#{name}"
  if !tags.include?("Passport") && !categories.include?("Passport")
    puts "Writing #{filename} - tags#{tags} - categories#{categories}"

    # Download the images
    html_doc = Nokogiri::HTML.fragment(wpautop(content))
    html_doc.css("img").each do |img|
      img["src"] = download_image(img["src"])
    end

    # Clean up anchor tag hrefs
    html_doc.css("a").each do |a|
      a["href"] = a["href"].sub(/http[s]*:\/\/www.inversoft.com/, "")
                      .sub(/\/docs\/cleanspeak\//, "/docs/")
                      .sub(/\/cleanspeak\//, "/products/profanity-filter")
    end

    # Write out the data and content to file
    File.open(filename, "w") do |f|
      f.puts data
      f.puts "---"
      f.puts html_doc.to_s
    end
  else
    puts "Skipping #{filename} - tags#{tags} - categories#{categories}"
  end
end

def self.clean_entities(text)
  text.force_encoding("UTF-8") if text.respond_to?(:force_encoding)
  text = HTMLEntities.new.encode(text, :named)
  # We don't want to convert these, it would break all
  # HTML tags in the post and comments.
  text.gsub!("&amp;", "&")
  text.gsub!("&lt;", "<")
  text.gsub!("&gt;", ">")
  text.gsub!("&quot;", '"')
  text.gsub!("&apos;", "'")
  text.gsub!("&#47;", "/")
  text
end

def self.sluggify(title)
  title.to_ascii.downcase.gsub(%r![^0-9A-Za-z]+!, " ").strip.tr(" ", "-")
end

def self.download_image(image_uri)
  image_uri = image_uri.sub(/\[siteurl\]/, "https://www.inversoft.com/blog").sub(/http:\/\/www\.inversoft\.com/, "https://www.inversoft.com")
  begin
    url_stream = open(image_uri)
    new_location = "images/blog/#{url_stream.base_uri.to_s.split("/")[-1]}"
    IO.copy_stream(url_stream, new_location)
    "/#{new_location}"
  rescue Exception => e
    puts "++++++ ERROR downloading [#{image_uri}] [#{e}]"
    nil
  end
end

def self.wpautop(pee, br = true)
  return "" if pee.strip == ""

  allblocks = "(?:table|thead|tfoot|caption|col|colgroup|tbody|tr|td|th|div|dl|dd|dt|ul|ol|li|pre|select|option|form|map|area|blockquote|address|math|style|p|h[1-6]|hr|fieldset|noscript|legend|section|article|aside|hgroup|header|footer|nav|figure|figcaption|details|menu|summary)"
  pre_tags = {}
  pee += "\n"

  if pee.include?("<pre")
    pee_parts = pee.split("</pre>")
    last_pee = pee_parts.pop
    pee = ""
    pee_parts.each_with_index do |pee_part, i|
      start = pee_part.index("<pre")

      unless start
        pee += pee_part
        next
      end

      name = "<pre wp-pre-tag-#{i}></pre>"
      pre_tags[name] = pee_part[start..-1] + "</pre>"

      pee += pee_part[0, start] + name
    end
    pee += last_pee
  end

  pee = pee.gsub(Regexp.new('<br />\s*<br />'), "\n\n")
  pee = pee.gsub(Regexp.new("(<" + allblocks + "[^>]*>)"), "\n\\1")
  pee = pee.gsub(Regexp.new("(</" + allblocks + ">)"), "\\1\n\n")
  pee = pee.gsub("\r\n", "\n").tr("\r", "\n")
  if pee.include? "<object"
    pee = pee.gsub(Regexp.new('\s*<param([^>]*)>\s*'), "<param\\1>")
    pee = pee.gsub(Regexp.new('\s*</embed>\s*'), "</embed>")
  end

  pees = pee.split(%r!\n\s*\n!).compact
  pee = ""
  pees.each { |tinkle| pee += "<p>" + tinkle.chomp("\n") + "</p>\n" }
  pee = pee.gsub(Regexp.new('<p>\s*</p>'), "")
  pee = pee.gsub(Regexp.new("<p>([^<]+)</(div|address|form)>"), "<p>\\1</p></\\2>")
  pee = pee.gsub(Regexp.new('<p>\s*(</?' + allblocks + '[^>]*>)\s*</p>'), "\\1")
  pee = pee.gsub(Regexp.new("<p>(<li.+?)</p>"), "\\1")
  pee = pee.gsub(Regexp.new("<p><blockquote([^>]*)>", "i"), "<blockquote\\1><p>")
  pee = pee.gsub("</blockquote></p>", "</p></blockquote>")
  pee = pee.gsub(Regexp.new('<p>\s*(</?' + allblocks + "[^>]*>)"), "\\1")
  pee = pee.gsub(Regexp.new("(</?" + allblocks + '[^>]*>)\s*</p>'), "\\1")
  if br
    pee = pee.gsub(Regexp.new('<(script|style).*?</\1>')) { |match| match.gsub("\n", "<WPPreserveNewline />") }
    pee = pee.gsub(Regexp.new('(?<!<br />)\s*\n'), "<br />\n")
    pee = pee.gsub("<WPPreserveNewline />", "\n")
  end
  pee = pee.gsub(Regexp.new("(</?" + allblocks + '[^>]*>)\s*<br />'), "\\1")
  pee = pee.gsub(Regexp.new('<br />(\s*</?(?:p|li|div|dl|dd|dt|th|pre|td|ul|ol)[^>]*>)'), "\\1")
  pee = pee.gsub(Regexp.new('\n</p>$'), "</p>")

  pre_tags.each do |name, value|
    pee.gsub!(name, value)
  end
  pee
end


options = {
    :user           => "root",
    :pass           => "",
    :host           => "localhost",
    :port           => "3306",
    :socket         => "/tmp/mysql.sock",
    :dbname         => "wordpress"
}

if options[:clean_entities]
  begin
    require "htmlentities"
  rescue LoadError
    STDERR.puts "Could not require 'htmlentities', so the :clean_entities option is now disabled."
    options[:clean_entities] = false
  end
end

FileUtils.mkdir_p("_posts")

db = Sequel.mysql2(options[:dbname],
                   :user     => options[:user],
                   :password => options[:pass],
                   :socket   => options[:socket],
                   :host     => options[:host],
                   :port     => options[:port],
                   :encoding => "utf8")

posts_query = "
   SELECT
     posts.ID            AS `id`,
     posts.guid          AS `guid`,
     posts.post_type     AS `type`,
     posts.post_status   AS `status`,
     posts.post_title    AS `title`,
     posts.post_name     AS `slug`,
     posts.post_date     AS `date`,
     posts.post_date_gmt AS `date_gmt`,
     posts.post_content  AS `content`,
     posts.post_excerpt  AS `excerpt`,
     posts.comment_count AS `comment_count`,
     users.display_name  AS `author`,
     users.ID            AS `author_id`,
     users.user_login    AS `author_login`,
     users.user_email    AS `author_email`,
     users.user_url      AS `author_url`
   FROM wp_posts AS `posts`
     LEFT JOIN wp_users AS `users`
       ON posts.post_author = users.ID
   WHERE posts.post_status = 'publish' AND
         posts.post_type = 'post'"

db[posts_query].each do |post|
  # puts "Handling #{sluggify(post[:title])}"
  process_post(post, db, options)
end
