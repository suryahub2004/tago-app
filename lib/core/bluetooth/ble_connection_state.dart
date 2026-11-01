enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  discoveringServices,
  subscribing,        // setting up notify characteristics
  connected,          // fully ready, streaming data
  reconnecting,
  error,
}
