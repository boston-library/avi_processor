module AviProcessor
  class ActiveFedoraConfigurator < ActiveFedora::FileConfigurator
    def init options = {}
      if options.is_a?(String)
        raise ArgumentError, "Calling ActiveFedora.init with a path as an argument has been removed.  Use ActiveFedora.init(:fedora_config_path=>#{options})"
      end
      reset!
      @config_options = options
      @config_env = options[:environment]
      load_configs
    end

    def load_configs
      return if config_loaded?
      @config_env = ActiveFedora.environment unless @config_env.present?

      load_fedora_config
      load_solr_config
      @config_loaded = true
    end
  end
end