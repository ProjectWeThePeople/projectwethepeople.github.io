# Belief Circles API Configuration
# For integration with Godot frontend

Rails.application.configure do
  # Enable CORS for Godot client requests
  config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins '*' # Configure this for production
      
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        expose: ['Authorization']
    end
  end
  
  # API-only configuration
  config.api_only = true
  
  # JSON API responses
  config.respond_to_on_unmatched_request = :json
end

# Godot Integration Notes:
# 
# 1. Godot HTTPRequest setup:
#    - Base URL: Rails.application.config.api_base_url
#    - Authentication: JWT tokens in Authorization header
#    - Content-Type: application/json
#
# 2. Circle Rendering in Godot:
#    - Use API endpoints to fetch circle and radian data
#    - Convert position_angle to Godot's coordinate system
#    - Create interactive nodes for each radian
#
# 3. Real-time Updates:
#    - Implement WebSocket connection for live collaboration
#    - Use Godot's WebSocketClient for real-time circle updates
#
# 4. Export Features:
#    - API endpoints for exporting circle data
#    - Godot can generate images/screenshots of circles
#    - Save/load circle configurations locally
#
# Example Godot GDScript for API integration:
#
# extends Node
# 
# const API_BASE = "http://localhost:3000/api/v1"
# var http_request: HTTPRequest
# var auth_token: String
# 
# func _ready():
#     http_request = HTTPRequest.new()
#     add_child(http_request)
#     http_request.request_completed.connect(_on_request_completed)
# 
# func load_circle(circle_id: int):
#     var headers = ["Authorization: Bearer " + auth_token, "Content-Type: application/json"]
#     http_request.request(API_BASE + "/circles/" + str(circle_id), headers, HTTPClient.METHOD_GET)
# 
# func create_radian(circle_id: int, content: String, angle: float):
#     var data = {"radian": {"content": content, "position_angle": angle}}
#     var json_string = JSON.stringify(data)
#     var headers = ["Authorization: Bearer " + auth_token, "Content-Type: application/json"]
#     http_request.request(API_BASE + "/circles/" + str(circle_id) + "/radians", headers, HTTPClient.METHOD_POST, json_string)
# 
# func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
#     if response_code == 200:
#         var json = JSON.new()
#         var parse_result = json.parse(body.get_string_from_utf8())
#         if parse_result == OK:
#             handle_api_response(json.data)
#     else:
#         print("API request failed: ", response_code)