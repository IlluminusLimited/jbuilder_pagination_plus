class Jbuilder
  ONE_PAGE = 1

  def pages!(collection, options = {})
    return unless collection && is_paginated?(collection)

    options_url = options.fetch(:url, nil)
    original_url = nil
    original_params = {}
    if options_url
      original_url, original_params = options_url.split("?")
      original_params = ::Rack::Utils.parse_nested_query(original_params).deep_symbolize_keys
    end
    options_query_parameters = options.fetch(:query_parameters, {})

    pages_from(collection).map do |key, value|
      params = query_parameters(options_query_parameters, original_params).deep_merge(page: { number: value, size: collection.size }).to_query
      _set_value key, "#{original_url}?#{params}"
    end
  end

  private

    def pages_from(collection)
      {}.tap do |pages|
        pages[:self] = collection.current_page
        return pages if collection.total_pages <= ONE_PAGE

        unless collection.current_page == ONE_PAGE
          pages[:first] = ONE_PAGE
          pages[:prev] = collection.current_page - ONE_PAGE
        end

        unless collection.current_page == collection.total_pages
          pages[:next] = collection.current_page + ONE_PAGE
          pages[:last] = collection.total_pages
        end
      end
    end

    def query_parameters(query_parameters, original_parameters)
      @query_parameters ||= original_parameters.deep_merge(query_parameters || {}).compact
    end

    def is_paginated?(collection)
      collection.respond_to?(:current_page) &&
          collection.respond_to?(:total_pages) &&
          collection.respond_to?(:size)
    end
end
