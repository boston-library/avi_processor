class ApiController < ActionController::Base

  def token
    @pw ||= YAML.load_file(Rails.root.join('config', 'avi_api.yml'))[Rails.env]["api_token"]
  end

  def geo_tiff_create
    errors = ''
    image_solr_response = []
    datastream = 'geoEncodedMaster'

    expected_params = [:object_id, :image_id, :bbox, :token, :environment]
    expected_params.each do |key|
      if !params.keys.include? key
        errors += "Missing required key of: #{key.to_s}\n"
      end
    end

    if params[:token] != token
      errors += "Token is invalid. \n"
    end

    begin
      ActiveFedora.init(:environment=>params[:environment])
    rescue
      errors += "Environment value is invalid. \n"
    end

    begin
      image_solr_response = Bplmodels::Finder.getImageFiles(params[:object_id]).first["id"]
      errors += "No Map Object Found for: #{params[:object_id]} \n" if image_solr_response.blank?
    rescue
      errors += "Problem loading images for: #{params[:object_id]} \n"
    end

    begin
      errors += "Likely a bad geo tiff sent... very little data sent. \n" if request.body.read.size < 100000
    rescue
      errors += "Couldn't read the request body... did you send the geo tiff data correctly? \n"
    end



    if errors.blank?
      obj = ActiveFedora::Base.find(params[:object_id]).adapt_to_cmodel
      image_obj = ActiveFedora::Base.find(image_solr_response[0]["id"]).adapt_to_cmodel

      image_obj.send(datastream).content = request.body.read
      image_obj.save

      subject_index = obj.descMetadata.mods(0).subject.count
      0.upto subject_index-1 do |pos|
        if obj.descMetadata.mods(0).subject(pos).geographic.blank? and obj.descMetadata.mods(0).subject(pos).authority.blank? and obj.descMetadata.mods(0).subject(pos).cartographics(0).coordinates.present?
          subject_index = pos
          break
        end
      end

      obj.descMetadata.mods(0).subject(subject_index).cartographics(0).coordinates = params[:bbox]
      obj.save
    end

    if errors.present?
      respond_to do |format|
        format.status = :unauthorized
        format.html { render text: errors }

      end
    else
      respond_to do |format|
        format.html { render text: "Successfully added GeoTIFF for #{params[:object_id]}" }

      end
    end

  end


end