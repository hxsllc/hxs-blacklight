ActiveSupport.on_load :action_controller do
  module BlacklightAdvancedSearch
    class QueryParser
      include AdvancedHelper

      def keyword_op
        # for guided search add the operations if there are queries to join
        # NOTs get added to the query. Only AND/OR are operations
        @keyword_op = []
        if !(@params[:q1].blank? || @params[:q2].blank? || @params[:op2] == 'NOT') && (@params[:f1] != @params[:f2])
          @keyword_op << @params[:op2]
        end
        if !(@params[:q3].blank? || @params[:op3] == 'NOT' || (@params[:q1].blank? && @params[:q2].blank?)) && !([@params[:f1],
                                                                                                                  @params[:f2]].include?(@params[:f3]) && ((@params[:f1] == @params[:f3] && @params[:q1].present?) || (@params[:f2] == @params[:f3] && @params[:q2].present?)))
          @keyword_op << @params[:op3]
        end
        @keyword_op
      end

      def keyword_queries
        unless @keyword_queries
          @keyword_queries = {}

          unless @params[:search_field] == ::AdvancedController.blacklight_config.advanced_search[:url_key]
            return @keyword_queries
          end

          q1 = @params[:q1]
          q2 = @params[:q2]
          q3 = @params[:q3]

          been_combined = false
          @keyword_queries[@params[:f1]] = q1 if @params[:q1].present?
          if @params[:q2].present?
            if @keyword_queries.key?(@params[:f2])
              @keyword_queries[@params[:f2]] = "(#{@keyword_queries[@params[:f2]]}) " + @params[:op2] + " (#{q2})"
              been_combined = true
            elsif @params[:op2] == 'NOT'
              @keyword_queries[@params[:f2]] = "NOT #{q2}"
            else
              @keyword_queries[@params[:f2]] = q2
            end
          end
          if @params[:q3].present?
            if @keyword_queries.key?(@params[:f3])
              @keyword_queries[@params[:f3]] = "(#{@keyword_queries[@params[:f3]]})" unless been_combined
              @keyword_queries[@params[:f3]] = "#{@keyword_queries[@params[:f3]]} " + @params[:op3] + " (#{q3})"
            elsif @params[:op3] == 'NOT'
              @keyword_queries[@params[:f3]] = "NOT #{q3}"
            else
              @keyword_queries[@params[:f3]] = q3
            end
          end
        end

        @keyword_queries
      end
    end
  end

  module BlacklightAdvancedSearch
    module ParsingNestingParser
      def process_query(_params, config)
        queries = []
        ops = keyword_op
        keyword_queries.each do |field, query|
          queries << ParsingNesting::Tree.parse(query,
                                                config.advanced_search[:query_parser]).to_query(local_param_hash(field,
                                                                                                                 config))
          queries << ops.shift
        end
        queries.join(' ')
      end
    end
  end

  module BlacklightAdvancedSearch
    module CatalogHelperOverride
      def remove_guided_keyword_query(fields, my_params = params)
        my_params = Blacklight::SearchState.new(my_params, blacklight_config).to_h
        fields.each do |guided_field|
          my_params.delete(guided_field)
        end
        my_params
      end
    end
  end

  module BlacklightAdvancedSearch
    module RenderConstraintsOverride

      def guided_search(my_params = params)
        constraints = []
        if my_params[:q1].present?
          label = blacklight_config.search_fields[my_params[:f1]][:label]
          query = my_params[:q1]
          constraints << render_constraint_element(
            label, query,
            remove: search_catalog_path(remove_guided_keyword_query(%i[f1 q1], my_params))
          )
        end
        if my_params[:q2].present?
          label = blacklight_config.search_fields[my_params[:f2]][:label]
          query = my_params[:q2]
          query = "NOT #{my_params[:q2]}" if my_params[:op2] == 'NOT'
          constraints << render_constraint_element(
            label, query,
            remove: search_catalog_path(remove_guided_keyword_query(%i[f2 q2 op2], my_params))
          )
        end
        if my_params[:q3].present?
          label = blacklight_config.search_fields[my_params[:f3]][:label]
          query = my_params[:q3]
          query = "NOT #{my_params[:q3]}" if my_params[:op3] == 'NOT'
          constraints << render_constraint_element(
            label, query,
            remove: search_catalog_path(remove_guided_keyword_query(%i[f3 q3 op3], my_params))
          )
        end
        constraints
      end

      # Render a label/value constraint on the screen. Can be called
      # by plugins and such to get application-defined rendering.
      #
      # Can pass in nil label if desired.
      # @see Blacklight::RenderConstraintsHelperBehavior#render_constraint_element
      #
      # @param [String] label to display
      # @param [String] value to display
      # @param [Hash] options
      # @option options [String] :remove url to execute for a 'remove' action
      # @option options [Array<String>] :classes an array of classes to add to container span.
      # @return [String]
      def render_constraint_element(label, value, options = {})
        # Removing. Princeton suppresses the BBox value, but we shall not.
        # if params[:bbox]
        #   value = nil if label == t('geoblacklight.bbox_label')
        # end
        super(label, value, options)
      end

      # Over-ride of Blacklight method, provide advanced constraints if needed,
      # otherwise call super.
      def render_constraints_query(my_params = params)
        if advanced_query.nil? || advanced_query.keyword_queries.empty?
          super(my_params)
        else
          content = guided_search
          safe_join(content.flatten, "\n")
        end
      end
    end
  end
end
