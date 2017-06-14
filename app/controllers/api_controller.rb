class ApiController < ActionController::Base

  def token(env)
    YAML.load_file(Rails.root.join('config', 'avi_api.yml'))[env]["api_token"]
  end

  def geo_tiff_create
    errors = ''
    return_status = 400

    expected_params = ["object_id", "image_id", "bbox", "token", "environment", "sha256hex", "geoTIFF"]
    expected_params.each do |key|
      if !params.keys.include? key
        errors += "Missing required key of: #{key.to_s}\n"
      end
    end

    begin
      ActiveFedora.init(:environment=>params["environment"])
    rescue
      errors += "Environment value is invalid. \n"
    end

    #Check token first... don't allow anything else if authentication isn't valid.
    if errors.blank? and params["token"] != token(params[:environment])
      errors += "Token is invalid. \n"
      return_status = 401
    end

    # Refactor needed... but check a few things first before touching the backend
    if errors.present?
      respond_to do |format|
        format.html { render text: errors, status: return_status }
      end
    else
      image_solr_response = []
      datastream = 'georectifiedMaster'

      begin
        image_solr_response = Bplmodels::Finder.getImageFiles(params["object_id"])
        if image_solr_response.blank?
          errors += "No Images Found for map object: #{params["object_id"]} \n"
        else
          existing_check = image_solr_response.select { |row| row["id"] == params["image_id"] }
          errors += "Passed Image ID of: #{params["image_id"]} not found related to Map Object #{params["object_id"]} \n" if existing_check.blank?
        end

      rescue
        errors += "Problem loading images for: #{params["object_id"]} \n"
      end

      begin
        file_content = params["geoTIFF"].read
        errors += "Likely a bad geo tiff sent... very little data sent. \n" if file_content.size < 100000
        errors += "SHA 256 hexdigest did not match the content received. \n" unless Digest::SHA256.hexdigest(file_content) == params['sha256hex']
      rescue
        errors += "Couldn't read the geo TIFF information... did you send the geo tiff data correctly? \n"
      end

      if errors.blank?
        begin
          obj = ActiveFedora::Base.find(params["object_id"]).adapt_to_cmodel
          image_obj = ActiveFedora::Base.find(params["image_id"]).adapt_to_cmodel

          image_obj.send(datastream).content = file_content
          image_obj.send(datastream).mimeType = 'image/tiff'
          #image_obj.send(datastream).dsLabel = params[:geoTIFF].original_filename.gsub(/\.(tif|TIF|jpg|JPG|jpeg|JPEG|jp2|JP2|png|PNG|txt|TXT)$/, '')
          image_obj.send(datastream).dsLabel = image_obj.productionMaster.dsLabel + "_geo"
          image_obj.save

          subject_count = obj.descMetadata.mods(0).subject.count
          subject_index = nil
          0.upto(subject_count - 1) do |index|
            if obj.descMetadata.mods(0).subject(index).cartographics(0).coordinates.present? &&
               obj.descMetadata.mods(0).subject(index).cartographics(0).coordinates[0] =~ /[-]*[\d\.]+ [-]*[\d\.]+ [-]*[\d\.]+ [-]*[\d\.]+/
              subject_index = index
              break
            end
          end
          if subject_index
            obj.descMetadata.mods(0).subject(subject_index).cartographics(0).coordinates(0, params["bbox"])
          else
            obj.descMetadata.mods(0).subject(subject_count).cartographics(0).coordinates = params["bbox"]
          end

          obj.save
        rescue => error
          errors += "Problem saving the image or coordinates. \n"
          errors += "Error message: #{error.message}\n"
          errors += "Error backtrace: #{error.backtrace}\n"
        end
      end

      if errors.present?
        respond_to do |format|
          format.html { render text: errors, status: 400 }
        end
      else
        respond_to do |format|
          format.html { render text: "Successfully added GeoTIFF for #{params["object_id"]}" }
        end
      end
    end

  end


end