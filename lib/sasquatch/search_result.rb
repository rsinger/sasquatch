module Sasquatch
  class SearchResult < Array
    attr_reader :graph, :total_results, :max_results, :start_index, :search_context
    
    def initialize
      @results = []
    end
    
    def self.new_from_query(graph, options, store)
      search_result = self.new
      search_result.graph = graph
      search_result.search_context={:store=>store, :options=>options}
      search_result.parse_graph
      search_result
    end
    
    def graph=(g)
      @graph = g
    end
    
    def search_context=(sc)
      @search_context=sc
    end
    
    def parse_graph
      return unless @graph
      @graph.query(:predicate=>RDF::URI.intern("http://a9.com/-/spec/opensearch/1.1/totalResults")).each do |stmt|
        @total_results = stmt.object.value.to_i
      end
      @total_result ||= 0
      @graph.query(:predicate=>RDF::URI.intern("http://a9.com/-/spec/opensearch/1.1/startIndex")).each do |stmt|
        @start_index = stmt.object.value.to_i
      end
      @start_index ||= 0 
      @graph.query(:predicate=>RDF::URI.intern("http://a9.com/-/spec/opensearch/1.1/itemsPerPage")).each do |stmt|
        @max_results = stmt.object.value.to_i
      end
      @max_results ||= 0    
      
      set_results       
    end
    
    def set_results
      channel_uri = nil
      @graph.query(:predicate=>RDF.type, :object=>RDF::RSS.channel).each do |channel|
        channel_uri = channel.subject
      end
      return unless channel_uri
      seq_uri = nil
      @graph.query(:subject=>channel_uri, :predicate=>RDF::RSS.items).each do |items|
        seq_uri = items.object
      end
      return unless seq_uri
      @graph.query(:subject=>seq_uri, :predicate=>RDF.li).each do |li|
        self << li.object
      end
    end
    
    def previous
      if @start_index == 0
        nil
      else
        o = {}
        o[:offset] = @start_index - @max_results
        o[:offset] = 0 if o[:offset] < 0
        o[:sort] = @search_context[:options][:sort]
        o[:max] = @max_results
        @search_context[:store].search(@search_context[:options][:query][:query],o)
      end
    end
    def next
      if (@start_index + self.count) >= @total_results
        nil
      else
        o = {}
        o[:offset] = @start_index + @max_results
        o[:sort] = @search_context[:options][:sort]
        o[:max] = @max_results
        @search_context[:store].search(@search_context[:options][:query][:query],o)
      end
    end    
  end
end