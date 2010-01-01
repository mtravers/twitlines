class TwitlinesController < ApplicationController

  before_filter :make_consumer

  def default
    if session[:user]
      render :json => twitter_home
    else
      render :json => twitter_public      
    end
  end

  def home
    
  end

  def search
    render :json => twitter_search(params[:term])
  end

  def public
    render :json => twitter_public
  end


  #basic_auth(acct, pwd)

  def twitter_search(term)
    count = 100
    params = { :q => term, :rpp => count}
    url = "http://search.twitter.com/search.json?#{params.to_query}" 
    resp = Net::HTTP.get(URI.parse(url))
    json = JSON.parse(resp)
    return { :events => json['results'].map { |evt| twitter_search_event(evt)}}
  end

  def twitter_public
#    params = {:db => :pubmed, :retmode => "xml", :tool => :collabrx, :email => "support@collabrx.com"  }.merge(params)
    url = "http://twitter.com/statuses/public_timeline.json"
    resp = Net::HTTP.get(URI.parse(url))
    json = JSON.parse(resp)
    return { :events => json.map { |evt| twitter_timeline_event(evt)}}
  end

  def twitter_home
    get_access
    params = { "count" => 100 }
    url = "http://twitter.com/statuses/home_timeline.json?#{params.to_query}" 
    response = @access_token.get(url)
    json = JSON.parse(response.body) # +++ should do an error check
    return { :events => json.map { |evt| twitter_timeline_event(evt)}}
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
    s = s.gsub(/(http:\/\/\S+)/, "<a href='\\1' target='_blank'>\\1</a>")
    # other subs
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
