enum AppEnvironment { development, staging, production }

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.environment,
    this.eventId,
  });

  factory AppConfig.fromEnvironment() {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const configuredUrl = String.fromEnvironment('API_BASE_URL');
    const configuredEvent = String.fromEnvironment('EVENT_ID');

    final environment = switch (environmentName) {
      'production' => AppEnvironment.production,
      'staging' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };

    final defaultUrl = switch (environment) {
      AppEnvironment.production => 'https://mariage-dusky-eta.vercel.app/api',
      AppEnvironment.staging => 'https://staging-api.mon-domaine.com/api',
      AppEnvironment.development => 'http://11.11.11.244:8000/api',
    };

    return AppConfig(
      apiBaseUrl: configuredUrl.isEmpty ? defaultUrl : configuredUrl,
      environment: environment,
      eventId: int.tryParse(configuredEvent),
    );
  }

  final String apiBaseUrl;
  final AppEnvironment environment;
  final int? eventId;
}
