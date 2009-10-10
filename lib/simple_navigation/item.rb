module SimpleNavigation
  
  # Represents an item in your navigation. Gets generated by the item method in the config-file.
  class Item
    attr_reader :key, :name, :url, :sub_navigation, :method
    attr_writer :html_options
    
    # see ItemContainer#item
    def initialize(container, key, name, url, options, sub_nav_block) #:nodoc:
      @container = container
      @key = key
      @method = options.delete(:method)
      @name = name
      @url = url
      @html_options = options
      if sub_nav_block
        @sub_navigation = ItemContainer.new(@container.level + 1)
        sub_nav_block.call @sub_navigation
      end
    end
    
    # Returns true if this navigation item should be rendered as 'selected'.
    # An item is selected if
    #
    # * it has been explicitly selected in a controller or
    # * it has a subnavigation and one of its subnavigation items is selected or
    # * its url matches the url of the current request (auto highlighting)
    #
    def selected?
      @selected = @selected || selected_by_config? || selected_by_subnav? || selected_by_url?
    end
        
    # Returns the html-options hash for the item, i.e. the options specified for this item in the config-file.
    # It also adds the 'selected' class to the list of classes if necessary. 
    def html_options
      default_options = self.autogenerate_item_ids? ? {:id => key.to_s} : {}
      options = default_options.merge(@html_options)
      options[:class] = [@html_options[:class], self.selected_class].flatten.compact.join(' ')
      options.delete(:class) if options[:class].blank?
      options
    end

    # Returns the configured selected_class if the item is selected, nil otherwise
    #
    def selected_class
      selected? ? SimpleNavigation.config.selected_class : nil
    end

    protected

    # Returns true if item has a subnavigation and the sub_navigation is selected
    def selected_by_subnav?
      sub_navigation && sub_navigation.selected?
    end

    # Return true if item has explicitly selected in controllers
    def selected_by_config?
      key == @container.current_explicit_navigation
    end

    # Returns true if the item's url matches the request's current url.
    def selected_by_url?
      if auto_highlight?
        !!(root_path_match? || (SimpleNavigation.template && SimpleNavigation.template.current_page?(url)))
      else
        false
      end
    end

    # Returns true if both the item's url and the request's url are root_path
    def root_path_match?
      url == '/' && SimpleNavigation.controller.request.path == '/'
    end

    # Converts url to url_hash. Accesses routing system, quite slow... Not used at the moment
    # def hash_for_url(url) #:nodoc:
    #   ActionController::Routing::Routes.recognize_path(url, {:method => (method || :get)})
    # end

    def autogenerate_item_ids?
      SimpleNavigation.config.autogenerate_item_ids
    end

    def auto_highlight?
      SimpleNavigation.config.auto_highlight && @container.auto_highlight
    end

  end
end