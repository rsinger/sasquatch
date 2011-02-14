module Sasquatch
  class SparqlBuilder < SPARQL::Client::Query
    attr_reader :store, :variables
    
    def self.init(store, *variables)
      options = variables.last.is_a?(Hash) ? variables.pop : {}
      self.new(store, options).set_variables(*variables)
    end
    def initialize(store, options={}, &block)
      @store = store

      super(:sparql, options, &block)
    end
    
    def sparql
      @form = "CHANGEME"
      self
    end
    
    def set_variables(*vars)
      @variables = vars.flatten
      self
    end
    def describe!(graph=:default)
      describe
      execute(graph)
    end
    
    def describe
      @form = :describe
      @values = @variables.map { |var|
        [var, var.is_a?(RDF::URI) ? var : RDF::Query::Variable.new(var)]
      }      
      self
    end
    
    def select!(graph=:default)
      select
      execute(graph)
    end
    
    def select
      @form = :select
      @values = @variables.map { |var| [var, RDF::Query::Variable.new(var)] }
      self
    end
    
    def ask!(graph=:default)      
      ask
      execute(graph)
    end    
    
    def ask
      @form = :ask
      self
    end
    
    def construct!(graph=:default)
      construct
      execute(graph)
    end
    
    def construct
      @form = :construct
      options[:template] = build_patterns(@variables)
      self
    end
    
    def execute(graph)
      @store.send(:"sparql_#{@form}", self.to_s, graph)
    end
  end
end
