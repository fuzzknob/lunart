import 'package:lunart/lunart.dart';

void main() {
  Lunart()
      .get('/', (req) => 'Hello from Lunart!')
      .get('/index.html', (req) => '<h1>Hello from Lunart!</h1>')
      .post('/posts', (req) async {
        // get request body
        final data = await req.body();

        return data;
      })
      .get('/posts/:id', (req) async {
        // get request parameters from parameters map
        final id = req.parameters['id'];

        return {
          'posts': 'Your post has the id: $id',
        };
      })
      .get('/posts/search', (req) {
        // get queries from the queries map
        final query = req.queries['q'];

        // Sends json object with message field
        return Res.message('Searching for: $query');
      })
      .serve(); // Starts server at port 8000
}
