class User < ActiveRecord::Base

  has_and_belongs_to_many :subscriptions, :class_name => 'Blog', :join_table => 'blog_subscribers'
  has_and_belongs_to_many :owned_blogs, :class_name => 'Blog', :join_table => 'blog_owners'

  @@friends = nil

  def self.find_or_make(name)
    # case insensitive, whoo hoo
    if name
      User.find(:first, :conditions => ["UPPER(tname) = ?", name.upcase]) || create(:tname => name)
    end
  end

  # is current user following this user?
  # arg is friends json 
  def following?(friends)
    friends.find { |f| f["screen_name"].casecmp(tname) == 0 }
  end

  # Do the blog-parsing task.  If we ever have more tasks, this should be moved elsewhere.
  def perform
    self.subscriptions.each do |blog| 
      begin
        blog.find_twitterers
      rescue Exception => whoops
        puts "Error on blog #{blog.title}: " + whoops
      end
    end
    # +++ sub name of host.
    # +++ page will have to deal with unauthenticated user.
    puts "Sending direct message to #{tname}"
    twitter_direct_message("Your blogs have been processed: http://twitlines.net/blogs")
  end

  # This works when TWITTER_USER is set to mtraven.
  # ApplicationController.do_twitter_request('http://twitter.com/direct_messages/new.json?text=foo&user=mtraven', :post, true)

  def twitter_direct_message(message)
    tparams = { :user => tname , :text => message}
    url = "http://twitter.com/direct_messages/new.json?#{tparams.to_query}"
    # should eventually be changed to _authenticated (mm, no, because that requires OAuth which the server isnt equipped to get)
    # OK, this works when done by hand, has problems from server, presumably because friendship is not set up?
    ApplicationController.do_twitter_request(url, :post, true)
  end

end
