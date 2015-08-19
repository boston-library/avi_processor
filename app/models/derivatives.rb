class Derivatives
  @queue = :derivatives

  def self.perform(*args)
    args = args.first

    raise "Environment argument missing!" if args["environment"].blank?

    #FIXME: What happens with multiple jobs?
    #https://github.com/projecthydra/active_fedora/blob/9aab861ef0918fe93ca5bd8dcfcf4da818aab505/lib/active_fedora/file_configurator.rb
    #https://github.com/projecthydra/active_fedora/blob/9aab861ef0918fe93ca5bd8dcfcf4da818aab505/lib/active_fedora.rb
    #https://github.com/projecthydra/active_fedora/blob/9aab861ef0918fe93ca5bd8dcfcf4da818aab505/lib/active_fedora/rubydora_connection.rb
    #All objects have ".fedora_connection
    #config = AviProcessor::ActiveFedoraConfigurator.new()
    #config.init({:environment=>args[:environment]})

    ActiveFedora.init(:environment=>args["environment"])


    if args.has_key?("file_pid")
      file_object = Bplmodels::File.find(args["file_pid"]).adapt_to_cmodel
      file_object.characterize if args[:is_new] == "true" || args[:is_new] == true
=begin
      if file_object.accessMaster.present? && file_object.accessMaster.versions.length >= 1
        file_object.accessMaster.delete
        file_object.save
      end
=end
      file_object.generate_derivatives
      file_object.save
    elsif args.has_key?("object_pid")
      Bplmodels::File.find_in_batches('is_file_of_ssim'=>"info:fedora/#{args["object_pid"]}") do |group|
        group.each { |image_id|
          file_object = Bplmodels::File.find(image_id['id']).adapt_to_cmodel
          file_object.characterize #if args[:is_new] == "true"
          file_object.generate_derivatives
          file_object.save
        }
      end

      #if args[:is_new] == "true"
      object = Bplmodels::ObjectBase.find(args["object_pid"]).adapt_to_cmodel
      if object.workflowMetadata.item_status.processing != ["complete"]
        object.workflowMetadata.item_status.processing = "complete"
        object.workflowMetadata.item_status.processing_comment = "Object Processing Complete"
        object.save
      end

      #end

    elsif args.has_key?("collection_pid")
    elsif args.has_key?("institution_pid")
    end
  end
end