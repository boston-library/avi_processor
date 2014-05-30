class ImageProcessorController < ApplicationController
  #http://localhost:3000/image_processor/bypid?pid=bpl-test:4q77fr754
  def bypid
    @object = Bplmodels::File.find(params[:pid]).adapt_to_cmodel

    Hydra::Derivatives.ffmpeg_path = '/home/bluewolf/tools/ffmpeg/ffmpeg'
    Hydra::Derivatives.fits_path = '/home/bluewolf/tools/fits/fits.sh'
    Hydra::Derivatives.libreoffice_path = '/usr/lib/libreoffice/program/soffice'
    Hydra::Derivatives.kdu_compress_path = '/home/bluewolf/tools/KDU74/kdu_compress'

    @object.generate_derivatives

    puts @object.label

    respond_to do |format|
      format.json { render json: nil, status: :created }
      format.html
    end

  end

  def bycollection
  end

  def byfile
  end
end
