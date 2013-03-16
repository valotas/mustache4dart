Mustache for Dart [![Build Status](https://drone.io/github.com/valotas/mustache4dart/status.png)](https://drone.io/github.com/valotas/mustache4dart/latest)
===========================================================================================================================================================
A simple implementation of [Mustache][mustache] for the [Dart language][dart]. 
At the moment this project serves as an excuse to better explore the language. 
Although it is still in development you can have a look at what is capable of 
at the [tests][tests]

Using it
--------
In order to use the library, just add it to your pubspec.yalm as a dependency

	dependencies:
	  mustache4dart: any

and you are good to go. You can use the render toplevel function to render your template.
For example:

	var salutation = render('Hello {{name}}!', {name: 'Bob'});
	print(salutation); //shoud print Hello Bob!
	
### Partials
mustache4dart support partials but it needs somehow to know how to find a partial. You can
do that by providing a function that returns a template given a name:

	String partialProvider(String partialName) => "this is the partial with name: ${partialName}";
	expect(render('[{{>p}}]', null, partial: partialProvider), '[this is the partial with name: p]'));

### Compiling to functions
If you have a template that you are going to reuse with different contextes you can compile
it to a function using the toplevel function compile:

	var salut = compile('Hello {{name}}!');
	print(salut('Alice')); //should print Hello Alice! 

Running the tests
-----------------
At the moment the project is under heavy development but pass all the [Mustache specs][specs]. 
If you want to run the tests yourself, the following commands should be enough

	git clone git://github.com/valotas/mustache4dart.git
	git submodule init
	git submodule update 
	pub install
	test/run.sh
	
Versioning
----------
The library will follow dart's versioning (x.x.x) and until a final release of the language will be 
followed by the latest dart language it has been tested against. For example 0.0.7+0.4.1.0 means that
the libraries version is 0.0.7 and has been tested against dart version 0.4.1.0
	
[mustache]: http://mustache.github.com/
[dart]: http://www.dartlang.org/
[tests]: http://github.com/valotas/mustache4dart/blob/master/test/mustache_tests.dart
[specs]: http://github.com/mustache/spec