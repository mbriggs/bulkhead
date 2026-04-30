Rails.application.routes.draw do
  root to: redirect("/kitchen_sink")

  resource :kitchen_sink, only: :show do
    member do
      %i[buttons alerts badges cards tables forms modals pagination
         empty_states lists icons interactive page_headers tabs layouts
         reader_mode typography assignees].each { |action| get action }
      %i[confirm_demo link_demo save_demo cancel_demo].each { |action| post action }
    end
  end
end
