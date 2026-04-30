module PaginationHelper
  # Renders Pagy's `series_nav` with bulkhead chrome (border, optional info_tag).
  # Returns nothing when there's only a single page so callers can render
  # surrounding markup unconditionally.
  def paginate(pagy, classes: nil, table: false, info: true)
    return if pagy.nil? || pagy.last <= 1

    classes = classnames(
      "pagination",
      { "bordered" => !table },
      classes
    )

    render partial: "shared/ui/paginate", locals: {
      pagy:, classes:, show_info: info
    }
  end

  def table_paginate(pagy, columns: nil, classes: nil)
    pagination = paginate(pagy, classes:, table: true)
    return if pagination.blank?

    row_classes = nil
    if !(pagy.next || pagy.previous)
      row_classes = "pagination-row available"
    end

    tag.tr(class: row_classes) do
      tag.td(pagination, colspan: columns)
    end
  end

  def pagination_info(pagy, entity)
    if pagy.nil?
      return
    end

    if entity.is_a?(Class)
      entity = entity.name.split("::").last.pluralize.downcase
    end

    tag.em { safe_join([ tag.strong(pagy.count), " #{entity} found" ]) }
  end
end
