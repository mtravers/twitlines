class TwitlinesController < ApplicationController

  before_filter :make_consumer

  def twitlines
    session[:iterm] = params[:iterm]
  end

  # JSON providers

  def default
    if session[:user]
      log_user
      render :json => twitter_home(params[:incremental])
    elsif session[:iterm]
      render :json => twitter_search(session[:iterm], nil)
    else
      render :json => twitter_public      
    end
  end

  def log_user
    if !session[:logged_user]
      uname = twitter_whoami
#      puts "Log user #{uname} at #{Time.now}"
      LogEntry.log(uname, 'logged in')
      session[:logged_user] = uname      
    end
  end

  def search
    render :json => twitter_search(params[:term], params[:incremental])
  end

  def public
    render :json => twitter_public
  end

  def twitter_search(term, incremental)
    count = 100
    params = { :q => term, :rpp => count}
    if incremental == "earlier"
      return { :events => [] }  # search API can't do this (should test)
    elsif incremental == "later"
      params[:since_id] = session[:high_id]
    else
      #      LogEntry.log(session[:logged_user], "search #{term}")
#      reset_range
    end
    url = "http://twitter.com/search.json?#{params.to_query}" 
    json = twitter_request(url)
    return { :events => json['results'].map { |evt| twitter_search_event(evt)}}
  end

  def twitter_public
    url = "http://twitter.com/statuses/public_timeline.json"
    json = twitter_request(url)
    return { :events => json.map { |evt| twitter_timeline_event(evt)}}
  end

  def reset_range
    session[:low_id] = session[:high_id] = nil
  end

  def twitter_home(incremental)
    params = { :count => 100 }
    if incremental == "earlier"
      params[:max_id] = session[:low_id]
    elsif incremental == "later"
      params[:since_id] = session[:high_id] unless session[:high_id] == nil
      params[:count] = 200
    else
      reset_range
    end
    url = "http://twitter.com/statuses/home_timeline.json?#{params.to_query}"
    json = twitter_request_authenticated(url)
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
    # I hope accessing session state is not expensive
    if session
      if session[:high_id] == nil || id > session[:high_id]
        session[:high_id] = id 
        session[:high_date] = Time.parse(time)
      end
      if session[:low_id] == nil || id < session[:low_id]
        session[:low_id] = id 
        session[:low_date] = Time.parse(time)
      end
    end
    { :title => timeline_entry_text(user,text), 
      :start => time, 
      :link => "http://twitter.com/#{user}/status/#{id}",
#      :icon => "http://twivatar.org/#{user}/mini"
# try alternate method     
      :icon => image.gsub('normal', 'mini')

    }
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
    # hashtags
    s = s.gsub(/#([A-Za-z0-9\-_]+)/, "\#<a onclick=\"newSearch(\'#\\1\')\">\\1</a>:")
  end

  def break_string(s)
    mid = s.length/2
    pos1 = s.index(' ', mid)
    pos2 = s.rindex(' ', mid)
    brk = nil
    if pos1 == nil
      brk = pos2
    elsif pos2 == nil
      brk = pos1
    elsif (pos1 - mid) < (mid - pos2)
      brk = pos1
    else
      brk = pos2
    end
    if brk
      return s[0,brk] + '<br/>' + s[brk+1, 200]
    else
      return s
    end
  end

end
