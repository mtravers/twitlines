class Blog < ActiveRecord::Base

  has_and_belongs_to_many :subscribers, :class_name => 'User', :join_table => 'blog_subscribers'
  has_and_belongs_to_many :owners, :class_name => 'User', :join_table => 'blog_owners'

  # slow -- needs to be done in a worker.
  def find_twitterers
    begin
      res = HTTParty.get(homepage)
      if res.code == 200
        html = res.body
      else
        # doesn't handle redirects
        throw "Error retrieving page " + res.message + " url was: " + homepage
      end
      owners = []
      matches = html.scan(/http:\/\/twitter.com\/([A-Za-z0-9\-_]+)/) 
      matches = matches.map { |m| m[0] }
      matches.uniq!
      matches = matches - ["home", "javascripts", "statuses"]
        matches.each {|u| owners << User.find_or_make(u) }
      p [title, owners]
      save!
    rescue StandardError => whoops
      puts 'Error: ' + whoops
    end
  end

  # not really, will do repeated queries if nothing is found.
  def twitterers
    if owners == []
#      find_twitterers
    end
    owners
  end

end

# testers
# Blog.find(:all).map {|b| puts b.title; p b.find_twitterers }
