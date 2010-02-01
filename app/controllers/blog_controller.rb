require 'xml/libxml'

class BlogController < ApplicationController
  
  def upload
  end

  def upload_file
    xml = XML::Document.io(params[:upload][:opmlfile])
    @blogs = read_opml(xml)
    render :html => 'uploaded'
  end

  def load
  end

  def view
  end

  def list
    @blogs = Blog.find(:all)
    @friends = twitter_friends
    @dom = 0
  end

  # doesn't really belong here unless we are doing it for other than the logged in user.
  # could take argument, paging +++
  def twitter_friends
    params = {:user => 'mtraven'} # +++ temp
    url = "http://twitter.com/statuses/friends.json?#{params.to_query}"
    json = twitter_request(url)
  end

  def read_opml_file(file)
    read_opml(XML::Document.file(file))
  end

  def read_opml(xml)
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
