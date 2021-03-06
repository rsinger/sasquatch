require 'httparty'
require 'cgi'
require 'rdf'
require 'rdf/ntriples'
require 'rdf/json'
require 'sparql/client'
require 'json'
module Sasquatch
  require File.dirname(__FILE__) + '/sasquatch/http_party'
  require File.dirname(__FILE__) + '/sasquatch/store'
  require File.dirname(__FILE__) + '/sasquatch/rdf'    
  require File.dirname(__FILE__) + '/sasquatch/changeset'      
  require File.dirname(__FILE__) + '/sasquatch/rss10'  
  require File.dirname(__FILE__) + '/sasquatch/search_result'   
  require File.dirname(__FILE__) + '/sasquatch/sparql_builder'         
end