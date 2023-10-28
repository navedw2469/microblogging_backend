class CreateUser < Interaction
  string :user_name
  string :profile_image_url
  string :email
  string :password
  string :full_name
  date :dob

  def execute
    user = User.new(get_create_params)

    unless user.save
      self.errors.merge!(user.errors)
      return
    end

    { id: user.id, session_token: user.sessions.first.id }
  end

  def get_create_params
    params = @_interaction_inputs.compact
    params[:sessions_attributes] = [{ is_active: true, expiry_time: Time.now + 1.day }]

    return params
  end
end