class UsersController < ApplicationController

  def follow
    user_id = params[:id]
    twit = User.find(user_id)
    tparams = { :user_id => twit.tname }
    url = "http://twitter.com/friendships/create.json?#{tparams.to_query}"
    twitter_request_authenticated(url)
#    render something
    respond_to do |format|
      format.html { 
        render :partial => 'following', :locals => { :twit => twit, :dom_id => params[:dom_id] }
      }
    end
  end


end
