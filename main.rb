#!/usr/bin/env ruby
require './putio.rb'

KEY = ARGV[0]

def list_files_recursive(api, start_id=0)
  all_files = []
  work_queue = []
  work_queue += api.files_list(start_id)
  
  while !work_queue.empty?
    current_file = work_queue.shift
    next if !current_file.is_directory?
    
    subfiles = api.files_list(current_file.id)
    all_files += subfiles
    work_queue += subfiles
  end
  return all_files
end

api = PutIo::Api.new(KEY)

start_id = 0
list_files_recursive(api, start_id).each do |x| 
  puts [x, x.is_video?, x.is_mp4_available].join(' ')
  if x.is_video?
    puts api.files_download_mp4(x.id)
    #pp api.files_get_mp4_status(x.id)
    
    if !x.is_mp4_available && api.files_get_mp4_status(x.id)["mp4"]["status"] != "IN_QUEUE"
      puts "requesting convert of #{x.id}"
      pp api.files_convert_to_mp4(x.id)
    else
      #puts "not requesting convert of #{x.id}"
    end
    
    
  end
end





