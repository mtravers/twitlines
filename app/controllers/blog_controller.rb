require 'xml/libxml'

class BlogController < ApplicationController
  
  def load
  end

  def view
  end

  def list
    @blogs = Blog.find(:all)
    @friends = twitter_friends
  end

  # doesn't really belong here unless we are doing it for other than the logged in user.
  # could take argument, paging +++
  def twitter_friends
    params = {:user => 'mtraven'} # +++ temp
    url = "http://twitter.com/statuses/friends.json?#{params.to_query}"
    json = twitter_request(url)
  end

  def read_opml_file(file)
    xml = XML::Document.file(file)    
    opmls = xml.find('//outline')
    blogs = []
    opmls.map do |o| 
      title = o['text']
      feed = o['xmlUrl']
      homepage = o['htmlUrl']
      if feed && homepage
        b = Blog.find_by_feed(feed)
        if b
          blogs.push(b)
        else
          b = Blog.new(:title => title, :homepage => homepage, :feed => feed)
          blogs.push(b)
        end
      end
    end
    blogs
  end

  # standin, this takes too long to be called in a web response
  def check_blogs(blogs)
    
  end

end
