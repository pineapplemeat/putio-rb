require 'JSON'
require 'pp'
require 'curb'

module PutIo
  class Api
    attr_accessor :oauth_token, :base_url
    
    def initialize(oauth_token)
      @oauth_token = oauth_token
      @base_url = "https://api.put.io/v2"
    end

    
    def perform_post(url)
      reutrn perform(url, :method => :post)
    end

    def perform_request(url, options={})
      params = options[:params] || {}
      params[:oauth_token] ||= @oauth_token
      
      #puts url
      #pp params
      if options[:method] == :post
        puts "POST"
        result = Curl.post(url, params)
      else
        result = Curl.get(url, params)
      end
      
      begin
        json_result = JSON.parse(result.body_str)
      rescue JSON::ParserError => ex
        raise "Problem parsing JSON (usually happens due to invalid request): #{result.body_str}"
      end

      validate_response(json_result)
      return json_result
    end
    
    def validate_response(response)
      if response["status"] != "OK"
        raise "Error.  Response code not OK: #{response}"
      end
      return true
    end

    def files_list(parent_id=0)
      url = "#{@base_url}/files/list"
      params = {:parent_id => parent_id }
      data = perform_request(url, :method => :get, :params => params)
      return data["files"].map do |f| File.new(f) end
    end

    def files_convert_to_mp4(id)
      url = "#{base_url}/files/#{id}/mp4"
      data = perform_request(url, :method => :post)
    end

    def files_get_mp4_status(id)
      url = "#{base_url}/files/#{id}/mp4"
      data = perform_request(url, :method => :get)
    end

  end
  
  # Simple wrapper for File object
  class File
    @@object_attrs = [:content_type,
                      :crc32,
                      :created_at,
                      :first_accessed_at,
                      :icon,
                      :id,
                      :is_mp4_available,
                      :is_shared,
                      :name,
                      :opensubtitles_hash,
                      :parent_id,
                      :screenshot]
    attr_accessor *@@object_attrs
    
    def initialize(data)
      @@object_attrs.each do |attr|
        self.instance_variable_set("@#{attr}", data[attr.to_s])
      end
    end

    def is_directory?
      return self.content_type == "application/x-directory"
    end
    
    def is_video?
      return self.content_type.start_with?("video/")
    end

    def to_s
      "<File #{id} \"#{self.name}\"; #{self.content_type}>"
    end
  end
end

