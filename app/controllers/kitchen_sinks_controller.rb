require "ostruct"

# Dev-only controller for visual UI component verification.
# No DB queries — all demo data is built inline with OpenStruct stand-ins.
class KitchenSinksController < ActionController::Base
  layout -> { Bulkhead.kitchen_sink_layout }
  helper Bulkhead::Engine.helpers

  # ActiveModel stand-in for form demos. Provides errors, model_name, and
  # human_attribute_name that OpenStruct lacks.
  class DemoItem
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :name, :string
    attribute :email, :string
    attribute :description, :string
    attribute :role, :string
    attribute :category_id, :integer
    attribute :active, :boolean
    attribute :start_date, :date
    attribute :assignee, :string
    attribute :password, :string
    attribute :count, :integer
  end

  def show; end
  def buttons; end
  def confirm_demo = redirect_to(buttons_kitchen_sink_path, notice: "Record deleted (not really).")
  def link_demo = redirect_back(fallback_location: kitchen_sink_path, notice: "Navigated via \"#{params[:label]}\" link.")
  def alerts; end
  def badges; end
  def cards; end
  def tables; end
  # JSON endpoint for the remote combobox demo. Filters a static list by ?q=.
  def assignees
    people = [
      { label: "Alice Chen", value: "alice" },
      { label: "Bob Martinez", value: "bob" },
      { label: "Carol Smith", value: "carol" },
      { label: "Dan Lee", value: "dan" },
      { label: "Eve Johnson", value: "eve" },
      { label: "Fay Kumar", value: "fay" },
      { label: "Grace Hopper", value: "grace" },
      { label: "Hank Patel", value: "hank" }
    ]

    q = params[:q].to_s.downcase
    results = q.blank? ? people : people.select { |p| p[:label].downcase.include?(q) }
    render json: results
  end

  def save_demo = redirect_to(forms_kitchen_sink_path, notice: "Record saved (not really).")
  def cancel_demo = redirect_to(forms_kitchen_sink_path, notice: "Changes discarded.")
  def forms
    @clean = DemoItem.new(
      name: "Example Project",
      email: "user@example.com",
      description: "A sample description for the kitchen sink demo.",
      role: "admin",
      category_id: 2,
      assignee: "carol",
      active: true,
      start_date: Date.today,
      password: "",
      count: 5
    )

    @errored = DemoItem.new(
      name: "",
      email: "not-an-email",
      description: "",
      role: "",
      category_id: nil,
      assignee: "",
      active: false,
      start_date: nil,
      password: "short",
      count: -1
    )
    @errored.errors.add(:name, "can't be blank")
    @errored.errors.add(:email, "is not a valid email address")
    @errored.errors.add(:description, "can't be blank")
    @errored.errors.add(:role, "must be selected")
    @errored.errors.add(:password, "is too short (minimum is 8 characters)")
    @errored.errors.add(:count, "must be greater than 0")
    @errored.errors.add(:assignee, "must be selected")
    @errored.errors.add(:start_date, "can't be blank")

    @roles = [ [ "Admin", "admin" ], [ "Editor", "editor" ], [ "Viewer", "viewer" ] ]
    @categories = [ OpenStruct.new(id: 1, name: "Engineering"), OpenStruct.new(id: 2, name: "Design"), OpenStruct.new(id: 3, name: "Product") ]
    @assignees = [ [ "Alice Chen", "alice" ], [ "Bob Martinez", "bob" ], [ "Carol Smith", "carol" ], [ "Dan Lee", "dan" ], [ "Eve Johnson", "eve" ] ]
  end
  def modals
    @demo = DemoItem.new(name: "Kitchen Sink Item", description: "Sample description")
  end
  def pagination; end
  def empty_states; end
  def lists; end
  def icons; end
  def interactive; end
  def page_headers; end
  def tabs; end
  def layouts; end
  def reader_mode; end
  def typography; end
end
