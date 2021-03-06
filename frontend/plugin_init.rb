Rails.application.config.after_initialize do
 
 ActionView::PartialRenderer.class_eval do
    alias_method :render_location, :render
    def render(context, options, block)
      result = render_location(context, options, block);

      # Add our location-specific templates to shared/templates
      if options[:partial] == "shared/templates"
        result += render(context, options.merge(:partial => "search/search_templates"), nil)
      end

      result
    end
  end
 
  SearchResultData.class_eval do
    self.singleton_class.send(:alias_method, :BASE_FACETS_pre_component_report, :BASE_FACETS)
    def self.BASE_FACETS
      self.BASE_FACETS_pre_component_report.unshift("level","resource_identifier_w_title_u_sstr")
    end
  end

  ApplicationController.class_eval do
    include SearchHelper
    def add_custom_columns_to_results_listing
      add_column("Date(s)",
                proc {|record|
                  result = ""
                  
                  if ASUtils.json_parse(record['json'])['dates']
                    date = ASUtils.json_parse(record['json'])['dates'].first
                  elsif ASUtils.json_parse(record['json'])['dates_of_existence']
                    date = ASUtils.json_parse(record['json'])['dates_of_existence'].first
                  else
                    date = ""
                  end
                  
                  unless date.nil? || date.empty?
                    if date['expression']
                      result = date['expression']
                    elsif date['end'].nil? || date['end'] == date['begin']
                      result = date['begin']
                    else
                      result = "#{date['begin']} - #{date['end']}"
                    end
                  end
                  
                  result
                })
      add_column(I18n.t("search_results.filter.resource_identifier_w_title_u_sstr"),
                proc {|record|
                  result = ""

                  if record.has_key?('resource_identifier_u_sstr')
                    result = ASUtils.wrap(record['resource_identifier_u_sstr']).first
                    result += ": #{ASUtils.wrap(record['resource_title_u_sstr']).first}" if record['resource_title_u_sstr']
                  end

                  result
                },
                {
                  :sortable => true,
                  :sort_by => 'resource_identifier_u_sort'
                })
    end
  end


  SearchController.class_eval do
    alias_method :advanced_search_pre_component_levels, :advanced_search
    def advanced_search
      @component_levels_level_column_supported = true
      advanced_search_pre_component_levels
    end

    alias_method :do_search_pre_component_levels, :do_search
    def do_search
      @component_levels_level_column_supported = true
      do_search_pre_component_levels
    end

    private

    # We need to add the column in render to be sure
    # the column is added post initialising @search_data
    # and prior to rendering the template.
    def render(*args)
      add_custom_columns_to_results_listing if @component_levels_level_column_supported && show_custom_columns?
      super
    end


    def show_custom_columns?
      (ASUtils.wrap(@search_data.types).empty? ||
        @search_data.types.include?("resource") || @search_data.types.include?("archival_object")) &&
      (!@search_data.filtered_terms? ||
        @search_data[:criteria]["filter_term[]"].none?{|filter| filter =~ /primary_type/ } ||
        @search_data[:criteria]["filter_term[]"].any?{|filter| filter =~ /primary_type/ && (filter =~ /archival_object/ || filter =~ /resource/) })
    end
  end


  ResourcesController.class_eval do
    alias_method :index_pre_component_levels, :index
    def index
      index_pre_component_levels
      add_custom_columns_to_results_listing
    end
  end
end