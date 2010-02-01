class UsersController < ApplicationController

  def follow
    user_id = params[:id]
    twit = User.find(user_id)
    tparams = { :screen_name => twit.tname }
    url = "http://twitter.com/friendships/create.json?#{tparams.to_query}"
    resp = twitter_request_authenticated(url, :post)
    p resp
    LogEntry.log(session[:logged_user], "followed #{twit.tname}")
    render :partial => 'following', :locals => { :twit => twit, :dom_id => params[:dom_id] }
  end

  def unfollow
    user_id = params[:id]
    twit = User.find(user_id)
    tparams = { :screen_name => twit.tname }
    url = "http://twitter.com/friendships/destroy.json?#{tparams.to_query}"
    twitter_request_authenticated(url, :post)
    LogEntry.log(session[:logged_user], "unfollowed #{twit.tname}")
    render :partial => 'nfollowing', :locals => { :twit => twit, :dom_id => params[:dom_id] }
  end


end
