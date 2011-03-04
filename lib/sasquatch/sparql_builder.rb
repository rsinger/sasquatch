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
      @variables = vars
      self
    end
    def describe!(graph=:default)
      describe
      execute(graph)
    end
    
    def describe
      @form = :describe
      @values = *@variables.flatten.map { |var|
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
      @values = @variables.flatten.map { |var| [var, RDF::Query::Variable.new(var)] }
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
      options[:template] = build_patterns(*@variables)
      self
    end
    
    def execute(graph)
      @store.send(:"sparql_#{@form}", self.to_s, graph)
    end
    
    ##
    # Returns the string representation of this query.
    #
    # @return [String]
    def to_s
      buffer = [form.to_s.upcase]
      case form
        when :select, :describe
          buffer << 'DISTINCT' if options[:distinct]
          buffer << 'REDUCED' if options[:reduced]
          buffer << (values.empty? ? '*' : values.map { |v| serialize_value(v[1]) }.join(' '))
        when :construct
          buffer << '{'
          buffer += serialize_patterns(options[:template])
          buffer << '}'
      end

      buffer << "FROM #{serialize_value(options[:from])}" if options[:from]

      unless (patterns.empty? && (options[:optionals].nil? || options[:optionals].empty?)) && form == :describe
        buffer << 'WHERE {'
        buffer += serialize_patterns(patterns)
        if options[:optionals]
          options[:optionals].each do |patterns|
            buffer << 'OPTIONAL {'
            buffer += serialize_patterns(patterns)
            buffer << '}'
          end
        end
        if options[:filters]
          buffer += options[:filters].map { |filter| "FILTER(#{filter})" }
        end
        buffer << '}'
      end

      if options[:order_by]
        buffer << 'ORDER BY'
        buffer += options[:order_by].map { |var| var.is_a?(String) ? var : "?#{var}" }
      end

      buffer << "OFFSET #{options[:offset]}" if options[:offset]
      buffer << "LIMIT #{options[:limit]}" if options[:limit]
      options[:prefixes].reverse.each {|e| buffer.unshift("PREFIX #{e}") } if options[:prefixes]

      buffer.join(' ')
    end    
  end
end
