class UpdateUser < Interaction
  string :id
  with_options default: nil do
    string :user_name
    string :profile_image_url
    string :email
    string :password
    string :full_name
    date :dob
    string :bio
  end

  def execute
    user = User.find(self.id)

    unless user.update(get_update_params)
      self.errors.merge!(user.errors)
    end

    { id: user.id }
  end

  def get_update_params
    @_interaction_inputs.compact.except(:id)
  end
end