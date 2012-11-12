# now a gem?
# require 'xml/libxml'

class BlogsController < ApplicationController
  
  def upload
  end

  def upload_file
    begin
      xml = XML::Document.io(params[:upload][:opmlfile])
      @blogs = read_opml(xml)
      throw "No blogs found" unless @blogs
      @user = current_user
      @user.subscriptions = @blogs
      LogEntry.log(@user.tname, "#{@blogs.length} blogs uploaded")
    rescue Exception => whoops
      flash[:warning] = "Upload failed"
      redirect_to "/blogs"
    end
  end

  def load
  end

  def view
  end

  def show
    @user = current_user
    if @user == nil
      session[:oauth_redirect] = '/blogs'
      redirect_to "/connect"    # won't come back to blogs page I think
    else
      @blogs = @user.subscriptions
      if @blogs.length == 0
        redirect_to '/blogs/upload'
      end
      @friends = twitter_friends
      @dom = 0
    end
  end

  def delayed_show
    twitter_add_friend(ENV['TWITTER_USER'])
    Cheepnis.enqueue(current_user)
  end

  def twitter_add_friend(f)
    # need to test if we are already a friend, otherwise error gets generated
    test_params = { :user_a => f, :user_b => current_user.tname}
    test_url = "http://api.twitter.com/1/friendships/exists.json?#{test_params.to_query}"
    test_json = twitter_request(test_url, :get, false, false)
    if !test_json
      url = "http://api.twitter.com/1/friendships/create/#{f}.json"
      json = twitter_request_authenticated(url, :post)
    end
  end

  # doesn't really belong here unless we are doing it for other than the logged in user.
  # could take argument, paging +++
  def twitter_friends(cursor=-1)
    tparams = { :cursor => cursor }
    url = "http://twitter.com/statuses/friends.json?#{tparams.to_query}"
    json = twitter_request_authenticated(url)
    nextc = json['next_cursor']
    users = json['users']
    if nextc != 0
      users = users + twitter_friends(nextc)
    end
    users
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
