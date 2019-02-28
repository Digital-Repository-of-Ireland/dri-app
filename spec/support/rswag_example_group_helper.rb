# this module should be extended rather than included
# so the helper methods can be called from example groups
# without WrongScopeError
# see https://github.com/domaindrivendev/rswag/blob/ef91e087d3332c5105a1b1601093517fc434e5bb/rswag-specs/lib/rswag/specs.rb#L15
module RswagExampleGroupHelper
  def default_search_params
    # default: 'objects' if param is omitted, 'collections' if using search through UI
    parameter name: :mode, description: 'Show Objects or Collections', 
              in: :query, type: :string, default: 'objects', 
              enum: %w[objects collections]

    # default: false if param is omitted, true if using search through UI
    parameter name: :show_subs, description: 'Show subcollections',
              in: :query, type: :boolean, default: false

    # although when you visit /my_collections in a web browser mode=collections
    # if you call /my_collections.json you get objects, not only collections
    let(:show_subs)    { false }
    let(:mode)         { 'objects' }
  end


  def default_page_params
    parameter name: :per_page, description: 'Number of results per page', 
              in: :query, type: :integer, default: 9
      
    parameter name: :page, description: 'Page number', 
              in: :query, type: :integer, default: 1

    let(:per_page)     { 9 }
    let(:page)         { 1 }
  end

  def pretty_json_param
    parameter name: :pretty, description: 'Indent json so it is human readable', 
              in: :query, type: :boolean, default: false

    let(:pretty) { false }
  end

  # @param [Blacklight::Configuration] config
  def search_controller_params(config)
    parameter name: :search_field, description: 'Search for data in this field only',
              in: :query, type: :string, default: 'all_fields',
              # keep docs in sync with dev, show all possible valid values for search_field
              enum: config.search_fields.keys

    # defaults to newest (system_create_dtsi) if omitted
    parameter name: :sort, description: 'Fields to sort by',
              in: :query, type: :string, default: nil,
              enum: config.sort_fields.keys
              # # TODO find a way to use labels in UI and keys on submit request
              # # gives labels but keys are used in param 
              # controller.blacklight_config.sort_fields.values.map(&:label)

    let(:sort)         { nil }
    let(:search_field) { nil }
  end
end
