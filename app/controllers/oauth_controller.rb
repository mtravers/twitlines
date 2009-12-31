class OauthController < ApplicationController
  
  before_filter :make_client

  def make_client
    @user = session[:user]
    @client = TwitterOAuth::Client.new(
                                       :consumer_key => ENV['CONSUMER_KEY'] || 'ftYX5V6tCN7GF2yw0PRzw',
                                       :consumer_secret => ENV['CONSUMER_SECRET'] || 'svcTyQ8UrlG2awFqeaQHUPG1XHiQjcrmhVn0H8dDbyg',
                                       :token => session[:access_token],
                                       :secret => session[:secret_token]
                                       )
  end

  def connect
    request_token = @client.request_token(:oauth_callback => ENV['CALLBACK_URL'] || 'http://localhost:3000/oauth_callback')
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret
    redirect_to request_token.authorize_url.gsub('authorize', 'authenticate') 
  end

  def oauth_callback
    # Exchange the request token for an access token.
    begin
      @access_token = @client.authorize(
                                        session[:request_token],
                                        session[:request_token_secret],
                                        :oauth_verifier => params[:oauth_verifier]
                                        )
    rescue OAuth::Unauthorized
    end
    if @client.authorized?
      # Storing the access tokens so we don't have to go back to Twitter again
      # in this session.  In a larger app you would probably persist these details somewhere.
      session[:access_token] = @access_token.token
      session[:secret_token] = @access_token.secret
      session[:user] = true
      redirect_to '/twitline/twitline'
    else
      redirect_to '/'
    end
  end

end


