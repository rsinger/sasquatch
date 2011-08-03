
module RDF
  module RSS10
     require File.dirname(__FILE__) + '/rss10/format'
     require File.dirname(__FILE__) + '/rss10/reader'     
     require File.dirname(__FILE__) + '/rss10/writer' 
    # require 'rdf/n3/vocab'
    # require 'rdf/n3/patches/array_hacks'
    # require 'rdf/n3/patches/graph_properties'
    # autoload :Meta, 'rdf/n3/reader/meta'
    # autoload :Parser, 'rdf/n3/reader/parser'
    # autoload :Reader, 'rdf/n3/reader'
    # autoload :VERSION, 'rdf/n3/version'
    # autoload :Writer, 'rdf/n3/writer'
    # 
    # def self.debug?; @debug; end
    # def self.debug=(value); @debug = value; end
  end
end