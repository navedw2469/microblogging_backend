class ListUsers < Interaction
  hash :filters, default: {}, strip: false
  integer :page_limit, default: 10
  integer :page, default: 1
  string :sort_by, default: 'created_at'
  string :sort_type, default: 'desc'

  POSSIBLE_DIRECT_FILTERS = [:id, :user_name, :status].freeze
  POSSIBLE_INDIRECT_FILTERS = [].freeze

  set_callback :execute, :before, lambda {
    self.filters = self.filters.deep_symbolize_keys.select { |_k, v| v.to_s.present? }
    unexpected_filters = (self.filters.keys - (POSSIBLE_DIRECT_FILTERS + POSSIBLE_INDIRECT_FILTERS))
    self.filters = self.filters.except(*unexpected_filters)
  }

  def execute
    query = get_query
    query = apply_direct_filters(query)
    query = apply_indirect_filters(query)


    data = get_data(query)
    pagination_data = get_pagination_data(query)

    { list: data }.merge!(pagination_data)
  end

  def get_query
    User.order("#{self.sort_by} #{self.sort_type}").page(self.page).per(self.page_limit)
  end

  def apply_direct_filters(query)
    query.where(self.filters.slice(*POSSIBLE_DIRECT_FILTERS))
  end

  def apply_indirect_filters(query)
    query
  end

  def get_data(query)
    return query.as_json.map(&:deep_symbolize_keys)
  end

  def get_pagination_data(query)
    {
      page: self.page,
      total: query.total_pages,
      total_count: query.total_count,
      page_limit: self.page_limit
    }
  end
end