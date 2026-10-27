# Lunart

- [x] Setup tests
- [x] Setup agents to write tests
- [x] Figure out the folder structure for lunart
- [x] Move over more existing code from the old lucore
- [x] Modify the codebase to make it compatible with the vision
- [ ] ~~Add hooks~~
- [x] Change response convertor
- [x] Move the server from lunart to a separate class
- [x] Add more testing
- [x] Copy over more examples
- [x] Setup git
- [x] Implement directory serving
      [x] Fix wild card path
      [x] Rough implement static file serving
      [x] Decide about caching
      [x] Etags
      [x] ignore patterns
      [x] Write tests
      [x] all() route and add missing methods
      [x] Write a proper example
- [x] Body parser limit & optimizations
- [x] Add query method
- [x] Fix stream
      [x] Streaming text
      [x] Convert serveStatic to a plugin
      [x] Range request support
      [x] Update tests
- [x] Implement SSE
      [x] Write implementation
      [x] Write Tests
- [ ] Implement websockets
      [x] Research
      [x] Write implementation
      [x] On close clean up listeners
      [x] Memory footprint
      [x] TODO: add global for this error catcher
      [x] Implement other ws methods
      [x] Implement other websocket options
      [x] Actually Write the Tests
- [ ] Caching?
- [ ] Compression? https://hono.dev/docs/middleware/builtin/compress
- [ ] Request timeout
- [ ] jwt
- [ ] csrf
- [ ] Rate limiting?
- [ ] Revamp body limit middleware. Don't just rely on content-length
- [ ] Remove native request dependency + Revamp Request
      Note: Make it easily testable
      [ ] fromIORequest()
      [ ] Use Size
- [ ] Revamp Response
      [ ] Memory leaks (specially in streams, sse and websocket)
- [ ] Context storage (req.getContext<Context>()) https://hono.dev/docs/middleware/builtin/context-storage
- [ ] Server timing https://hono.dev/docs/middleware/builtin/timing?
- [ ] Implement more advanced logger
- [ ] Revamp error handler middleware
- [ ] Multithreading support
- [ ] SSL support
- [ ] Benchmarks + Optimizations + Fuzz testing
- [ ] Support for RFC 9457 type https://datatracker.ietf.org/doc/html/rfc9457
- [ ] Comment documentations
- [ ] Templating support?
- [ ] Hot reload?
- [ ] Env parser?
- [ ] Implement router.on([.post, .get], (req) {})
- [ ] Think about if Agents are necessary for this project
- [ ] Rewrite the test code
- [ ] Write integration tests including websocket

## Lunart Future

- [ ] RPC
- [ ] Open API?
- [ ] Implement backpressure in websocket
- [ ] uWebsocket support

# Artiform

- [ ] Setup artiform orm library

# Eclipse

# Framework

[ ] Intertia support?
