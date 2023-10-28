class ListPosts < Interaction
  hash :filters, default: {}, strip: false
  integer :page_limit, default: 10
  integer :page, default: 1
  string :sort_by, default: 'created_at'
  string :sort_type, default: 'desc'
  boolean :is_user_data_required, default: false


  POSSIBLE_DIRECT_FILTERS = [:text, :user_id].freeze
  POSSIBLE_INDIRECT_FILTERS = [:liked_by_id, :replied_by_id, :post_type].freeze

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
    Post.order("#{self.sort_by} #{self.sort_type}").page(self.page).per(self.page_limit)
  end

  def apply_direct_filters(query)
    query.where(self.filters.slice(*POSSIBLE_DIRECT_FILTERS))
  end

  def apply_indirect_filters(query)
    indirect_filters = self.filters.slice(*POSSIBLE_INDIRECT_FILTERS)
    indirect_filters.keys.each do |indirect_filter|
      query = send("apply_#{indirect_filter}_filter", query)
    end
    query
  end

  def apply_liked_by_id_filter
    query = query.joins(:likes).where(:post_likes => { user_id: self.filters[:liked_by_id] })
  end

  def get_data(query)
    data = query.as_json.map(&:deep_symbolize_keys)
    ids = data.pluck(:id)

    likes = PostLike.where(post_id: ids).group(:post_id).count
    replies = Post.where(parent_post_id: ids).group(:parent_post_id).count

    data.each do |obj|
      obj[:likes_count] = likes[obj[:id]].to_i
      obj[:replies_count] = replies[obj[:id]].to_i
    end

    data = get_user_data(data) if self.is_user_data_required
    
    return data
  end

  def get_user_data(data)
    user_data = ListUsers.run!(filters: { id: data.pluck(:user_id).compact })[:list]

    user_data_mappings = {}
    user_data.each { |user| user_data_mappings[user[:id]] = user }

    data.each { |post| post[:user] = user_data_mappings[post[:user_id]] }
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