# OpenTelemetry is opt-in so existing deployments remain unchanged until the
# OTLP endpoint and sampling policy are explicitly configured.
if ENV.fetch("OTEL_SDK_DISABLED", "false") != "true" &&
   ENV.fetch("OTEL_TRACES_EXPORTER", "none") != "none"
  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"
  require "opentelemetry/instrumentation/rails"

  # Keep telemetry useful for latency and failure analysis without exporting
  # request data, credentials, or database statements.
  class SureTelemetryPrivacyProcessor
    REDACTED_ATTRIBUTES = %w[
      url.query
      url.full
      db.statement
      db.query.text
      http.request.body
      http.response.body
    ].freeze

    def on_start(_span, _parent_context); end

    def on_finishing(span)
      attributes = span.attributes.dup
      REDACTED_ATTRIBUTES.each { |key| attributes.delete(key) }
      attributes.delete_if do |key, _|
        key.start_with?("http.request.header.") ||
          key.start_with?("http.response.header.") ||
          key.start_with?("http.request.cookie.") ||
          key.start_with?("http.response.cookie.")
      end
      # The SDK freezes attributes before this hook; replace the mutable copy
      # so redaction remains inside the supported span lifecycle.
      span.instance_variable_set(:@attributes, attributes)
    end

    def on_finish(_span); end

    def force_flush(timeout: nil); OpenTelemetry::SDK::Trace::Export::SUCCESS; end

    def shutdown(timeout: nil); OpenTelemetry::SDK::Trace::Export::SUCCESS; end

  end

  OpenTelemetry::SDK.configure do |config|
    config.service_name = ENV.fetch("OTEL_SERVICE_NAME", "sure")
    config.add_span_processor(SureTelemetryPrivacyProcessor.new)
    config.use "OpenTelemetry::Instrumentation::Rails"
    config.use "OpenTelemetry::Instrumentation::ActionPack"
    config.use "OpenTelemetry::Instrumentation::ActiveRecord"
  end
end
