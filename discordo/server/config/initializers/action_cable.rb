Rails.application.config.action_cable.disable_request_forgery_protection = true
Rails.application.config.action_cable.allowed_request_origins = [
  /http:\/\/localhost:\d+/,
  /http:\/\/127\.0\.0\.1:\d+/,
  /http:\/\/192\.168\.\d+\.\d+:\d+/,
  /http:\/\/10\.\d+\.\d+\.\d+:\d+/,
  /http:\/\/172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+:\d+/,
  /file:\/\//,
  'null'
]
