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
    def describe
      @form = :describe
      @values = @variables.map { |var|
        [var, var.is_a?(RDF::URI) ? var : RDF::Query::Variable.new(var)]
      }
      execute
    end
    
    def select
      @form = :select
      @values = @variables.map { |var| [var, RDF::Query::Variable.new(var)] }
      execute
    end
    def execute
      @store.get("/services/sparql", {:query=>{:query=>self}})
    end
  end
end
