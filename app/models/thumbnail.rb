class Thumbnail
  @queue = :derivatives

  AUDIO_TYPES = ['mp3', 'wav', 'mp4']
  IMAGE_TYPES = ['jpg', 'tif', 'png']
  TEXT_TYPES = ['doc', 'docx', 'pdf']


  #Specific pages: http://stackoverflow.com/questions/2974442/convert-pdf-to-images-using-rmagick-ruby
  def self.perform(*args)
    args = args.first

    raise "Environment argument missing!" if args["environment"].blank?

    ActiveFedora.init(:environment=>args["environment"])
    config_hash = YAML.load_file(Rails.root.join('config', 'ark.yml'))[args["environment"]] #FIXME: Do this better
    raise "Ark config incorrect for environment: " + args["environment"] if config_hash.blank?

    url_list = []
    temp_url_list = ""
    temp_url_list = args["image_urls"] if args["image_urls"].present?

    temp_url_list.split('||').each do |url|
      url_list << url
    end

    img = nil
    @thumbnail_url = nil
    @object = ActiveFedora::Base.find(args["object_pid"]).adapt_to_cmodel

    if args["system_type"] == "omeka" && url_list.present?

      #For SAIL, the following url doesn't work in ImageMagick if URL not escaped...
      url_list.each do |url|

        url = url.gsub('[','%5B').gsub(']','%5D')

        if @thumbnail_url.blank? && !AUDIO_TYPES.include?(url.split('.').last) && !(url.include?('amazonaws') && url.downcase.include?('.mp3')) #http://moakleyarchive.omeka.net/items/show/377 is mp3
          if TEXT_TYPES.include?(url.split('.').last) || (url.include?('amazonaws') && (url.include?('.pdf') || url.include?('.doc') || url.include?('.docx')))

            if url.include?('.docx') || url.include?('.doc')
              command = 'soffice -convert-to pdf:writer_pdf_Export --outdir public/data/pdf --headless ' + url
              result = system(command)
              if result
                #FIXME: do more than .docx documents
                url = 'public/data/pdf/' + url.split('/').last.gsub('.docx', '.pdf')
              end
            end

            current_page = -1
            total_colors = 0

            until total_colors > 1 do
              current_page = current_page + 1

              if url.include?('amazonaws') #Can't do paging as signature is off then 0.o
                img = Magick::Image.read(url){
                  self.quality = 100
                  self.density = 200
                }.first
              else
                img = Magick::Image.read(url.gsub('.pdf', '.pdf[' + current_page.to_s + ']')){
                  self.quality = 100
                  self.density = 200
                }.first
              end

              total_colors = img.total_colors
            end

            @thumbnail_url = @object.generate_thumbnail_url(config_hash)
          else

            #Amazonaws requires a special token so unable to access thumbnails directly...
            if url.include?('/original/') & !url.include?('amazonaws')
              #Note: Second gsub removes the extension and then adds .jpg
              @thumbnail_url = url.gsub('/original/', '/square_thumbnails/').gsub(/\.\w+$/, '') + '.jpg'
              img =  Magick::Image.read(@thumbnail_url).first
            elsif url.include?('/files/') & !url.include?('amazonaws')
              #Note: Second gsub removes the extension and then adds .jpg
              @thumbnail_url = url.gsub('/files/', '/square_thumbnails/').gsub(/\.\w+$/, '') + '.jpg'
              img =  Magick::Image.read(@thumbnail_url).first
            else
              #@thumbnail_url = @object.generate_thumbnail_url
              #FIXME:
              @thumbnail_url = @object.generate_thumbnail_url(config_hash)
              img =  Magick::Image.read(url).first
            end
          end

          #This is horrible. But if you don't do this, some PDF files won't come out right at all.
          #Multiple attempts have failed to fix this but perhaps the bug will be patched in ImageMagick.
          #To duplicate, one can use the PDF files at: http://libspace.uml.edu/omeka/files/original/7ecb4dc9579b11e2b53ccc2040e58d36.pdf
          img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

          thumb = img.resize_to_fit(300,300)

          @object.thumbnail300.content = thumb.to_blob { self.format = "jpg" }
          @object.thumbnail300.mimeType = 'image/jpeg'
          @object.thumbnail300.dsLabel = url.split('/').last.gsub(/\....$/, '')

          @object.descMetadata.insert_location_url(@thumbnail_url, nil, 'preview')
          @object.add_relationship(:is_image_of, "info:fedora/" + @object.pid)
          @object.add_relationship(:is_exemplary_image_of, "info:fedora/" + @object.pid)
        end


      end

    elsif args["system_type"] == "generic" && url_list.present?

        max_retry = 2
        sleep_time = 60 # In seconds
        retry_count = 0

        current_page = 0
        total_colors = 0

        url = url_list.first

        img = nil

        if @thumbnail_url.blank? && !AUDIO_TYPES.include?(url.split('.').last)
          if TEXT_TYPES.include?(url.split('.').last)

            #Convert docx and doc to PDF
            if url.include?('.docx') || url.include?('.doc')
              command = 'soffice -convert-to pdf:writer_pdf_Export --outdir public/data/pdf --headless ' + url
              result = system(command)
              if result
                #FIXME: do more than .docx documents
                url = 'public/data/pdf/' + url.split('/').last.gsub('.docx', '.pdf')
              end
            end

            until total_colors > 1 do


              begin
                if retry_count > 0
                  sleep(sleep_time)
                end
                retry_count = retry_count + 1
                img = Magick::Image.read(url + '[' + current_page.to_s + ']'){
                  self.quality = 100
                  self.density = 200
                }.first
              rescue
                retry if retry_count <= max_retry
                #raise "Image Magick Error With URL: #{url}"       #No errors - just skip as some PDFs don't exist
                return false
              end

              total_colors = img.total_colors
              current_page = current_page + 1

            end

          else

            until total_colors > 1 do

              begin
                if retry_count > 0
                  sleep(sleep_time)
                end
                retry_count = retry_count + 1
                img =  Magick::Image.read(url).first
              rescue => error
                retry if retry_count <= max_retry
                #raise "Image Magick Error With URL: #{url} and message header #{$!}", $!.backtrace
                current_error = "Image Magick Error With URL: #{url}\n"
                current_error += "Error message: #{error.message}\n"
                current_error += "Error backtrace: #{error.backtrace}\n"

                #Resque.logger.error current_error

                raise current_error
              end

              total_colors = img.total_colors

              current_page = current_page + 1

              if current_page > url_list.size
                raise "Could not find a page that was not blank with url_list: #{url_list}"
              end

              url = url_list[current_page] unless total_colors > 1 #FIXME: Should be more consistent with the until condition....
            end

          end

          #Fix for transparency
          if img.matte
            img_list = Magick::ImageList.new
            img_list << img
            img_list.new_image(img_list.first.columns, img_list.first.rows) { self.background_color = "white" } # Create new "layer" with white background and size of original image
            img = img_list.reverse.flatten_images
            img = img.quantum_operator(Magick::MultiplyQuantumOperator, 0.3, Magick::AlphaChannel)
          end

          #This is horrible. But if you don't do this, some PDF files won't come out right at all.
          #Multiple attempts have failed to fix this but perhaps the bug will be patched in ImageMagick.
          #To duplicate, one can use the PDF files at: http://libspace.uml.edu/omeka/files/original/7ecb4dc9579b11e2b53ccc2040e58d36.pdf
          img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

          thumb = img.resize_to_fit(300,300)


          @object.thumbnail300.content = thumb.to_blob { self.format = "jpg" }
          @object.thumbnail300.mimeType = 'image/jpeg'
          @object.thumbnail300.dsLabel = url.split('/').last.gsub(/\....$/, '')

          #@thumbnail_url = args["thumbnail_url"].present? ? args["thumbnail_url"] : @object.generate_thumbnail_url #Generate the thumbnail url
          #FIXME: Temporary... no ARK Config...

          @thumbnail_url = args["thumbnail_url"].present? ? args["thumbnail_url"] : @object.generate_thumbnail_url(config_hash)
          @object.descMetadata.insert_location_url(@thumbnail_url, 'preview', nil)
          @object.add_relationship(:is_image_of, "info:fedora/" + @object.pid)
          @object.add_relationship(:is_exemplary_image_of, "info:fedora/" + @object.pid)



        end

    elsif args["system_type"] == "wgbh" && url_list.present?

      max_retry = 2
      sleep_time = 60 # In seconds
      retry_count = 0

      current_page = 0
      total_colors = 0

      url = url_list.first

      img = nil

      if @thumbnail_url.blank? && !AUDIO_TYPES.include?(url.split('.').last)

        response = ::Typhoeus::Request.get(
            url,
            method: :get,
            headers: {'Referer' => 'http://openvault.wgbh.org/' }
        )

        img =  Magick::Image.from_blob(response.body).first

        #Fix for transparency
        if img.matte
          img_list = Magick::ImageList.new
          img_list << img
          img_list.new_image(img_list.first.columns, img_list.first.rows) { self.background_color = "white" } # Create new "layer" with white background and size of original image
          img = img_list.reverse.flatten_images
          img = img.quantum_operator(Magick::MultiplyQuantumOperator, 0.3, Magick::AlphaChannel)
        end

        #This is horrible. But if you don't do this, some PDF files won't come out right at all.
        #Multiple attempts have failed to fix this but perhaps the bug will be patched in ImageMagick.
        #To duplicate, one can use the PDF files at: http://libspace.uml.edu/omeka/files/original/7ecb4dc9579b11e2b53ccc2040e58d36.pdf
        img = Magick::Image.from_blob( img.to_blob { self.format = "jpg" } ).first

        thumb = img.resize_to_fit(300,300)


        @object.thumbnail300.content = thumb.to_blob { self.format = "jpg" }
        @object.thumbnail300.mimeType = 'image/jpeg'
        @object.thumbnail300.dsLabel = url.split('/').last.gsub(/\....$/, '')

        #@thumbnail_url = args["thumbnail_url"].present? ? args["thumbnail_url"] : @object.generate_thumbnail_url #Generate the thumbnail url
        #FIXME: Temporary... no ARK Config...

        @thumbnail_url = args["thumbnail_url"].present? ? args["thumbnail_url"] : @object.generate_thumbnail_url(config_hash)
        @object.descMetadata.insert_location_url(@thumbnail_url, 'preview', nil)
        @object.add_relationship(:is_image_of, "info:fedora/" + @object.pid)
        @object.add_relationship(:is_exemplary_image_of, "info:fedora/" + @object.pid)



      end

  end

  if @object.workflowMetadata.item_status.processing != ["complete"]
    @object.workflowMetadata.item_status.processing = "complete"
    @object.workflowMetadata.item_status.processing_comment = "Object Processing Complete"
  end

  @object.save
  @object.save
  #Need to call it twice so that exemplary_image is populated as won't be in solr to be found.
  end
end