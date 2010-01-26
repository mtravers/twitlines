require 'xml/libxml'

class BlogController < ApplicationController
  
  def load
  end

  def view
  end

  def list
    @blogs = Blog.find(:all)
  end

  def read_opml_file(file)
    xml = XML::Document.file(file)    
    opmls = xml.find('//outline')
    blogs = []
    opmls.map do |o| 
      title = o['text']
      feed = o['xmlUrl']
      homepage = o['htmlUrl']
      if feed && homepage
        b = Blog.find_by_feed(feed)
        if b
          blogs.push(b)
        else
          b = Blog.new(:title => title, :homepage => homepage, :feed => feed)
          blogs.push(b)
        end
      end
    end
    blogs
  end

end
