#encoding: utf-8

=begin
  Outputs a list with movies from cuevana with each download link
=end

require 'nokogiri'
require 'open-uri'
require 'net/http'

class Cuevana
  attr_reader :lastPage
  URL = "http://www.cuevana.tv"
  MOVIES_LIST = "/peliculas/lista/page="
  SOURCE_GET = "/player/source_get"
  SOURCE = "/player/source?"
  

  def initialize
    @last_page = extract_last_page()
  end
  
  def print_movies(from = 1, to = @last_page)
    from.upto(to) do |pageNo|
      $stdout.puts "Page Number: #{pageNo}"
    
      $stdout.flush
  
      movies = extract_movies(pageNo)
      break if movies.nil? || movies.empty?
  
      movies.each do |movie|
        $stdout.puts "#{extract_title(movie)}"
      
        extract_sources(movie).each do |source|
          key, host = source.to_s.slice(/\'.*\'/).gsub(/\'/, "").split(/,/)
          $stdout.puts "#{extract_download_link(key, host)}\n\n"
        end
        $stdout.flush
      end
    end
  end
  
  def extract_last_page
    movies_url = URL + MOVIES_LIST +"0"
    doc = Nokogiri::HTML(open(movies_url).read.force_encoding("utf-8"))
    doc.at_xpath("/html/body/div/div[9]/span/a[6]").content.to_i
  end
  
  def extract_title(movie)
    movie.at_css('.tit a').content
  end
  
  def extract_id(movie)
    movie.at_css('.tit a @href').content.split('/')[2]
  end
  
  def extract_sources(movie)
    player_params = "&id=#{extract_id(movie)}&subs=,ES&onstart=yes&sub_pre=ES"
    player_link = URL + SOURCE + player_params
    player = Nokogiri::HTML(open(player_link).read.force_encoding("utf-8"))
    player.css("html body div div div#sources ul script")
  end
  
  # returns an array of html tags that represents a movie
  def extract_movies(pageNo)
    movies_url = URL + MOVIES_LIST + pageNo.to_s
    doc = Nokogiri::HTML(open(movies_url).read.force_encoding("utf-8"))
    doc.xpath("//table//tr[@class != 'tabletit']")
  end
  
  def extract_download_link(key, host)
    # Uses a POST method
    uri = URI(URL + SOURCE_GET)
    res = Net::HTTP.post_form(uri, 'key' => key, 'host' => host)
    # from ascii to utf-8 compatibility
    res.body.gsub(/[^a-zA-Z0-9\/\.\&\?=:]/, "") 
  end
  
end

c = Cuevana.new
c.print_movies(3,4)