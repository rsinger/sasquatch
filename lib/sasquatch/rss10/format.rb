module RDF::RSS10

  class Format < RDF::Format
    #content_type 'application/xml', :extension => :rss
    #content_type 'application/rdf+xml', :extension => :rss
    content_encoding 'utf-8'

    reader { RDF::RSS10::Reader }
    writer { RDF::RSS10::Writer }
  end
end

