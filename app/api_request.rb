class ApiRequest
  attr_accessor :api_path, :auth_token, :api_config, :interaction, :request_params, :response

  def initialize(api_path, auth_token)
    self.api_path = api_path
    self.auth_token = auth_token
  end

  def set_api_config
    self.api_config = $API_REGISTRY[self.api_path.to_sym]
  end

  def is_resource_not_found?
    self.api_config.nil?
  end

  def set_request_params(params)
    self.request_params = {}

    self.interaction.filters.keys.each do |filter|
      self.request_params[filter] = params[filter] if params.key?(filter)
    end

    self.request_params.as_json.deep_symbolize_keys!
  end

  def set_interaction
    self.interaction = self.api_path.camelize.constantize
  end

  def set_response
    interaction = self.interaction.run(self.request_params.deep_symbolize_keys)

    self.response = {}
    if interaction.valid?
      self.response[:result] = interaction.result
    else
      self.response[:errors] = interaction.errors.messages
    end
  end

  def is_bad_request?
    self.response[:errors].present?
  end

  def is_unauthenticated?
    return false if self.api_config[:access_type] == 'public'

    return true if self.auth_token.blank?

    session = GetUserSession.run!(session_token: self.auth_token)

    return true if session.blank?
    
    self.request_params[:performed_by_id] = session[:user][:id]

    return false
  end

  def validation_errors
    self.response[:errors]
  end

  def result
    self.response[:result]
  end
end