class GetPost < Interaction
  string :performed_by_id
  string :id
  boolean :is_user_data_required, default: true

  def execute
    post = Post.where(id: self.id).first

    if post.blank?
      self.errors.add(:post, 'does not exist')
      return
    end

    is_liked = post.likes.where(user_id: self.performed_by_id, is_active: true).present?
    is_bookmarked = post.bookmarks.where(user_id: self.performed_by_id, is_active: true).present?
    likes_count = post.likes.where(is_active: true).count
    bookmarks_count = post.bookmarks.where(is_active: true).count
    replies_count = Post.where(parent_post_id: post.id).count

    user = ListUsers.run!(filters: { id: post.user_id, is_user_data_required: false },  performed_by_id: self.performed_by_id)[:list].first

    return {data: post.as_json.deep_symbolize_keys.merge!({is_liked: is_liked, is_bookmarked: is_bookmarked, likes_count: likes_count, bookmarks_count: bookmarks_count, user: user, replies_count: replies_count })}
  end
end