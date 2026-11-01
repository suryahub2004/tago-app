class ApiEndpoints {
  const ApiEndpoints._();

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const refresh = '/auth/refresh';
  static const me = '/users/me';
  static const healthProfile = '/users/me/health-profile';
  static const vitalsSummary = '/vitals/summary';
  static const vitalsHistory = '/vitals/history';
  static const vitalsBatch = '/vitals/batch';
  static const correlations = '/vitals/correlations';
  static const familyGroup = '/family/my-group';
  static const familyInvite = '/family/invite';
  static const shopFeatured = '/shop/products/featured';
  static const shopProducts = '/shop/products';
  static const shopOrders = '/shop/orders';
  static const alertSettings = '/alerts/settings';
}
