module Sasquatch
  class Store
    include HTTParty
    
    attr_reader :store_name, :last_response, :sparql_clients
    def initialize(storename, options={})
      self.class.base_uri "http://api.talis.com/stores/#{storename}"
      @store_name = storename
      if options[:username]
        set_credentials(options[:username], options[:password])
      end

    end
    
    def set_credentials(username, password)
      @auth = {:username => username, :password => password}
      @auth[:headers] = self.get("/snapshots", {}).headers['www-authenticate']
    end
    
    def describe(uri)
      options = {:query=>{:about=>uri, :output=>"ntriples"}}
      @last_response = get("/meta", options)
      graph = parse_ntriples(@last_response.body)
      graph.set_requested_resource(uri)
      graph
    end
    
    def describe_multi(uris)
      sparql = "DESCRIBE "
      uris.each {|uri| sparql << "<#{uri}> "}
      options = {:query=>{:query=>sparql, :output=>"ntriples"}}
      @last_response = get("/services/sparql", options)
      graph = parse_ntriples(@last_response.body)
      graph      
    end
    
    def get(path, options)
      self.class.get(path, options)      
    end
    
    def post(path, options)
      self.class.post(path, options)
    end
    
    def save(graph_statement_or_resource, graph_name=nil)
      path = "/meta"
      path << "/graphs/#{graph_name}" if graph_name
      options = {:headers=>{"Content-Type"=> "text/turtle"}, :body=>graph_statement_or_resource.to_ntriples, :digest_auth=>@auth}
      @last_response = post(path, options )      
      if @last_response.response.code == "204"
        true
      else
        false
      end
    end
    
    def search(query, options={})
      path = "/items"
      opts = {:query=>options}
      opts[:query][:query] = query
      @last_response = get(path, opts)
      graph = parse_rss10(@last_response.body)
      SearchResult.new_from_query(graph, opts, self)
    end
    
    def remove_triple(stmt, versioned=false)
      remove_triples([stmt], versioned)
    end
    
    def remove_triples(stmts, versioned=false)
      changesets = {}
      stmts.each do |stmt|
        changesets[stmt.subject] ||= Changeset.new(stmt.subject)
        changesets[stmt.subject].remove_statements(stmt)
      end
      graph = RDF::Graph.new
      changesets.each_pair do |uri, changeset|
        changeset.statements.each do |stmt|
          graph << stmt
        end
      end
      send_changeset(graph, versioned)   
    end
    
    def replace_triple(old_stmt, new_stmt, versioned=false)
      replace_triples({old_triple=>new_triple}, versioned)
    end

    ##
    # takes a Hash in form of {old_statement=>replacement_statement}
    #
    def replace_triples(changes, versioned=false)
      changesets = {}
      changes.each_pair do |old_stmt, new_stmt|
        changesets[old_stmt.subject] ||= Changeset.new(old_stmt.subject)
        changesets[old_stmt.subject].remove_statements(*old_stmt)
        changesets[new_stmt.subject] ||= Changeset.new(new_stmt.subject)
        changesets[new_stmt.subject].remove_statements(*new_stmt)        
      end
      graph = RDF::Graph.new
      changesets.each_pair do |uri, changeset|
        changeset.statements.each do |stmt|
          graph << stmt
        end
      end
      send_changeset(graph, versioned)   
    end 
    
    def replace(graph_statements_or_resource, versioned=false)
      uris = case graph_statements_or_resource.class.name
      when "RDF::Graph"
        subjects = []
        graph_statements_or_resource.each_subject {|s| subjects << s}
        subjects
      when "Array"
        subjects = []
        graph_statements_or_resource.each_subject {|s| subjects << s}
        subjects.uniq
      else
        # This should only work for rdf-rdfobjects Resources
        if graph_statements_or_resource.respond_to?(:predicates)
          [graph_statements_or_resource.to_s]
        end
      end
      raise ArgumentError unless uris
      current_graph = describe_multi(uris)
      changesets = {}
      current_graph.each_statement.each do |stmt|
        changesets[stmt.subject] ||= Changeset.new(stmt.subject)
        changesets[stmt.subject].remove_statements(stmt)
      end
      replacements = case graph_statements_or_resource.class.name
      when "Array" then graph_statements_or_resource
      else
        graph_statements_or_resource.statements
      end
      replacements.each do |stmt|
        changesets[stmt.subject] ||= Changeset.new(stmt.subject)
        changesets[stmt.subject].add_statements(stmt)        
      end
      graph = RDF::Graph.new
      changesets.each do |uri, changeset|
        changeset.statements.each do |stmt|
          graph << stmt
        end
      end
      send_changeset(graph, versioned)
    end
    
    def send_changeset(graph, versioned=false)
      path = "/meta"
      path << "/meta/changesets" if versioned
      options = {:headers=>{"Content-Type"=> "application/vnd.talis.changeset+turtle"}, :body=>graph.to_ntriples, :digest_auth=>@auth}
      @last_response = post(path, options )      
      if !versioned && @last_response.response.code == "204"      
        true
      elsif versioned && @last_response.response.code == "201"
        true
      else
        false
      end      
    end
    
    def delete_uri(uri, versioned=false)
      delete_uris([uri],versioned)
    end
    
    def delete_uris(uris, versioned=false)
      current_graph = describe_multi(uris)
      changesets = []
      uris.each do |uri|
        u = RDF::URI.intern(uri)
        cs = Changeset.new(u)
        cs.remove_statements(current_graph.query(:subject=>u))
        changesets << cs
      end
      graph = RDF::Graph.new
      changesets.each do |changeset|
        changeset.statements.each do |stmt|
          graph << stmt
        end
      end
      send_changeset(graph, versioned)
    end
    
    def sparql(*variables)
      SparqlBuilder.init(self,variables) 
    end
    
    def sparql_describe(query, graph=:default)
      path = "/services/sparql"
      unless graph == :default
        path << "/graphs/#{graph}"
      end
      options = {:query=>{:query=>query, :output=>'ntriples'}}
      @last_response = get(path, options)
      graph = parse_ntriples(@last_response.body)
      graph      
    end
    
    alias :sparql_construct :sparql_describe 
    
    def sparql_select(query, graph=:default)
      path = "/services/sparql"
      unless graph == :default
        path << "/graphs/#{graph}"
      end
      options = {:query=>{:query=>query, :output=>'json'}}
      @last_response = get(path, options)
      SPARQL::Client.parse_json_bindings(@last_response.body) || false
    end
    
    alias :sparql_ask :sparql_select

    
    def parse_ntriples(body)
      read_graph(body, :ntriples)
    end
    
    def parse_rss10(body)      
      read_graph(body, :rss10)
    end
    
    def read_graph(data, format)
      graph = RDF::Graph.new
      RDF::Reader.for(format).new(data) do |reader|
        reader.each_statement do |statement|
          graph << statement
        end
      end
      graph      
    end
    
    # Parse the response body however you like
    class Parser::Simple < HTTParty::Parser
      def parse
        body
      end
    end

    parser Parser::Simple    
  end  
end