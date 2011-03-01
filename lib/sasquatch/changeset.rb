module RDF
  module Talis
    class Changeset < RDF::Vocabulary('http://purl.org/vocab/changeset/schema#')
      property :removal
      property :addition
      property :creatorName
      property :createdDate
      property :subjectOfChange
      property :changeReason
      property :ChangeSet
      property :precedingChangeSet
    end

    class Bigfoot < RDF::Vocabulary('http://schemas.talis.com/2006/bigfoot/configuration#')
      property :jobType
      property :ResetDataJob
      property :startTime
      property :JobRequest
    end

    class TalisDir < RDF::Vocabulary('http://schemas.talis.com/2005/dir/schema#')
      property :etag
    end
  end
end

module Sasquatch
  class Changeset
    attr_reader :resource, :statements, :subject_of_change
    def initialize(subject_of_change, resource=nil)
      @resource = RDF::Node.new unless resource
      @subject_of_change = subject_of_change
      @statements = []
      @statements.concat [RDF::Statement.new(@resource, RDF.type, RDF::Talis::Changeset.ChangeSet),
       RDF::Statement.new(@resource, RDF::Talis::Changeset.changeReason, "Generated in Platform Party"),
       RDF::Statement.new(@resource, RDF::Talis::Changeset.createdDate, Time.now),
       RDF::Statement.new(@resource, RDF::Talis::Changeset.subjectOfChange, subject_of_change)]
    end
    
    def remove_statements(stmts)
      stmts = [stmts] if stmts.is_a?(RDF::Statement)
      stmts.each do |stmt|
        raise ArgumentError unless stmt.subject == @subject_of_change        
        @statements.concat changeset_statement(stmt, :removal)
      end
    end
    
    def add_statements(stmts)
      stmts = [stmts] if stmts.is_a?(RDF::Statement)
      stmts.each do |stmt|
        next unless stmt
        raise ArgumentError unless stmt.subject == @subject_of_change        
        @statements.concat changeset_statement(stmt, :addition)
      end
    end
        
    def changeset_statement(stmt, action)
      s = RDF::Node.new
      [RDF::Statement.new(@resource, RDF::Talis::Changeset.send(action), s),
        RDF::Statement.new(s, RDF.type, RDF.to_rdf+"Statement"),
        RDF::Statement.new(s, RDF.subject, stmt.subject),
        RDF::Statement.new(s, RDF.predicate, stmt.predicate),
        RDF::Statement.new(s, RDF.object, stmt.object)]
    end      
  end
end