class Blog < ActiveRecord::Base

  def find_twitterers
#    purl = URI.parse(homepage)
    begin
#      res = Net::HTTP.start(purl.host, purl.port) { |http| http.get(homepage, {"User-Agent" => "twitlines"}) }
      res = HTTParty.get(homepage)
      if res.code == 200
        html = res.body
      else
        # doesn't handle redirects
        throw "Error retrieving page " + res.message + " url was: " + homepage
      end
      matches = html.scan(/http:\/\/twitter.com\/([A-Za-z0-9\-_]+)/) 
      matches = matches.map { |m| m[0] }
      matches.uniq!
      matches = matches - ["home", "javascripts", "statuses"]
    rescue StandardError => whoops
      puts 'Error: ' + whoops
    end
  end

end

# testers
# Blog.find(:all).map {|b| puts b.title; p b.find_twitterers }
