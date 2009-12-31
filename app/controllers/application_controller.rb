# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

    def make_client
      @user = session[:user]
#       @client = TwitterOAuth::Client.new(
#                                          :consumer_key => ENV['CONSUMER_KEY'] || 'ftYX5V6tCN7GF2yw0PRzw',
#                                          :consumer_secret => ENV['CONSUMER_SECRET'] || 'svcTyQ8UrlG2awFqeaQHUPG1XHiQjcrmhVn0H8dDbyg',
#                                          :token => session[:access_token],
#                                          :secret => session[:secret_token]
#                                          )
      @client = OAuth::Consumer.new(ENV['CONSUMER_KEY'] || 'ftYX5V6tCN7GF2yw0PRzw',
                                    ENV['CONSUMER_SECRET'] || 'svcTyQ8UrlG2awFqeaQHUPG1XHiQjcrmhVn0H8dDbyg',
                                    { :site=>"http://twitter.com"})

    end

    def get_access
      if session[:user]
        make_client
        @access_token = OAuth::AccessToken.new(@client, session[:access_token], session[:secret_token]) 
      end
    end

end
