class AutomationEvent {
  final String type;
  final Map<String, dynamic> data;

  const AutomationEvent({required this.type, required this.data});

  factory AutomationEvent.openUrl(String url) {
    return AutomationEvent(type: 'openUrl', data: {'url': url});
  }

  factory AutomationEvent.click(double x, double y) {
    return AutomationEvent(type: 'click', data: {'x': x, 'y': y});
  }

  factory AutomationEvent.swap(
    double fromX,
    double fromY,
    double toX,
    double toY, [
    int? duration,
  ]) {
    final data = {'from_x': fromX, 'from_y': fromY, 'to_x': toX, 'to_y': toY};
    if (duration != null) {
      data['duration'] = duration.toDouble();
    }
    return AutomationEvent(type: 'swap', data: data);
  }

  factory AutomationEvent.write(String text) {
    return AutomationEvent(type: 'write', data: {'text': text});
  }

  factory AutomationEvent.wait(int milliseconds) {
    return AutomationEvent(type: 'wait', data: {'milliseconds': milliseconds});
  }

  factory AutomationEvent.dismissKeyboard() {
    return AutomationEvent(type: 'dismissKeyboard', data: {});
  }

  factory AutomationEvent.closeApp() {
    return AutomationEvent(type: 'closeApp', data: {});
  }

  factory AutomationEvent.minimizeApp() {
    return AutomationEvent(type: 'minimizeApp', data: {});
  }

  factory AutomationEvent.openThisApp() {
    return AutomationEvent(type: 'openThisApp', data: {});
  }

  factory AutomationEvent.openThisAppIfNeeded() {
    return AutomationEvent(type: 'openThisAppIfNeeded', data: {});
  }

  factory AutomationEvent.openApp(String packageName) {
    return AutomationEvent(type: 'openApp', data: {'packageName': packageName});
  }

  factory AutomationEvent.openTikTok() {
    return AutomationEvent(type: 'openTikTok', data: {});
  }

  factory AutomationEvent.back() {
    return AutomationEvent(type: 'back', data: {});
  }

  factory AutomationEvent.isAppOpen(String packageName) {
    return AutomationEvent(
      type: 'isAppOpen',
      data: {'packageName': packageName},
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'data': data};
  }

  factory AutomationEvent.fromJson(Map<String, dynamic> json) {
    return AutomationEvent(type: json['type'], data: json['data']);
  }

  @override
  String toString() {
    return 'AutomationEvent{type: $type, data: $data}';
  }
}
