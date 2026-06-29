import 'event_bus.dart';

abstract class Event {
  const Event();

  void dispatch() {
    EventBus.instance.dispatch(this);
  }
}
