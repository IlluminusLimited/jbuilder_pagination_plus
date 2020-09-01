require 'rack/utils'
require 'jbuilder'
require 'jbuilder/pagination/pages'
require 'jbuilder/pagination/exceptions/unpageable_resource_error'

module Pagination
  # The order of this hash matters, elements are pulled off the end by calling .pop recursively
  DEFAULT_PAGINATION = [[:page, ->(params) { params.dig(:page, :number) }],
                        [:per, ->(params) { params.dig(:page, :size) }]].freeze

  NO_COUNT_PAGINATION = [[:page, ->(params) { params.dig(:page, :number) }],
                         [:per, ->(params) { params.dig(:page, :size) }],
                         [:without_count]].freeze

  # @param pageable_resource [Object] resource to be paged
  # @param methods [Array<Symbol, Lambda>] array of methods to call on the pageable_resource
  # @param params [Object] params object from the controller
  def paginate_no_count(pageable_resource, methods = NO_COUNT_PAGINATION.dup, params = self.params)
    paginate(pageable_resource, methods, params)
  end

  # @param pageable_resource [Object] resource to be paged
  # @param methods [Array<Symbol, Lambda>] array of methods to call on the pageable_resource
  # @param params [Object] params object from the controller
  def paginate(pageable_resource, methods = DEFAULT_PAGINATION.dup, params = self.params)
    return pageable_resource if methods.blank?
    key_value_array = methods.pop
    build_pagination(key_value_array, paginate(pageable_resource, methods, params), params)
  end

  private

  def build_pagination(key_value_array, pageable_resource, params)
    unless pageable_resource.respond_to?(key_value_array[0])
      raise Errors::UnpageableResourceError, "Resource does not respond to '#{key_value_array[0]}' method!"
    end

    if key_value_array[1].nil?
      return pageable_resource.public_send(key_value_array[0])
    end

    pageable_resource.public_send(key_value_array[0], key_value_array[1].call(params))
  end
end
