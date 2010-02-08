class User < ActiveRecord::Base

  has_and_belongs_to_many :subscriptions, :class_name => 'Blog', :join_table => 'blog_subscribers'
  has_and_belongs_to_many :owned_blogs, :class_name => 'Blog', :join_table => 'blog_owners'

  @@friends = nil

  def self.find_or_make(name)
    # case insensitive, whoo hoo
    User.find(:all, :conditions => ["UPPER(tname) = ?", name.upcase]) || create(:tname => name)
  end

  # is current user following this user?
  # arg is friends json 
  def following?(friends)
    friends.find { |f| f["screen_name"].casecmp(tname) == 0 }
  end

end
