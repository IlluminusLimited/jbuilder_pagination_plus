class Jbuilder
  ONE_PAGE = 1

  # Used to generate the pagination links for a collection
  # @param collection [Object] the paginated collection
  # @param opts [Hash] options to pass in
  # @option opts [String] :url The url to use
  # @option opts [Hash] :query_parameters Query parameters to automatically add to any generated urls
  # @option opts [Boolean] :no_count This can be passed to force pagination without counting the total which is
  #   an alternative to calling #pages_no_count!
  def pages!(collection, opts = {})
    return unless collection && is_paginated?(collection)

    options_query_parameters, original_params, original_url = handle_url(opts)

    if opts.fetch(:no_count, false)
      pages_without_count(collection, options_query_parameters, original_params, original_url)
    elsif is_countable?(collection)
      pages_with_count(collection, options_query_parameters, original_params, original_url)
    else
      pages_without_count(collection, options_query_parameters, original_params, original_url)
    end
  end

  # Used to generate the pagination links for a collection without requiring the total_count
  # @param collection [Object] the paginated collection
  # @param opts [Hash] options to pass in
  # @option opts [String] :url for the url to use
  # @option opts [Hash] :query_parameters to automatically add to any generated urls
  def pages_no_count!(collection, opts = {})
    return unless collection && is_paginated?(collection)

    options_query_parameters, original_params, original_url = handle_url(opts)

    pages_without_count(collection, options_query_parameters, original_params, original_url)
  end

  private

  def handle_url(opts)
    options_url = opts.fetch(:url, nil)
    original_url = nil
    original_params = {}
    if options_url
      original_url, original_params = options_url.split("?")
      original_params = ::Rack::Utils.parse_nested_query(original_params).deep_symbolize_keys
    end
    options_query_parameters = opts.fetch(:query_parameters, {})
    [options_query_parameters, original_params, original_url]
  end

  def pages_with_count(collection, options_query_parameters, original_params, original_url)
    pages_from(collection).map do |key, value|
      build_jbuilder_value(collection, key, options_query_parameters, original_params, original_url, value)
    end
  end



  def pages_without_count(collection, options_query_parameters, original_params, original_url)
    pages_without_count_from(collection).map do |key, value|
      build_jbuilder_value(collection, key, options_query_parameters, original_params, original_url, value)
    end
  end

  def build_jbuilder_value(collection, key, options_query_parameters, original_params, original_url, value)
    params = query_parameters(options_query_parameters, original_params)
               .deep_merge(page: { number: value, size: collection.size })
               .to_query
    _set_value key, "#{original_url}?#{params}"
  end

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

  def pages_without_count_from(collection)
    {}.tap do |pages|
      pages[:self] = collection.current_page

      unless collection.current_page == ONE_PAGE
        pages[:first] = ONE_PAGE
        pages[:prev] = collection.current_page - ONE_PAGE
      end

      if collection.respond_to?(:last_page?) && collection.last_page?
        # Do nothing
        return pages
      else
        pages[:next] = collection.current_page + ONE_PAGE
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

  # Kaminari raises an exception if you call #total_count on a #without_count-ed collection
  # Rescue can't be good for performance which is why you should use pages_no_count! if you know you will be
  # dealing with non-counted collections
  def is_countable?(collection)
    collection.total_pages
  rescue ::StandardError
    false
  end
end
