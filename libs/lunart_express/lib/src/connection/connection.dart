import '../query/grammar/grammar.dart';
import '../drivers/driver.dart';

abstract interface class Connection {
  // gets a new instance of grammar
  Grammar get grammar;

  // gets a new instance of driver
  Driver get driver;
}
