module ActiveAdmin
  class MenuItem


    # Generates a route using the rails application url helpers
    #
    # @param [Symbol] named_route
    #
    # @returns [String] The generated route
    def self.generate_url(named_route)
      Rails.application.routes.url_helpers.send(named_route)
    end

    attr_accessor :name, :url, :priority, :parent, :display_if_block

    def initialize(name, url, priority = 10, options = {})
      @name, @url, @priority = name, url, priority
      @children = []
      @cached_url = {} # Stores the cached url in a hash to allow us to change it and still cache it

      @display_if_block = options.delete(:if)

      yield(self) if block_given? # Builder style syntax
    end

    def human_name
      I18n.translate!(@name, :scope => [:admin, :menu])
    rescue I18n::MissingTranslationData
      @name.pluralize.titleize
    end

    def add(name, url, priority=10, options = {}, &block)
      item = MenuItem.new(name, url, priority, options, &block)
      item.parent = self
      @children << item
    end

    def children
      @children.sort
    end

    def parent?
      !parent.nil?
    end

    def dom_id
      name.downcase.gsub( " ", '_' ).gsub( /[^a-z0-9_]/, '' )
    end

    # new version support scoped routes
    def url
      case @url
      when Symbol
        generated = self.class.generate_url(@url) # Call the named route
      else
        generated = @url
      end
      @cached_url["#{@url}_#{I18n.locale}"] ||= generated
    end

    # Returns an array of the ancestory of this menu item
    # The first item is the immediate parent fo the item
    def ancestors
      return [] unless parent?
      [parent, parent.ancestors].flatten
    end

    # Returns the child item with the name passed in
    #    @blog_menu["Create New"] => <#MenuItem @name="Create New" >
    def [](name)
      @children.find{ |i| i.name == name }
    end

    def <=>(other)
      result = priority <=> other.priority
      result = name <=> other.name if result == 0
      result
    end

    # Returns the display if block. If the block was not explicitly defined
    # a default block always returning true will be returned.
    def display_if_block
      @display_if_block || lambda { |_| true }
    end


  end
end
