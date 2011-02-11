module RDF::RSS10
  class Reader < RDF::Reader
    require 'nokogiri'
    # copied indiscriminately from gkellogg's rdf/xml parser

    def initialize(input = $stdin, options = {}, &block)
      super do
        
        @base_uri = uri(options[:base_uri]) if options[:base_uri]
            
        @doc = case input
        when Nokogiri::XML::Document then input
        else Nokogiri::XML.parse(input, @base_uri.to_s)
        end
        
        raise RDF::ReaderError, "Synax errors:\n#{@doc.errors}" if !@doc.errors.empty? && validate?
        raise RDF::ReaderError, "Empty document" if (@doc.nil? || @doc.root.nil?) && validate?

        block.call(self) if block_given?
      end
    end    
    ##
     # Iterates the given block for each RDF statement in the input.
     #
     # @yield [statement]
     # @yieldparam [RDF::Statement] statement
     # @return [void]
     def each_statement(&block)
       # Block called from add_statement
       @callback = block

       root = @doc.root


       rdf_nodes = root.xpath("/rdf:RDF", "rdf" => RDF.to_uri.to_s)
       statements = []
       rdf_nodes.each do |node|


         root.xpath("//rss:channel", "rss"=>RDF::RSS.to_s).each do |channel|
           if channel.attribute('about')
             channel_uri = RDF::URI.intern(channel.attribute('about').value)
           else
             channel_uri = RDF::Node.new
           end
           statements << RDF::Statement.new(channel_uri, RDF.type, RDF::RSS.channel)
           channel.children.each do |elem|
             unless elem.name == 'items'
               if elem.children.length == 1 && elem.children.first.is_a?(Nokogiri::XML::Text)
                 statements << RDF::Statement.new(channel_uri, RDF::URI.intern(elem.namespace.href + elem.name), literal(elem.children.first))
               elsif elem.attribute('resource')
                 statements << RDF::Statement.new(channel_uri, RDF::URI.intern(elem.namespace.href + elem.name), RDF::URI.intern(elem.attribute('resource').value))
               end
             else
               stmt = RDF::Statement.new(:subject=>channel_uri, :predicate=>RDF::URI.intern(elem.namespace.href + elem.name))
               elem.children.each do |list|
                 if list.attribute('about')
                   list_uri = RDF::URI.intern(list.attribute('about').value)
                 else
                   list_uri = RDF::Node.new
                 end

                 stmt.object = list_uri
                 statements << stmt
                 list_type = RDF::URI.intern(list.namespace.href + list.name)
                 unless list_type == RDF.Description
                   statements << RDF::Statement.new(:subject=>list_uri, :predicate=>RDF.type, :object=>list_type)
                 end
                 list.children.each do |li|
                   stmt = RDF::Statement.new(:subject=>list_uri, :predicate=>RDF::URI.intern(li.namespace.href + li.name))
                   if li.attribute('resource')
                     stmt.object = RDF::URI.intern(li.attribute('resource').value)
                   elsif li.children.length == 1 && li.children.first.is_a?(Nokogiri::XML::Text)
                     stmt.object = literal(li.children.first)
                   end
                   statements << stmt if stmt.object
                 end
               end
             end
           end
         end
         root.xpath("/rdf:RDF/rss:item", "rdf"=>RDF.to_uri.to_s, "rss"=>RDF::RSS.to_s).each do |item|
           if item.attribute('about')
             item_uri = RDF::URI.intern(item.attribute('about').value)
           else
             item_uri = RDF::Node.new
           end
           statements.concat statements_from_element(item, item_uri)
         end


       end
       statements.each do |stmt |
         yield stmt
       end   
       statements.to_enum    
     end
     
     def statements_from_element(elem, resource)
       child_elements = {}
       statements = []
       elem.children.each do |el|
         if el.attribute_with_ns('resource', RDF.to_uri.to_s)
           statements << RDF::Statement.new(:subject=>resource, :predicate=>RDF::URI.intern(el.namespace.href+el.name), :object=>RDF::URI.intern(el.attribute_with_ns('resource', RDF.to_uri.to_s).value))
         elsif all_text_nodes?(el.children)
           statements << RDF::Statement.new(:subject=>resource, :predicate=>RDF::URI.intern(el.namespace.href+el.name),:object=>literal(el.children.first))
         else
           el.children.each do |e|
             if e.attribute_with_ns('about', RDF.to_uri.to_s)
               c = RDF::URI.intern(e.attribute_with_ns('about', RDF.to_uri.to_s).value)
               statements << RDF::Statement.new(:subject=>resource, :predicate=>RDF::URI.intern(el.namespace.href+el.name), :object=>c)  
               child_elements[c] = e
               e_type = RDF::URI.intern(e.namespace.href + e.name)
               unless e_type == RDF.Description || RDF::RSS.item
                 statements << RDF::Statement.new(:subject=>c, :predicate=>RDF.type, :object=>e_type)
               end
             elsif has_child_elements?(e)   
               c = RDF::Node.new         
               statements << RDF::Statement.new(:subject=>resource, :predicate=>RDF::URI.intern(el.namespace.href+el.name), :object=>c)  
               child_elements[c] = e
               e_type = RDF::URI.intern(e.namespace.href + e.name)
               unless e_type == RDF.Description || RDF::RSS.item
                 statements << RDF::Statement.new(:subject=>c, :predicate=>RDF.type, :object=>e_type)
               end
             end               
           end
         end
       end
       child_elements.each_pair do |r,e|
         statements.concat statements_from_element(e, r)
       end
       statements
     end
     
     def all_text_nodes?(nodes)
       all_text = true
       nodes.each {|n| all_text = false unless n.is_a?(Nokogiri::XML::Text)}
       all_text
     end
     
     def has_child_elements?(elem)
       children = false
       elem.each {|e| children = true if e.is_a?(Nokogiri::XML::Element)}
       children
     end
     
     def literal(txt)
       if txt.attribute('lang')
         options[:language] = txt.attribute('lang').value.to_sym
       end
       if txt.attribute_with_ns('datatype', RDF.to_uri.to_s)
         options[:datatype] = RDF::URI.intern(txt.attribute_with_ns('datatype', RDF.to_uri.to_s).value)
       end
       RDF::Literal.new(txt.inner_text, options)       
     end
     
     def parse_children(elem, stmt)
       old_stmt = nil
       statements = []
       if elem.attribute_with_ns("about", RDF.to_uri.to_s)
         old_stmt = stmt
         stmt = RDF::Statement.new(:subject=>elem.attribute_with_ns("about", RDF.to_uri.to_s).value)
         type_object = RDF::URI.intern(elem.namespace.href+elem.name)
         unless type_object == RDF.Description || type_object == RDF::RSS.item
           stmt.predicate = RDF.type
           stmt.object = type_object
           statements << stmt
           stmt = RDF::Statement.new
           stmt.subject = RDF::URI.intern(elem.attribute_with_ns('about', RDF.to_uri.to_s).value)
         end
       end         
       elem.children.each do |el|
         next if el.is_a?(Nokogiri::XML::Text)
         if el.attribute_with_ns('resource', RDF.to_uri.to_s) || el.attribute('resource')
           if el.attribute_with_ns('resource', RDF.to_uri.to_s)
             stmt.object = RDF::URI.intern(el.attribute_with_ns('resource', RDF.to_uri.to_s).value)
           else
             stmt.object = RDF::URI.intern(el.attribute('resource').value)
           end
           stmt.predicate = RDF::URI.intern(el.namespace.href+el.name)
           statements << stmt.dup
           stmt = RDF::Statement.new(:subject=>stmt.subject)
         elsif el.children.length == 1 && el.children.first.is_a?(Nokogiri::XML::Text)
           stmt.predicate = RDF::URI.intern(el.namespace.href+el.name)
           options = {}
           txt = el.children.first
           if txt.attribute('lang')
             options[:language] = txt.attribute('lang').value.to_sym
           end
           if txt.attribute_with_ns('datatype', RDF.to_uri.to_s)
             options[:datatype] = RDF::URI.intern(txt.attribute_with_ns('datatype', RDF.to_uri.to_s).value)
           end
           stmt.object = RDF::Literal.new(txt.inner_text, options)
           statements << stmt.dup
           stmt = RDF::Statement.new(:subject=>stmt.subject)
         else
           stmt_found = false
           el.children.each do |child|
             next unless child.is_a?(Nokogiri::XML::Element)
             stmt.predicate = RDF::URI.intern(el.namespace.href+el.name)
             if child.attribute_with_ns("about", RDF.to_uri.to_s)
               stmt.object = RDF::URI.intern(child.attribute_with_ns("about", RDF.to_uri.to_s).value)
               statements << stmt.dup
               stmt = RDF::Statement.new(:subject=>stmt.subject)
               stmt_found = true
             else
               stmt.object = RDF::Node.new
               statements << stmt.dup
               stmt = RDF::Statement.new(:subject=>stmt.subject)
               stmt_found = true
             end               
           end
           puts "#{el.name}: #{el.inspect}" unless stmt_found
         end
             
         #puts "#{el.name}: #{el.class.name}"
         statements.concat parse_children(el, stmt) unless el.children.empty?
       end
       if old_stmt
         stmt = old_stmt
       end
       statements
     end
   end
 end
