class ListUsers < Interaction
  string :performed_by_id
  hash :filters, default: {}, strip: false
  integer :page_limit, default: 10
  integer :page, default: 1
  string :sort_by, default: 'created_at'
  string :sort_type, default: 'desc'
  boolean :is_user_data_required, default: true

  POSSIBLE_DIRECT_FILTERS = [:id, :user_name, :status].freeze
  POSSIBLE_INDIRECT_FILTERS = [:followed_by_user_name, :followed_user_name, :full_name_q].freeze

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
    self.filters.slice(*POSSIBLE_INDIRECT_FILTERS).keys.each do |indirect_filter|
      query = send("apply_#{indirect_filter}_filter", query)
    end

    query
  end

  def apply_full_name_q_filter(query)
    q = self.filters[:full_name_q].to_s

    query.where('full_name ilike ?', "%#{q}%")
  end

  def apply_followed_by_user_name_filter(query)
    id = User.where(user_name: self.filters[:followed_by_user_name]).first.id rescue nil

    query = query.joins(:followers).where(user_followers: { follower_user_id: id, is_active: true}).distinct
  end

  def apply_followed_user_name_filter(query)
    id = User.where(user_name: self.filters[:followed_user_name]).first.id rescue nil

    query.where(id: UserFollower.where(user_id: id, is_active: true).select('follower_user_id'))
  end

  def get_data(query)
    return query.as_json.map(&:deep_symbolize_keys) unless self.is_user_data_required
    
    followed_users = query.joins(:followers).where(:user_followers=>{follower_user_id: self.performed_by_id, is_active: true}).as_json.pluck('id')
    data = query.as_json.map(&:deep_symbolize_keys)

    data.each do |obj|
      obj[:is_following] = followed_users.include?(obj[:id])
    end
    
    return data
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