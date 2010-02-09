# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def current_user
    if !session[:logged_user]
      session[:logged_user] = twitter_whoami
    end
    User.find_by_tname(session[:logged_user]) # probably wrong, also in efficient
  end

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def make_consumer
    @user = session[:user]
    @consumer = OAuth::Consumer.new(ENV['CONSUMER_KEY'],
                                    ENV['CONSUMER_SECRET'],
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
  # this is for unauthenticated requests or requests from the application using basic auth.

  def twitter_request(url, method=:get, auth=false)
    self.twitter_request(url, method, auth)
  end

  def self.twitter_request(url, method=:get, auth=false)
    purl = URI.parse(url)
    res = Net::HTTP.start(purl.host, purl.port) { |http|
      req = method == :post ?
      Net::HTTP::Post.new(url, {"User-Agent" => "twitlines"}) :
      Net::HTTP::Get.new(url, {"User-Agent" => "twitlines"})
      if auth 
        req.basic_auth(ENV['TWITTER_ACCOUNT'], ENV['TWITTER_PASSWORD']) 
      end
      http.request(req)
    }
    # simpler, but it just wraps Net::HTTP and you can't specify the agent.
    #    res = HTTParty.get(url)
    if res.code_type == Net::HTTPOK
      JSON.parse(res.body)
    else
      throw "Error from Twitter: " + res.message + " url was: " + url
    end
  end

  # returns JSON
  # +++ error handling
  def twitter_request_authenticated(url, method = :get)
    get_access
    if method == :post
      response = @access_token.post(url, '', {"User-Agent" => "twitlines"})
    else
      response = @access_token.get(url, {"User-Agent" => "twitlines"})
    end
    JSON.parse(response.body)
  end

  def twitter_request_as_server(url)
  end

  # flaking out every now and then
  def twitter_whoami_old
    json = twitter_request_authenticated('http://twitter.com/statuses/user_timeline.json?count=1')
    json[0]['user']['name']
  end

  # better
  def twitter_whoami
    begin
      json = twitter_request_authenticated('http://twitter.com/account/verify_credentials.json')
      json['screen_name']
    rescue Exception => e
      # fails inexplicably; let's not get hung up since this is just for informational purposes
      puts e.to_s
    end
  end


end
