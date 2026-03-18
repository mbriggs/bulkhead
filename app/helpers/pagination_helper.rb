module PaginationHelper
  def paginate(pagy, classes: nil, table: false)
    if pagy.nil?
      return
    end

    classes = classnames(
      "flex", "items-center", "justify-between",
      "border-zinc-200", "dark:border-zinc-700",
      "bg-white", "dark:bg-zinc-800",
      "px-3", "py-4", "w-full",
      { "border-t" => !table },
      classes
    )

    render partial: "shared/ui/paginate", locals: {
      pagy:, classes:
    }
  end

  def table_paginate(pagy, columns: nil, classes: nil)
    row_classes = nil
    if !(pagy.next || pagy.previous)
      row_classes = "hidden @sm:table-row"
    end

    pagination = paginate(pagy, classes:, table: true)

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

  def paginate_prev_url(pagy)
    pagy.previous ? pagy.page_url(pagy.previous) : nil
  end

  def paginate_next_url(pagy)
    pagy.next ? pagy.page_url(pagy.next) : nil
  end
end
