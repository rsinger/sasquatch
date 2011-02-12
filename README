Sasquatch - A DSL for the Talis Platform
==============================

Sasquatch makes it easy to add/delete/replace resources and triples on the Talis Platform using RDF.rb.

Example:

  store = Sasquatch::Store.new(storename, {:username=>u, :password=>p}) # authentication is optional
  
  resource = store.describe("http://example.org/1")
  => #<RDF::Graph:0x81467e78(<>)>
  
  resources = store.describe_multi(['http://example.org/1', 'http://example.org/2'])
  => #<RDF::Graph:0x8100fd58(<>)>

  store.delete_uri('http://example.org/1')
  
  => true
  
  store.delete_uris(['http://example.org/2', 'http://example.org/3'])
  
  => true
  
  Because ChangeSets are somewhat cumbersome, there are methods to replace triples or resources wholesale:
  
  store.replace(resources) # where 'resources' is an RDF::Graph, array of RDF::Statements or RDF::RDFObjects::Resource
  
  This will replace all of the subjects with what is sent.  Pass a boolean true to make it a versioned changeset.
  
  There is also:
  
  store.replace_triple(old_triple, new_triple)
  
  where old_triple and new_triple are RDF::Statements
  
  and
  
  store.replace_triples
  
  which takes a Hash where the keys are the old triples and the values are the new triples.
  
  search = store.search("italy")
  => [#<RDF::URI:0x80f92484(http://id.loc.gov/authorities/sh89006665#concept)>, #<RDF::URI:0x80f90df0(http://lcsubjects.org/subjects/sh89006665#concept)>, #<RDF::URI:0x80f9042c(http://id.loc.gov/authorities/sh2004008861#concept)>, #<RDF::URI:0x80f8f5e0(http://id.loc.gov/authorities/sh2006002475#concept)>, #<RDF::URI:0x80f8e974(http://id.loc.gov/authorities/sh86005484#concept)>, #<RDF::URI:0x80f8d31c(http://lcsubjects.org/subjects/sh2004008861#concept)>, #<RDF::URI:0x80f8c548(http://lcsubjects.org/subjects/sh2006002475#concept)>, #<RDF::URI:0x80f8b29c(http://lcsubjects.org/subjects/sh86005484#concept)>, #<RDF::URI:0x80f8a48c(http://id.loc.gov/authorities/sh85069035#concept)>, #<RDF::URI:0x80f88f38(http://lcsubjects.org/subjects/sh85069035#concept)>]
  
  #search returns a Sasquatch::SearchResult, which is sort of a glorified array.
  
  To get the next page of search results, use SearchResult#next, to get the previous, use SearchResult#previous
  
  You can access the search result graph at SearchResult#graph
  
  Because it is really an array of URIs, you can chain it into other Store methods:
  
  store.delete_uris(store.search('italy'))
  
  => true
  
  etc.