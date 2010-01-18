class LogEntry < ActiveRecord::Base

  def self.log(user, event)
    e = LogEntry.new(:user => user, :event => event)
    e.save
  end

end
