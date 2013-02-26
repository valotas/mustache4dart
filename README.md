Mustache for Dart
=================
A simple implementation of [mustache](http://mustache.github.com/) for the
[Dart language](http://www.dartlang.org/). At the moment this project serves
as an excuse to better explore the language. Although it is still in development you can have a look at what is capable of at the
[tests](https://github.com/valotas/mustache4dart/blob/master/test/mustache_tests.dart)

Running the tests
-----------------
At the moment the project is under heavy development. If you want to run the tests the
following commands should be enough

	git clone git://github.com/valotas/mustache4dart.git
	git submodule init
	git submodule update 
	pub install
	test/run.sh

At the moment mustache4dart can pass all interpolation, inverted and sections specs.

Build status
------------
[![Build Status](https://drone.io/github.com/valotas/mustache4dart/status.png)](https://drone.io/github.com/valotas/mustache4dart/latest)