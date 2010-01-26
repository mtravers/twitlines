class User < ActiveRecord::Base

  has_and_belongs_to_many :blogs

  def self.find_or_make(name)
    find_by_tname(name) || create(:tname => name)
  end

end
