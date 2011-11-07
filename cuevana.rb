#encoding: utf-8

=begin
  Outputs a list with movies from cuevana with each download link
=end

require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'logger'

class Cuevana
  URL           = "http://www.cuevana.tv"
  ALL_MOVIES   = "/peliculas/lista/page="
  LATEST_MOVIES = "/peliculas/?page="
  SOURCE_GET    = "/player/source_get"
  SOURCE        = "/player/source?"

  def logger
    @logger ||= Logger.new $stderr
  end

  def all_movies(from = 1, to = last_page)
    movies(ALL_MOVIES, from, to)
  end

  def latest_movies()
    movies(LATEST_MOVIES, 1, 4)
  end
  
  def movies(url, from, to)
    (from..to).map do |pageNo|
      logger.info "Page Number: #{pageNo}"
      (dom_for_movies(pageNo, url) || []).map { |movie_dom| Movie.new(movie_dom) }
    end.flatten.compact
  end
  
  def dom_for_movies(pageNo, url)
    source = open("#{URL}#{url}#{pageNo}").read.force_encoding("utf-8")
    Nokogiri::HTML(source).xpath("//table//tr[@class != 'tabletit']")
  end
  private :dom_for_movies
  
  def last_page
    source = open("#{URL}#{MOVIES_LIST}0").read.force_encoding("utf-8")
    doc = Nokogiri::HTML(source)
    doc.at_xpath("/html/body/div/div[9]/span/a[6]").content.to_i
  end
  
  class Movie < Struct.new(:dom)
    def title
      @title ||= dom.at_css('.tit a').content
    end

    def links
      @links ||= sources.map do |source|
        key, host = source.to_s.slice(/\'.*\'/).gsub(/\'/, "").split(/,/)
        download_link(key, host)
      end
    end

    def to_s
      links_str = links.map { |link| " * #{link}" }.join("\n")
      "#{title}\n#{links_str}"
    end

    def page_id
      @page_id ||= dom.at_css('.tit a @href').content.split('/')[2]
    end
    private :page_id

    def sources
      source = open("#{URL}#{SOURCE}&id=#{page_id}&subs=,ES&onstart=yes&sub_pre=ES").read.force_encoding("utf-8")
      Nokogiri::HTML(source).css("html body div div div#sources ul script")
    end
    private :sources

    def download_link(key, host)
      uri = URI("#{URL}#{SOURCE_GET}")
      res = Net::HTTP.post_form(uri, 'key' => key, 'host' => host) # POST
      res.body.gsub(/[^a-zA-Z0-9\/\.\&\?=:]/, "") # from ascii to utf-8 compatibility
    end
    private :download_link
  end
end

Cuevana.new.latest_movies().each do |movie|
  puts movie
end