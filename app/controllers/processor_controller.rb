class ProcessorController < ApplicationController
  skip_before_action :verify_authenticity_token

  #http://localhost:3000/processor/bypid?pid=bpl-test:4q77fr754
  def bypid
    is_new = false
    if params[:new].present? && params[:new] == "true"
      is_new = true
    end
    result = Resque.enqueue(Derivatives, :file_pid=>params[:pid], :is_new=>is_new, :environment=>params[:environment])

    respond_to do |format|
      if result
        format.json { render json: {"result" => true}.as_json, status: :created }
      else
        format.json { render json: {"result" => false}.as_json, status: :unprocessable_entity }
      end
    end

    #Resque.enqueue(Derivatives, :object_pid=>'steventest:22')
  end

  def byobject
    is_new = false

    is_new = true if params[:new].present? && params[:new] == "true"

    result = Resque.enqueue(Derivatives, :object_pid=>params[:pid], :is_new=>is_new, :environment=>params[:environment])

    respond_to do |format|
      if result
        format.json { render json: {"result" => true}.as_json, status: :created }
      else
        format.json { render json: {"result" => false}.as_json, status: :unprocessable_entity }
      end
    end

    #Resque.enqueue(Derivatives, :object_pid=>'steventest:22')
  end

  def oaithumbnail
    is_new = false
    thumbnail_url = nil

    is_new = true if params[:new].present? && params[:new] == "true"
    thumbnail_url = params[:thumbnail_url] if params[:thumbnail_url].present?

    result = Resque.enqueue(OaiThumbnail, :object_pid=>params[:pid], :is_new=>is_new, :environment=>params[:environment], :system_type=>params[:system_type], :image_urls=>params[:image_urls], :thumbnail_url=>thumbnail_url)

    respond_to do |format|
      if result
        format.json { render json: {"result" => true}.as_json, status: :created }
      else
        format.json { render json: {"result" => false}.as_json, status: :unprocessable_entity }
      end
    end
  end

  def bycollection
  end

  def byinstitution
  end

  def byfile
    is_new = false

    is_new = true if params[:new].present? && params[:new] == "true"

    result = Resque.enqueue(Derivatives, :file_pid=>params[:pid], :is_new=>is_new, :environment=>params[:environment])

    respond_to do |format|
      if result
        format.json { render json: {"result" => true}.as_json, status: :created }
      else
        format.json { render json: {"result" => false}.as_json, status: :unprocessable_entity }
      end
    end
  end
end
