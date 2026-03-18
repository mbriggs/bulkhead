module TableHelper
  # build a url for a path helper that has sort parameters, and will toggle direction if currently sorted
  def sort_field(field, title: field.to_s.humanize.titleize, namespace: @form&.model_name&.param_key&.to_sym, sortable: true)
    return title unless sortable

    current_params = request.query_parameters.deep_dup
    sort_fields = [ :sort, :sort_order ]

    # pull sort fields off of param namespace if namespace is provided
    if namespace
      current_params[namespace] ||= {}
      sort_params = current_params[namespace].slice(*sort_fields)
    else
      sort_params = current_params.slice(*sort_fields)
    end

    sort = field
    sort_order = "d"
    classes = "w-4 h-4 inline text-zinc-400 dark:text-zinc-500"

    sorted = sort_params[:sort] == field.to_s

    # Show current sort direction and determine next sort order
    if sorted
      if sort_params[:sort_order] == "d"
        arrow = icon(:chevron_down, classes:)
        sort_order = "a" # Next click will sort ascending
      else
        arrow = icon(:chevron_up, classes:)
        sort_order = "d" # Next click will sort descending
      end
      title = safe_join([ title, " ", arrow ])
    end

    sort_params = { sort:, sort_order: }

    # set appropriate sort params back on the right place in the params hash
    if namespace
      current_params[namespace].merge!(sort_params)
    else
      current_params.merge!(sort_params)
    end

    url = url_for(current_params)

    link_to(title, url)
  end

  class TableBuilder
    def initialize(template, sortable: false, sortable_endpoint: nil, style: nil)
      @headers = []
      @template = template
      @sortable = sortable
      @sortable_endpoint = sortable_endpoint
      @row_index = 0
      @style = style
    end

    private def t
      @template
    end

    def column(title = nil, cell: nil, text: :left, classes: nil, &blk)
      # Set default cell styling based on table style
      if @style == :data
        cell ||= ""  # No default styling for data tables
      else
        cell ||= "px-3 py-3.5 text-sm font-semibold text-zinc-900 dark:text-zinc-100"
      end

      case text
      when :left
        text = "text-left"
      when :right
        text = "text-right"
      when :center
        text = "text-center"
      else
        raise ArgumentError, "Invalid text alignment: #{text}"
      end

      if @style == :data
        # For data tables, only include essential classes (width, alignment)
        width_class = classes&.split&.find { |c| c.start_with?("w-") }
        classes = t.classnames(width_class, text)
      else
        # Add rounded corners for first and last th elements in default tables
        corner_classes = "first:rounded-tl-lg last:rounded-tr-lg"
        classes = t.classnames(cell, classes, text, corner_classes)
      end

      title = t.capture(&blk) if blk
      @headers << { title:, classes: }
    end

    def cell(value = nil, cell: "whitespace-nowrap px-3 py-4 text-sm text-zinc-700 dark:text-zinc-300", text: :left, classes: nil, span: nil, &)
      content = value

      if block_given?
        content = t.capture(&)
      end

      case text
      when :left
        text = "text-left"
      when :right
        text = "text-right"
      when :center
        text = "text-center"
      else
        raise ArgumentError, "Invalid text alignment: #{text}"
      end

      classes = t.classnames(cell, classes, text)

      t.tag.td(content, class: classes, colspan: span)
    end

    def time(timestamp, **)
      content = "#{t.time_ago_in_words(timestamp)} ago"
      cell(content, **)
    end

    def link(title, path, **)
      content = t.link_to(title, path)
      cell(content, **)
    end

    def sortable_row(item_id, classes: nil, data: {}, &)
      if !@sortable
        raise ArgumentError, "sortable_row can only be used within a sortable table"
      end

      # Merge custom data attributes with sortable data attributes
      merged_data = {
        sortable_target: "item",
        sortable_item_id_value: item_id,
        position: @row_index
      }.merge(data)

      row_attrs = {
        class: classes,
        data: merged_data
      }

      @row_index += 1

      t.tag.tr(**row_attrs) do
        t.capture(&)
      end
    end

    def sort_handle_cell(classes: "cursor-move", cell: "whitespace-nowrap px-3 py-3 text-sm text-zinc-500 dark:text-zinc-400 align-middle", &)
      handle = t.sortable_handle
      content = if block_given?
        t.safe_join([ handle, t.capture(&) ])
      else
        handle
      end

      cell(content, classes:, cell:)
    end

    def to_state
      {
        headers: @headers,
        sortable: @sortable,
        sortable_endpoint: @sortable_endpoint
      }
    end
  end

  def table(style = nil, classes: nil, pager: nil, sortable: false, sortable_endpoint: nil)
    builder = TableBuilder.new(self, sortable:, sortable_endpoint:, style:)

    body = capture do
      yield builder
    end

    state = builder.to_state

    # Use different partial based on style
    if style == :data
      # Minimal data table style
      classes = classnames(classes)

      tbody_attrs = { class: "divide-y divide-zinc-100 dark:divide-zinc-700" }
      if sortable
        tbody_attrs[:data] = { controller: "sortable" }
        if sortable_endpoint
          tbody_attrs[:data][:sortable_endpoint_value] = sortable_endpoint
          tbody_attrs[:data][:sortable_method_value] = "PATCH"
        end
      end

      render(partial: "shared/ui/table_data", locals: {
        body:,
        headers: state[:headers],
        classes:,
        pager:,
        tbody_attrs:
      })
    else
      # Default table style
      classes = classnames(classes, "mt-8", "flow-root")

      # Build tbody attributes
      tbody_attrs = { class: "divide-y divide-zinc-200 dark:divide-zinc-700" }
      if sortable
        tbody_attrs[:data] = { controller: "sortable" }
        if sortable_endpoint
          tbody_attrs[:data][:sortable_endpoint_value] = sortable_endpoint
          tbody_attrs[:data][:sortable_method_value] = "PATCH"
        end
      end

      table_class = ""
      table_style = ""
      inner_wrapper_class = ""
      inner_wrapper_style = ""
      thead_class = "bg-zinc-50 dark:bg-zinc-700/50"

      render(partial: "shared/ui/table", locals: {
        body:,
        headers: state[:headers],
        classes:,
        pager:,
        tbody_attrs:,
        table_class:,
        table_style:,
        inner_wrapper_class:,
        inner_wrapper_style:,
        thead_class:
      })
    end
  end
end
