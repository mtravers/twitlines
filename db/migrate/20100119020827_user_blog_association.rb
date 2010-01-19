class UserBlogAssociation < ActiveRecord::Migration
  def self.up
    create_table :blogs_users, :id => false do |t|
      t.column :blog_id, :integer
      t.column :user_id, :integer
    end

  end

  def self.down
    drop_table :blogs_users
  end
end
