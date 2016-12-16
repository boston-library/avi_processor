module Blacklight::Solr
  class SearchBuilder < Blacklight::SearchBuilder
    #include Blacklight::Solr::SearchBuilderBehavior
    #No longer in blacklight... but hydra 8.1.0 complains without it in production...
  end
end