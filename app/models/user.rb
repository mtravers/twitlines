class User < ActiveRecord::Base

  has_and_belongs_to_many :subscriptions, :class_name => 'Blog', :join_table => 'blog_subscribers'
  has_and_belongs_to_many :owned_blogs, :class_name => 'Blog', :join_table => 'blog_owners'

  @@friends = nil

  def self.find_or_make(name)
    # case insensitive, whoo hoo
    User.find(:first, :conditions => ["UPPER(tname) = ?", name.upcase]) || create(:tname => name)
  end

  # is current user following this user?
  # arg is friends json 
  def following?(friends)
    friends.find { |f| f["screen_name"].casecmp(tname) == 0 }
  end

  # Do the blog-parsing task.  If we ever have more tasks, this should be moved elsewhere.
  def perform
    self.subscriptions.each { |blog| blog.find_twitterers }
    # +++ sub name of host.
    # +++ page will have to deal with unauthenticated usr.
    twitter_direct_message("Your blogs have been processed at http://twitline.net/blog/list")
  end

  # WHOOOPS -- this needs to dm as someone...ie, the system itself.  We need a twitter ID and the means to authenticate to it!

  def twitter_direct_message(message)
    tparams = { :user => tname , :text => message}
    url = "http://twitter.com/direct_messages/new.json?#{tparams.to_query}"
    # should eventually be changed to _authenticated
    # this is supposed to be a stopgap (and its not working)
    ApplicationController.do_twitter_request(url, :post, true)
  end

end
