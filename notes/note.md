## Dogma

- lean and extensible core
- feature reach framework

## Brief

- There will separate packages for each thing
    - Lunart 'lunart' the core
    - Lunart Framework 'lunart_framework' the framework
    - Lunart Express 'lunart_express' orm
    - Lunart Cli - the cli that scaffolds the project
    - Lunart env

# Plugin vs Middleware

## Plugin

A plugin is more of an extension to the server that adds capabilities to the server. It has the ability to add routes, middlewares and even other plugin.

## Middleware

A Middleware just sits in the request/response cycle. It has the capability to modify, validate and reject request outright.
