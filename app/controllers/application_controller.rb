# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def make_consumer
    @user = session[:user]
    @consumer = OAuth::Consumer.new(ENV['CONSUMER_KEY'] || 'ftYX5V6tCN7GF2yw0PRzw',
                                    ENV['CONSUMER_SECRET'] || 'svcTyQ8UrlG2awFqeaQHUPG1XHiQjcrmhVn0H8dDbyg',
                                    { :site=>"http://twitter.com"})

  end

  def get_access
    if session[:user]
      make_consumer
      @access_token = OAuth::AccessToken.new(@consumer, session[:access_token], session[:secret_token]) 
    end
  end

  # Twitter machinery -- doesn't really belong here...need to make a lib or something (or use Twitter gem like a good little rubyist)

  # you have to do some rigamrole to set the user-agent, apparently.
  # this is only for unauthenticated requests
  def twitter_request(url)
    purl = URI.parse(url)
    res = Net::HTTP.start(purl.host, purl.port) { |http| http.get(url, {"User-Agent" => "twitlines"}) }
    if res.code_type == Net::HTTPOK
      JSON.parse(res.body)
    else
      throw "Error from Twitter: " + res.message + " url was: " + url
    end
  end

  # returns JSON
  # +++ error handling
  def twitter_request_authenticated(url)
    get_access
    response = @access_token.get(url, {"User-Agent" => "twitlines"})
    JSON.parse(response.body)
  end


end
