module KitchenSinkHelper
  def kitchen_sink_sections
    {
      "Foundations" => [
        { name: "Overview",     path: kitchen_sink_path,              icon: :home },
        { name: "Typography",   path: typography_kitchen_sink_path,   icon: :document_text },
        { name: "Icons",        path: icons_kitchen_sink_path,        icon: :sparkles },
        { name: "Layouts",      path: layouts_kitchen_sink_path,      icon: :view_columns }
      ],
      "Surfaces" => [
        { name: "Cards",        path: cards_kitchen_sink_path,        icon: :rectangle_group },
        { name: "Page Headers", path: page_headers_kitchen_sink_path, icon: :document_text },
        { name: "Modals",       path: modals_kitchen_sink_path,       icon: :window },
        { name: "Reader Mode",  path: reader_mode_kitchen_sink_path,  icon: :arrows_pointing_out }
      ],
      "Controls" => [
        { name: "Buttons",      path: buttons_kitchen_sink_path,      icon: :cursor_arrow_rays },
        { name: "Forms",        path: forms_kitchen_sink_path,        icon: :pencil_square },
        { name: "Tabs",         path: tabs_kitchen_sink_path,         icon: :squares_2x2 },
        { name: "Interactive",  path: interactive_kitchen_sink_path,  icon: :bolt }
      ],
      "Data" => [
        { name: "Tables",       path: tables_kitchen_sink_path,       icon: :table_cells },
        { name: "Lists",        path: lists_kitchen_sink_path,        icon: :list_bullet },
        { name: "Pagination",   path: pagination_kitchen_sink_path,   icon: :arrows_right_left },
        { name: "Empty States", path: empty_states_kitchen_sink_path, icon: :inbox }
      ],
      "Feedback" => [
        { name: "Alerts",       path: alerts_kitchen_sink_path,       icon: :bell_alert },
        { name: "Badges",       path: badges_kitchen_sink_path,       icon: :tag }
      ]
    }
  end
end
