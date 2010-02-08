require 'xml/libxml'

class BlogController < ApplicationController
  
  def upload
  end

  def upload_file
    xml = XML::Document.io(params[:upload][:opmlfile])
    @blogs = read_opml(xml)
    @user = current_user
    @user.subscriptions = @blogs        # no, argh, this relationship is for blog/owners, not blog/followers.
    render :html => 'uploaded'
  end

  def load
  end

  def view
  end

  def list
    @user = current_user
    @blogs = @user.subscriptions
    @friends = twitter_friends
    @dom = 0
  end

  # in progress
  def delayed_list
  end

  def twitter_direct_message(to, message)
    tparams = { :user => to.tname, :text => message}
    url = "http://twitter.com/direct_messages/new.json?#{tparams.to_query}"
    twitter_request_authenticated(url, '', :post)
  end

  # doesn't really belong here unless we are doing it for other than the logged in user.
  # could take argument, paging +++
  def twitter_friends
#    tparams = {:user_id => 'mtraven'} # +++ temp
    tparams = { }
    url = "http://twitter.com/statuses/friends.json" # ?#{tparams.to_query}"
    json = twitter_request_authenticated(url)
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
