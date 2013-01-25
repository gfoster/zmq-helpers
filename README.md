# Zmq::Helpers

A set of utility classes and helper methods for working with ZeroMQ listeners.

## Installation

Add this line to your application's Gemfile:

    gem 'zmq-helpers'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install zmq-helpers

## Usage

This gem helps abstract writing ZeroMQ listeners.  It will allow you
to easily create small listeners which can be attached to arbitrary
ZeroMQ buses, receive messages and respond to them.  The main class in
this gem provides a Zservice class which abstracts a multithreaded
listener.

Creating a listener service is as easy as instantiating a class,
defining a few methods, registering them and starting the service.
This will create a multithreaded listener which will automatically
respond to incoming messages and dispatch them appropriately in their
own service threads.

See the files in examples/ for detailed examples.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
