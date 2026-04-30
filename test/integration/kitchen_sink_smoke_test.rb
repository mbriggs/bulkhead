require "test_helper"

class KitchenSinkSmokeTest < ActionDispatch::IntegrationTest
  ROUTES = %w[buttons alerts badges cards tables forms modals pagination
              empty_states lists icons interactive page_headers tabs
              layouts reader_mode typography].freeze

  ROUTES.each do |action|
    test "#{action} renders successfully" do
      get "/kitchen_sink/#{action}"
      assert_response :success
    end
  end
end
