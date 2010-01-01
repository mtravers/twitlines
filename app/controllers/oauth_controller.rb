class OauthController < ApplicationController
  
  before_filter :make_consumer

  def connect
    request_token = @consumer.get_request_token(:oauth_callback => ENV['CALLBACK_URL'] || 'http://localhost:3000/oauth_callback')
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect_to request_token.authorize_url.gsub('authorize', 'authenticate') 
  end

  def oauth_callback
    # Exchange the request token for an access token.
    begin
      @request_token = OAuth::RequestToken.new(@consumer,
                                               session[:request_token],
                                               session[:request_token_secret])
      @access_token = @request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
    rescue OAuth::Unauthorized
      redirect_to '/'
    end
    # Storing the access tokens so we don't have to go back to Twitter again
    # in this session.  In a larger app you would probably persist these details somewhere.
    session[:access_token] = @access_token.token
    session[:secret_token] = @access_token.secret
    session[:user] = true
    redirect_to ''
  end

end


