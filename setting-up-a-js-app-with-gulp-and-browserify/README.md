## [Setting Up A JS App With Gulp and Browserify](https://quickleft.com/blog/setting-up-a-clientside-javascript-project-with-gulp-and-browserify/)

For JavaScript developers, it can be hard to keep up to date with the latest frameworks and libraries. It seems like every day there’s a new _something_.js to check out. Luckily, there is one part of the toolchain that doesn’t change as often, and that’s the build process. That said, it’s worth checking out your options every now and then.

My build process toolset has traditionally been comprised of [RequireJS](http://requirejs.org/) for dependency loading, and [Grunt](http://gruntjs.com/). They’ve worked great, but recently I was pairing with someone who prefers to use [Gulp](http://gulpjs.com/) and [Browserify](http://browserify.org/) instead. After using them on a couple of projects, I’m coming to like them quite a bit. They’re great for use with Backbone, Angular, Ember, React, and my own hand-rolled JavaScript projects.

In this post, we’ll explore how to set up a clientside JavaScript project for success using Gulp and Browserify.


## Defining the Project Structure

For the purposes of this post, we’ll pretend we’re building an app called Car Finder, that helps you remember where you parked your car. If you want to follow along, check out the [code on GitHub](https://github.com/fluxusfrequency/car-finder).

When building a full application that includes both an API server and a clientside JavaScript app, there’s a certain project structure that I’ve found often works well for me. I like to put my clientside app in a folder one level down from the root of my project, called `client`. This folder usually has sibling folders named `server`, `test`, `public`, and `build`. Here’s how this would look for Car Finder:

    car-finder
    |- build
    |- client
       |- less
    |- public
       |- javascripts
       |- stylesheets
    |- server
    |- test

The idea is to do our app developent inside of `client`, then use a build task to compile the JS and copy it to the `build` folder, where it will be minified, uglified, and copied to `public` to be served by the backend.


## Pulling In Dependencies

To get up and running, we’ll need to pull in some dependencies.

Run `npm init` and follow the prompts.

Add `browserify`, `gulp`, and our build and testing dependencies:

    npm install --save-dev gulp gulp-browserify browserify-shim gulp-jshint gulp-mocha-phantomjs 
    gulp-rename gulp-uglify gulp-less gulp-autoprefixer gulp-minify-css mocha chai

If you’re using git, you may want to ignore your `node_modules` folder with `echo "node_modules" >> .gitignore`.


## Shimming Your Frameworks

You’ll probably want to use `browserify-shim` to shim jQuery and your JavaScript framework so that you can write `var $ = require('jquery')` into your code. We’ll use jQuery here, but the process is the same for any other library (Angular, Ember, Backbone, React, etc.). To set it up, modify your `package.json` like so:

    {
      "name": "car-finder",
      "author": "Ben Lewis",
      "devDependencies": {
        "gulp-rename": "^1.2.0",
        "gulp": "^3.8.10",
        "gulp-mocha-phantomjs": "^0.5.1",
        "gulp-jshint": "^1.9.0",
        "gulp-browserify": "^0.5.0",
        "browserify": "^6.3.4",
        "browserify-shim": "^3.8.0",
        "mocha": "^2.0.1",
        "gulp-minify-css": "^0.3.11",
        "gulp-uglify": "^1.0.1",
        "gulp-autoprefixer": "^2.0.0",
        "gulp-less": "^1.3.6",
        "chai": "^1.10.0"
      },
      "browserify-shim": {
        "jquery": "$"
      },
      "browserify": {
        "transform": [
          "browserify-shim"
        ]
      }
    }

If you’re getting JSHint errors in your editor for this file, you can turn them off with `echo "package.json" >> .jshintignore`.


## Setting Up Gulp

Now that we have the `gulp` package installed, we’ll configure `gulp` tasks to lint our code, test it, trigger the compilation process, and copy our minified JS into the `public` folder. We’ll also set up a `watch` task that we can use to trigger a lint and recompile of our project whenever a source file is changed.

We’ll start by requiring the `gulp` packages we want in a `gulpfile.js` that lives in the root of the project.

    // Gulp Dependencies
    var gulp = require('gulp');
    var rename = require('gulp-rename');

    // Build Dependencies
    var browserify = require('gulp-browserify');
    var uglify = require('gulp-uglify');

    // Style Dependencies
    var less = require('gulp-less');
    var prefix = require('gulp-autoprefixer');
    var minifyCSS = require('gulp-minify-css');

    // Development Dependencies
    var jshint = require('gulp-jshint');

    // Test Dependencies
    var mochaPhantomjs = require('gulp-mocha-phantomjs');

Now we can start defining some tasks.


### JSHint

To set up linting for our clientside code as well as our test code, we’ll add the following to the `gulpfile`:

    gulp.task('lint-client', function() {
      return gulp.src('./client/**/*.js')
        .pipe(jshint())
        .pipe(jshint.reporter('default'));
    });

    gulp.task('lint-test', function() {
      return gulp.src('./test/**/*.js')
        .pipe(jshint())
        .pipe(jshint.reporter('default'));
    });

We’ll also need to define a `.jshintrc` in the root of our project, so that JSHint will know which rules to apply. If you have a JSHint plugin turned on in your editor, it will show you any linting errors as well. I use [jshint.vim](https://github.com/wookiehangover/jshint.vim). Here’s an example of a typical `.jshintrc` for one of my projects. You’ll notice that it has some predefined globals that we’ll be using in our testing environment.

    {
      "camelcase": true,
      "curly": true,
      "eqeqeq": true,
      "expr" : true,
      "forin": true,
      "immed": true,
      "indent": 2,
      "latedef": "nofunc",
      "newcap": false,
      "noarg": true,
      "node": true,
      "nonbsp": true,
      "quotmark": "single",
      "undef": true,
      "unused": "vars",
      "trailing": true,
      "globals": {
        "after"      : false,
        "afterEach"  : false,
        "before"     : false,
        "beforeEach" : false,
        "context"    : false,
        "describe"   : false,
        "it"         : false,
        "window"     : false
      }
    }


### Mocha

I’m a Test-Driven Development junkie, so one of the first things I always do when setting up a project is to make sure I have a working testing framework. For clientside unit testing, I like to use [gulp-mocha-phantomjs](https://www.npmjs.org/package/gulp-mocha-phantomjs), which we already pulled in above.

Before we can run any tests, we’ll need to create a `test/client/index.html` file for Mocha to load up in the headless PhantomJS browser environment. It will pull Mocha in from our `node_modules` folder, require `build/client-test.js` (more on this in a minute), then run the scripts:

    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Mocha Test Runner</title>
        <link rel="stylesheet" href="../../node_modules/mocha/mocha.css">
      </head>
      <body>
        <div id="mocha"></div>
        <script src="../../node_modules/mocha/mocha.js"></script>
        <script>mocha.setup('bdd')</script>
        <script src="../../build/client-test.js"></script>
        <script>
          if (window.mochaPhantomJS) {
            mochaPhantomJS.run();
          } else {
            mocha.run();
          }
        </script>
      </body>
    </html>


## Setting Up Browserify

Now we need to set up Browserify to compile our code. First, we’ll define a couple of `gulp` tasks: one to build the app, and one to build the tests. We’ll copy the result of the compile to `public` so we can serve it unminified in development, and we’ll also put a copy into `build`, where we’ll grab it for minification. The compiled test file will also go into `build`. Finally, we’ll set up a `watch` task to trigger rebuilds of the app and test when one of the source files changes.

    gulp.task('browserify-client', ['lint-client'], function() {
      return gulp.src('client/index.js')
        .pipe(browserify({
          insertGlobals: true
        }))
        .pipe(rename('car-finder.js'))
        .pipe(gulp.dest('build'));
        .pipe(gulp.dest('public/javascripts'));
    });

    gulp.task('browserify-test', ['lint-test'], function() {
      return gulp.src('test/client/index.js')
        .pipe(browserify({
          insertGlobals: true
        }))
        .pipe(rename('client-test.js'))
        .pipe(gulp.dest('build'));
    });

    gulp.task('watch', function() {
      gulp.watch('client/**/*.js', ['browserify-client']);
      gulp.watch('test/client/**/*.js', ['browserify-test']);
    });

There’s one more thing we’ll need to do before we can run our `gulp` tasks, which is to make sure we actually have `index.js` files in each of the folders we’ve it to look at, so it doesn’t raise an error. Add one to the `client` and `test/client` folders.

Now, when we run `gulp browserify-client` from the command line, we see new `build/car-finder.js` and `public/javascripts/car-finder.js` files. In the same way, `gulp browserify-test` creates a `build/client-test.js` file.


## More Testing

Now that we have Browserify set up, we can finish getting our test environment up and running. Let’s define a `test` Gulp task and add it to our `watch`. We’ll add `browserify-test` as a dependency for the `test` task, so our `watch` will just require `test`. We should also update our watch to run the tests whenever we change any of the app _or_ test files.

    gulp.task('test', ['lint-test', 'browserify-test'], function() {
      return gulp.src('test/client/index.html')
        .pipe(mochaPhantomjs());
    });

    gulp.task('watch', function() {
      gulp.watch('client/**/*.js', ['browserify-client', 'test']);
      gulp.watch('test/client/**/*.js', ['test']);
    });

To verify that this is working, let’s write a simple test in `test/client/index.js`:

    var expect = require('chai').expect;

    describe('test setup', function() {
      it('should work', function() {
        expect(true).to.be.true;
      });
    });

Now, when we run `gulp test`, we should see Gulp run the `lint-test`, `browserify-test`, and `test` tasks and exit with one passing example. We can also test the `watch` task by running `gulp watch`, then making changes to `test/client/index.js` or `client/index.js`, which should trigger the tests.


## Building Assets

Next, let’s turn our attention to the rest of our build process. I like to use `less` for styling. We’ll need a `styles` task to compile it down to CSS. In the process, we’ll use [gulp-autoprefixer](https://www.npmjs.org/package/gulp-autoprefixer) so that we don’t have to write vendor prefixes in our CSS rules. As we did with the app, we’ll create a development copy and a build copy, and place them in `public/stylesheets` and `build`, respectively. We’ll also add the `less` directory to our `watch`, so changes to our styles will get picked up.

We should also uglify our JavaScript files to improve page load time. We’ll write tasks for minification and uglification, then copy the minified production versions of the files to `public/stylesheets` and `public/javascripts`. Finally, we’ll wrap it all up into a `build` task.

Here are the changes to the `gulpfile`:

    gulp.task('styles', function() {
      return gulp.src('client/less/index.less')
        .pipe(less())
        .pipe(prefix({ cascade: true }))
        .pipe(rename('car-finder.css'))
        .pipe(gulp.dest('build'))
        .pipe(gulp.dest('public/stylesheets'));
    });

    gulp.task('minify', ['styles'], function() {
      return gulp.src('build/car-finder.css')
        .pipe(minifyCSS())
        .pipe(rename('car-finder.min.css'))
        .pipe(gulp.dest('public/stylesheets'));
    });

    gulp.task('uglify', ['browserify-client'], function() {
      return gulp.src('build/car-finder.js')
        .pipe(uglify())
        .pipe(rename('car-finder.min.js'))
        .pipe(gulp.dest('public/javascripts'));
    });

    gulp.task('build', ['uglify', 'minify']);

If we now run `gulp build`, we see the following files appear:  
– `build/car-finder.css`  
– `public/javascripts/car-finder.min.js`  
– `public/stylesheets/car-finder.css`  
– `public/stylesheets/car-finder.min.css`


## Did It Work?

We’ll want to check that what we’ve built is actually going to work. Let’s add a little bit of styling and JS code to make sure it’s all getting compiled and served the way we hope it is. We’ll start with an `index.html` file in the `public` folder. It will load up the development versions of our CSS and JS files.

    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Car Finder</title>
        <link rel="stylesheet" href="stylesheets/car-finder.css">
      </head>
      <body>
        <script src="javascripts/car-finder.js"></script>
      </body>
    </html>

We’ll add some styling in `client/less/index.less`:

    body {
      background-color: DarkOliveGreen;
    }

Now we’ll write our million dollar app in `client/index.js`:

    alert('I found your car!');

Let’s put it all together. Run `grunt build`, then `open public/index.html`. Our default browser opens a beautiful olive green screen with an alert box. Profit!


## One Task To Rule Them All

At this point, I usually like to tie it all together with a `default` Gulp task, so all I have to do is run `gulp` to check that everything’s going together the way I expect, and start watching for changes. Since `test` already does the linting and browserifying, all we really need here is `test`, `build`, and `watch`.

    gulp.task('default', ['test', 'build', 'watch']);


## Wrapping Up

We’ve now set up our project to use Browserify and Gulp. The former took the headache out of requiring modules and dependencies, and the latter made defining tasks for linting, testing, `less` compilation, minification, and uglification a breeze.

I hope you’ve found this exploration of Gulp and Browserify has been enlightening. I personally love these tools. For the moment, they’re my defaults when creating a personal project. I hope this post helps make your day-to-day development more fun by simplifying things. Thanks for reading!

P.S. What do you think? Going to make the switch from Grunt and/or Requirejs? Think these tools are inferior? Leave a comment below.

