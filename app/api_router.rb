class ApiRouter

  def self.load
    MyApplication::Application.routes.draw do
      $API_REGISTRY.each do |api, api_config|
        send(api_config[:method], api, to: "api##{api}")
        ApiController.define_method api.to_sym do
        end
      end
    end
  end
  
end
