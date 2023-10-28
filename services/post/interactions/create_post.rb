class CreatePost < Interaction
  string :user_id
  string :text, default: nil
  string :image_url, default: nil
  string :parent_post_id, default: nil

  def execute
    post = Post.new(get_create_params)

    unless post.save
      self.errors.merge!(post.errors)
      return
    end

    { id: post.id }
  end

  def get_create_params
    @_interaction_inputs.compact
  end
end