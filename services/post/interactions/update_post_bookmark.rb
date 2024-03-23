class UpdatePostBookmark < Interaction
  string :performed_by_id
  string :post_id
  boolean :only_data_required, default: true

  def execute
    bookmark = PostBookmark.find_by(user_id: self.performed_by_id, post_id: self.post_id)
    
    if bookmark.blank?
      self.errors.add(:bookmark, 'not found')
      return
    end

    unless bookmark.update!({ is_active: false })
      self.errors.merge!(bookmark.errors)
      return
    end

    return { id: bookmark.id } unless self.only_data_required

    return { is_bookmarked: false, bookmarks_count: PostBookmark.where(post_id: bookmark.post_id, is_active: true).count }
  end
end