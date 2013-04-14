Mustache for Dart [![Build Status](https://drone.io/github.com/valotas/mustache4dart/status.png)](https://drone.io/github.com/valotas/mustache4dart/latest)
===========================================================================================================================================================
A simple implementation of [Mustache][mustache] for the [Dart language][dartlang].
This project started as an excuse for exploring the language itself, but the 
final result, passes happily all the [mustache specs][specs]. If you want to 
have a look at how it works, just check the [tests][tests]. For more info, 
just read further.

Using it
--------
In order to use the library, just add it to your pubspec.yalm as a dependency

	dependencies:
	  mustache4dart: any

and you are good to go. You can use the render toplevel function to render your template.
For example:

	var salutation = render('Hello {{name}}!', {name: 'Bob'});
	print(salutation); //shoud print Hello Bob!
	
### Context objects
mustache4dart will look at your given object for operators, fields or methods. For example,
if you give the template `{{firstname}}` for rendering, mustache4dart will try the followings

1. use the `[]` operator with `firstname` as the parameter
2. search for a field named `firstname`
3. search for a getter named `firstname`
4. search for a method named `firstname`

in each case the first valid value will be used.

As a sidenote, you will get the best performance if you provide a proper implementation of
the [] operator.

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
	
Contributing
------------
If you found a bug, just create a [new issue][new_issue] or even better fork and issue a
pull request with you fix.

	
Versioning
----------
The library will follow a [semantic versioning][semver] and until a final release of the language will be 
followed by the latest dart language it has been tested against. For example 0.0.7+0.4.1.0 means that
the libraries version is 0.0.7 and has been tested against dart version 0.4.1.0

TODO
----
- Introduce mixins in order to simplify some parts of the code
- Make or add to the api an asynchronous mode

[mustache]: http://mustache.github.com/
[dartlang]: http://www.dartlang.org/
[tests]: http://github.com/valotas/mustache4dart/blob/master/test/mustache_tests.dart
[specs]: http://github.com/mustache/spec
[new_issue]: https://github.com/valotas/mustache4dart/issues/new
[semver]: http://semver.org/