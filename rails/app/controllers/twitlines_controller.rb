class TwitlinesController < ApplicationController

  def home
    
  end

  def search
  end

  def public
    render :json => { :events => twitter_call.map { |evt| twitter_timeline_event(evt)}}
  end

  #basic_auth(acct, pwd)

  def twitter_call
#    params = {:db => :pubmed, :retmode => "xml", :tool => :collabrx, :email => "support@collabrx.com"  }.merge(params)
    url = "http://twitter.com/statuses/public_timeline.json"
    resp = Net::HTTP.get(URI.parse(url))
    json = JSON.parse(resp)
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
