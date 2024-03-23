class ApiController < ApplicationController
  before_action :run_api

  def run_api
    base_url, service, api_path = request.path.split('/')
    api_path = service if api_path.blank?
    
    auth_token = request.headers['Authorization'].to_s.split('Bearer ').last

    @api_request = ApiRequest.new(api_path, auth_token)
    @api_request.set_api_config
    
    if @api_request.is_resource_not_found?
      render json: {}, status: :not_found and return
    end

    
    @api_request.set_interaction
    
    @api_request.set_request_params(params.to_unsafe_hash)
    
    if @api_request.is_unauthenticated?
      render json: {}, status: :unauthorized and return
    end

    @api_request.set_response

    if @api_request.is_bad_request?
      render json: @api_request.validation_errors, status: :bad_request and return
    end

    render json: @api_request.result, status: :ok and return
  end

end
  