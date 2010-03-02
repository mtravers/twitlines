class CreateBlogs < ActiveRecord::Migration
  def self.up
    create_table :blogs do |t|
      t.string :title
      t.string :feed
      t.string :homepage
      t.string :status

      t.timestamps
    end
  end

  def self.down
    drop_table :blogs
  end
end
