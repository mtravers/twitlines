class UserController < ApplicationController

  def follow
    tparams = { :user_id => params[:id] }
    url = "http://twitter.com/friendships/create.json?#{tparams.to_query}"
    twitter_request_authenticated(url)
#    render something
  end


end
