import Config

config :logger,
  level: :info,
  truncate: 4096,
  handle_otp_reports: true,
  handle_sasl_reports: false
