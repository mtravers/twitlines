class DualBlogUserAssociation < ActiveRecord::Migration
  def self.up
    drop_table :blogs_users

    create_table :blog_subscribers, :id => false do |t|
      t.column :blog_id, :integer
      t.column :user_id, :integer
    end

    create_table :blog_owners, :id => false do |t|
      t.column :blog_id, :integer
      t.column :user_id, :integer
    end

  end

  def self.down
    drop_table :blog_owners
    drop_table :blog_subscribers
    
    create_table :blogs_users, :id => false do |t|
      t.column :blog_id, :integer
      t.column :user_id, :integer
    end
    
  end
end
