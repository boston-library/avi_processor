class CacheInvalidate
  @queue = :cache_invalidate

  def self.perform(*args)
    args = args.first


    if args.has_key?("file_pid")
      #file = ident_from_pid(args["file_pid"])
      #File.delete(file) if File.exist?file


    elsif args.has_key?("object_pid")
      Bplmodels::File.find_in_batches('is_file_of_ssim'=>"info:fedora/#{args["object_pid"]}") do |group|
        group.each { |image_id|
          #file = ident_from_pid(image_id['id'])
          #File.delete(file) if File.exist?file
          dir = ident_from_pid(image_id['id'])
          FileUtils.rm_rf(dir) if File.directory?(dir)
        }
      end
    elsif args.has_key?("collection_pid")
    elsif args.has_key?("institution_pid")
    end
  end

  def self.ident_from_pid(pid)
    if !pid.include?(':')
      pid = CGI::unescape(pid)
    end

    ident_hash = Digest::MD5.hexdigest(CGI::escape(pid))

    directory = '/home/avi/mapped/loris/jp2/' + pid.split(':').first + '/'
    directory = directory + ident_hash[0..1] + '/'
    [2,5,8,11,14,17,20,23,26,29].each do |index|
      directory = directory + ident_hash[index..index+2] + '/'
    end

    #directory = directory + 'loris_cache.jp2'

    return directory
  end
end