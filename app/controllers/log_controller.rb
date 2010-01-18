class LogController < ApplicationController
  def view
    @entries = LogEntry.find(:all)
  end

end
