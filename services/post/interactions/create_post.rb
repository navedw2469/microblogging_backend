class CreatePost < Interaction
  string :performed_by_id
  string :text, default: nil
  string :image_url, default: nil
  string :parent_post_id, default: nil

  def execute
    create_params = get_create_params

    if create_params.except(:user_id, parent_post_id).blank?
      self.errors.add(:post, 'should not be blank')
      return
    end

    post = Post.new(create_params)

    unless post.save
      self.errors.merge!(post.errors)
      return
    end

    { id: post.id }
  end

  def get_create_params
    self.text = nil if self.text.blank?

    return {
      user_id: self.performed_by_id,
      text: self.text,
      image_url: self.image_url,
      parent_post_id: self.parent_post_id
    }.compact
  end
end