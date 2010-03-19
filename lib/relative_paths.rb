# A webby filter for turning absolute paths (paths that start with a slash "/") 
# into relative paths ("../").
#
# Should be used as a filter for Layouts.
#
# Created by: M@ McCray (http://mattmccray.com)
 
require 'hpricot'
 
 
# Patch Webby's Renderer class so we can have access to the target page 
# (so filtering on layouts will work right...)
class Webby::Renderer
  attr_accessor :page
end
 
class Webby::Resources::Page
  def url
    return @url unless @url.nil?
    @url = super
 
    # Uncomment this to return to default behavior of
    # only referencing the parent folder for index pages...
    #@url = File.dirname(@url) if filename == 'index'
 
    @url
  end
end
 
# Used Webby::Filters::BasePath as an example...
class RelativePaths
 
  # call-seq:
  #    RelativePaths.new( html, mode, page )
  #
  # Creates a new RelativePaths filter that will operate on the given _html_
  # string. The _mode_ is either 'xml' or 'html' and determines how Hpricot
  # will handle the parsing of the input string.
  #
  def initialize( str, mode, page )
    @str = str
    @mode = (mode || 'html').downcase.to_sym
    @page = page
  end
 
  # call-seq:
  #    filter    => html
  #
  # Process the original html document passed to the filter when it was
  # created. The document will be scanned and the basepath for certain
  # elements will be modified.
  #
  # For example, if a document contains the following line:
  # 
  #    <a href="/link/to/another/page.html">Page</a>
  #
  # And the document is located at /my/other/dir/file.txt, the result of 
  # the filter would be:
  #
  #     <a href="../../../link/to/another/page.html">Page</a>
  #
  def filter
    doc = @mode == :xml ? Hpricot.XML(@str) : Hpricot(@str)
    attr_rgxp = %r/\[@(\w+)\]$/o
    path_to_root = ""
    path_parts = @page.destination.split('/') - SITE.output_dir.split('/')
    (path_parts.length - 1).times { path_to_root += "../" }
    Webby.site.xpaths.each do |xpath|
      @attr_name = nil
      doc.search(xpath).each do |element|
        @attr_name ||= attr_rgxp.match(xpath)[1]
        a = element.get_attribute(@attr_name)
        if a[0..0] == '/' # Only 'fix' absolute URIs
          new_uri = path_to_root + a[1..-1]
         # puts "Updating URI: #{a}"
         # puts "          to: #{new_uri}"
          element.set_attribute(@attr_name, new_uri)
        end
      end
    end
 
    doc.to_html
  end
 
end  # class RelativePaths
 
 
# Rewrite base URIs in the input HTML text.
#
Webby::Filters.register :relativepaths do |input, cursor|
  page = cursor.page.is_a?(Webby::Resources::Page) ? cursor.page : cursor.renderer.page
  RelativePaths.new(input, cursor.page.extension, page).filter
end
 
# EOF