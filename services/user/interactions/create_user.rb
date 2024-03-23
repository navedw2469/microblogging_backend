class CreateUser < Interaction
  string :user_name
  string :profile_image_url, default: nil
  string :email
  string :password
  string :full_name
  date :dob
  boolean :is_user_data_required, default: true

  def execute
    user = User.new(get_create_params)

    unless user.save
      self.errors.merge!(user.errors)
      return
    end

    session = user.sessions.new({ is_active: true, expiry_time: Time.now + 1.day })

    unless session.save!
      self.errors.merge!(session.errors)
      return
    end

    return { session_token: session.id, id: user.id } unless self.is_user_data_required

    return { session_token: session.id, user: user.as_json.deep_symbolize_keys.slice(:id, :user_name, :profile_image_url, :email, :full_name, :dob, :bio) }
  end

  def get_create_params
    params = @_interaction_inputs.compact.except(:is_user_data_required)
    params[:sessions_attributes] = [{ is_active: true, expiry_time: Time.now + 1.day }]
    params[:status] = 'active'

    return params
  end
end