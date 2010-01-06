class TwitlinesController < ApplicationController

  before_filter :make_consumer

  # JSON providers

  def default
    if session[:user]
      render :json => twitter_home(params[:low], params[:high])
    else
      render :json => twitter_public      
    end
  end

  def search
    render :json => twitter_search(params[:term])
  end

  def public
    render :json => twitter_public
  end

  def twitter_search(term)
    count = 100
    params = { :q => term, :rpp => count}
    url = "http://twitter.com/search.json?#{params.to_query}" 
    resp = twitter_request(url)
    json = JSON.parse(resp)
    return { :events => json['results'].map { |evt| twitter_search_event(evt)}}
  end

  def twitter_public
    url = "http://twitter.com/statuses/public_timeline.json"
    resp = twitter_request(url)
    json = JSON.parse(resp)
    return { :events => json.map { |evt| twitter_timeline_event(evt)}}
  end

  def reset_range
    session[:low_date] = session[:high_date] = nil
    session[:low_id] = session[:high_id] = nil
  end

  def twitter_home(low, high)
    get_access
    params = { "count" => 100 }
    if low == nil
      reset_range
    else
      puts "TwitMe: " + low + high
      low = Time.parse(low)
      high = Time.parse(high)
      if low < session[:low_date]
        params[:max_id] = session[:low_id]
      elsif high > session[:high_date]
        params[:since_id] = session[:high_id]
      else
        return { :events => []}
      end
    end
    url = "http://twitter.com/statuses/home_timeline.json?#{params.to_query}" 
    puts = "TwitUrl: " + url
    response = @access_token.get(url, {"User-Agent" => "twitlines"})
    json = JSON.parse(response.body) # +++ should do an error check
    return { :events => json.map { |evt| twitter_timeline_event(evt)}}
  end

  # you have to do some rigamrole to set the user-agent, apparently.
  # this is only for unauthenticated requests
  def twitter_request(url)
    purl = URI.parse(url)
    res = Net::HTTP.start(purl.host, purl.port) { |http| http.get(url, {"User-Agent" => "twitlines"}) }
    if res.code_type == Net::HTTPOK
      res.body      
    else
      throw "Error from Twitter: " + res.message
    end
  end

  def twitter_search_event(evt)
    timeline_entry(evt['from_user'],
                   evt['text'],
                   evt['created_at'],
                   evt['id'],
                   evt['profile_image_url'])
  end

  def twitter_timeline_event(evt)
    timeline_entry(evt['user']['screen_name'],
                   evt['text'],
                   evt['created_at'],
                   evt['id'],
                   evt['user']['profile_image_url'])
  end

  def timeline_entry(user, text, time, id, image)
    # I hope accessing session state is not expensive
    if session[:high_id] == nil || id > session[:high_id]
      session[:high_id] = id 
      session[:high_date] = Time.parse(time)
    end
    if session[:low_id] == nil || id < session[:low_id]
      session[:low_id] = id 
      session[:low_date] = Time.parse(time)
    end
    { :title => timeline_entry_text(user,text), 
      :start => time, 
      :link => "http://twitter.com/#{user}/status/#{id}",
      :icon => "http://twivatar.org/#{user}/mini"}
  end
  
  def timeline_entry_text(user, text)
    s = break_string("#{user}: #{text}")
    s = linkify_string(s)
  end

  def linkify_string(s)
    # This is a hairy URL matcher
    s = s.gsub(/\b(([\w-]+:\/\/?|www[.])[^\s()<>]+(?:\([\w\d]+\)|([^[:punct:]\s]|\/)))/, "<a href='\\1' target='_blank'>\\1</a>")
    s = s.gsub(/@([A-Za-z0-9\-_]+)/, "@<a href='http://twitter.com/\\1' target='_blank'>\\1</a>")
    s = s.gsub(/\A([A-Za-z0-9\-_]+):/, "<a href='http://twitter.com/\\1' target='_blank'>\\1</a>:")
  end

  def break_string(s)
    pos = s.index(' ', s.length/2)
    if pos == nil
      return s
    else
      return s[0,pos] + '<br/>' + s[pos+1, 200]
    end
  end

end
