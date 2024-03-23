class ListPosts < Interaction
  string :performed_by_id
  hash :filters, default: {}, strip: false
  integer :page_limit, default: 10
  integer :page, default: 1
  string :sort_by, default: 'created_at'
  string :sort_type, default: 'desc'
  boolean :is_user_data_required, default: false
  boolean :is_parent_post_data_required, default: true


  POSSIBLE_DIRECT_FILTERS = [:id, :text, :user_id, :parent_post_id].freeze
  POSSIBLE_INDIRECT_FILTERS = [:liked_by_id, :replied_by_id, :post_type, :user_name, :type, :q, :posted_by_user_name, :replied_by_user_name, :media_posted_by_user_name, :liked_by_user_name, :bookmarked_by_user_name].freeze

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

  def apply_q_filter(query)
    q = self.filters[:q].to_s

    query.where('text ilike ?', "%#{q}%")
  end

  def apply_user_name_filter(query)
    id = GetUser.run!(user_name: self.filters[:user_name], performed_by_id: self.performed_by_id)[:data][:id] rescue nil

    query = query.where(user_id: id)
  end

  def apply_type_filter(query)
    return query.where(parent_post_id: nil) if self.filters[:type] == 'post'

    return query.where.not(parent_post_id: nil) if self.filters[:type] == 'reply'

    return query.where.not(image_url: nil) if self.filters[:type] == 'media'

    return query.joins(:likes).where(post_likes: {is_active: true}).distinct if self.filters[:type] == 'like'

    return query.joins(:bookmarks).where(post_bookmarks: {is_active: true}).distinct if self.filters[:type] == 'bookmark'
  end

  def apply_posted_by_user_name_filter(query)
    id = GetUser.run!(user_name: self.filters[:posted_by_user_name], performed_by_id: self.performed_by_id)[:data][:id] rescue nil

    query.where(parent_post_id: nil, user_id: id)
  end

  def apply_replied_by_user_name_filter(query)
    id = GetUser.run!(user_name: self.filters[:replied_by_user_name], performed_by_id: self.performed_by_id)[:data][:id] rescue nil

    query = query.where.not(parent_post_id: nil).where(user_id: id)
  end

  def apply_media_posted_by_user_name_filter(query)
    id = GetUser.run!(user_name: self.filters[:media_posted_by_user_name], performed_by_id: self.performed_by_id)[:data][:id] rescue nil

    query = query.where.not(image_url: nil).where(user_id: id)
  end

  def apply_liked_by_user_name_filter(query)
    id = GetUser.run!(user_name: self.filters[:liked_by_user_name], performed_by_id: self.performed_by_id)[:data][:id] rescue nil

    query.joins(:likes).where(post_likes: {is_active: true, user_id: id}).distinct
  end

  def apply_bookmarked_by_user_name_filter(query)
    id = GetUser.run!(user_name: self.filters[:bookmarked_by_user_name], performed_by_id: self.performed_by_id)[:data][:id] rescue nil

    query.joins(:bookmarks).where(post_bookmarks: {is_active: true, user_id: id}).distinct
  end

  def apply_liked_by_id_filter(query)
    query = query.joins(:likes).where(:post_likes => { user_id: self.filters[:liked_by_id] })
  end

  def get_data(query)
    data = query.as_json.map(&:deep_symbolize_keys)
    ids = data.pluck(:id)
    parent_post_ids = data.pluck(:parent_post_id).compact
    
    liked_by_loggedin_user_posts = PostLike.where(post_id: ids, user_id: self.performed_by_id, is_active: true).pluck(:post_id)
    bookmarked_by_loggedin_user_posts = PostBookmark.where(post_id: ids, user_id: self.performed_by_id, is_active: true).pluck(:post_id)
    replied_by_loggedin_user_posts = Post.where(parent_post_id: ids, user_id: self.performed_by_id).pluck(:parent_post_id)
    parent_posts = ListPosts.run!(filters: {id: parent_post_ids}, performed_by_id: self.performed_by_id, is_parent_post_data_required: false, is_user_data_required: true)[:list] if self.is_parent_post_data_required
    

    likes = PostLike.where(post_id: ids, is_active: true).group(:post_id).count
    bookmarks = PostBookmark.where(post_id: ids, is_active: true).group(:post_id).count
    replies = Post.where(parent_post_id: ids).group(:parent_post_id).count


    data.each do |obj|
      obj[:likes_count] = likes[obj[:id]].to_i
      obj[:is_liked] = liked_by_loggedin_user_posts.include?(obj[:id])
      obj[:bookmarks_count] = bookmarks[obj[:id]].to_i
      obj[:is_bookmarked] = bookmarked_by_loggedin_user_posts.include?(obj[:id])
      obj[:replies_count] = replies[obj[:id]].to_i
      obj[:is_replied] = replied_by_loggedin_user_posts.include?(obj[:id])
      obj[:parent_post] = parent_posts.find{ |post| post[:id] == obj[:parent_post_id] }  if self.is_parent_post_data_required
    end

    data = get_user_data(data) if self.is_user_data_required
    
    return data
  end

  def get_user_data(data)
    user_data = ListUsers.run!(filters: { id: data.pluck(:user_id).compact, is_user_data_required: false },  performed_by_id: self.performed_by_id)[:list]

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