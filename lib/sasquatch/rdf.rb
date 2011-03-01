module RDF
  class Statement
    def to_ntriples
      RDF::Writer.for(:ntriples).buffer do |writer|
        writer << self          
      end      
    end
  end
  
  class Graph
    attr_reader :requested_resource
    def to_ntriples
      RDF::Writer.for(:ntriples).buffer do |writer|
        self.statements.each do |statement|
          writer << statement
        end
      end      
    end    
    def set_requested_resource(uri)
      @requested_resource = uri
    end
    
    def requested_resource
      if self.respond_to?(:"[]") # in case rdf-rdfobjects is available
        self[@requested_resource]
      else
        RDF::URI.intern(@requested_resource)
      end
    end
  end    
end