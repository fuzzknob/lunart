// import 'package:lunart/lunart.dart';

class Validator {
  const Validator();
}

const validator = Validator();

@validator
class PostDTO {
  String title;
  String body;

  PostDTO({required this.title, required this.body});
}

void main() {
  //
}
