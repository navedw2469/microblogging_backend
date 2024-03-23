class CreatePostBookmark < Interaction
  string :performed_by_id
  string :post_id
  boolean :only_data_required, default: true

  def execute
    bookmark = PostBookmark.find_or_initialize_by(user_id: self.performed_by_id, post_id: self.post_id)
    bookmark.is_active = true

    unless bookmark.save!
      self.errors.merge!(bookmark.errors)
      return
    end

    return { id: bookmark.id } unless self.only_data_required

    return { is_bookmarked: true, bookmarks_count: PostBookmark.where(post_id: bookmark.post_id, is_active: true).count }
  end
end