class LogEntry < ActiveRecord::Base

  def self.log(user, event)
    e = LogEntry.new(:user => user, :event => event)
    puts "Log: #{user}: #{event}"
    e.save
  end

end
