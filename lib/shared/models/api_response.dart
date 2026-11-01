class ApiResponse<T> {
  const ApiResponse({required this.data, this.message});

  final T data;
  final String? message;
}
