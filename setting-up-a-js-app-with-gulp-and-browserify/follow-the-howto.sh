# ## [Setting Up A JS App With Gulp and Browserify](https://quickleft.com/blog/setting-up-a-clientside-javascript-project-with-gulp-and-browserify/)
# 
# For JavaScript developers, it can be hard to keep up to date with the latest frameworks and libraries. It seems like every day there’s a new _something_.js to check out. Luckily, there is one part of the toolchain that doesn’t change as often, and that’s the build process. That said, it’s worth checking out your options every now and then.
# 
# My build process toolset has traditionally been comprised of [RequireJS](http://requirejs.org/) for dependency loading, and [Grunt](http://gruntjs.com/). They’ve worked great, but recently I was pairing with someone who prefers to use [Gulp](http://gulpjs.com/) and [Browserify](http://browserify.org/) instead. After using them on a couple of projects, I’m coming to like them quite a bit. They’re great for use with Backbone, Angular, Ember, React, and my own hand-rolled JavaScript projects.
# 
# In this post, we’ll explore how to set up a clientside JavaScript project for success using Gulp and Browserify.
# 
# 
## Defining the Project Structure
#
# For the purposes of this post, we’ll pretend we’re building an app called Car Finder, that helps you remember where you parked your car. If you want to follow along, check out the [code on GitHub](https://github.com/fluxusfrequency/car-finder).
#
# When building a full application that includes both an API server and a clientside JavaScript app, there’s a certain project structure that I’ve found often works well for me. I like to put my clientside app in a folder one level down from the root of my project, called `client`. This folder usually has sibling folders named `server`, `test`, `public`, and `build`. Here’s how this would look for Car Finder:
# 

echo "Enter project name:"
read projectname
mkdir $projectname
cd !$

mkdir build
mkdir client
mkdir client/less
mkdir public
mkdir public/js
mkdir public/css
mkdir server
mkdir test

# The idea is to do our app developent inside of `client`, then use a build task to compile the JS and copy it to the `build` folder, where it will be minified, uglified, and copied to `public` to be served by the backend.
# 
# 
# ## Pulling In Dependencies
# 
# To get up and running, we’ll need to pull in some dependencies.
# 
# Run `npm init` and follow the prompts.

echo "Initializing npm project..."
npm init

# Add `browserify`, `gulp`, and our build and testing dependencies:

npm install --save-dev gulp gulp-browserify browserify-shim gulp-jshint gulp-mocha-phantomjs gulp-rename gulp-uglify gulp-less gulp-autoprefixer gulp-minify-css mocha chai

# If you’re using git, you may want to ignore your `node_modules` folder with `echo "node_modules" >> .gitignore`.

echo "node_modules" >> .gitignore
git init
git add .

# ## Shimming Your Frameworks
# 
# You’ll probably want to use `browserify-shim` to shim jQuery and your JavaScript framework so that you can write `var $ = require('jquery')` into your code. We’ll use jQuery here, but the process is the same for any other library (Angular, Ember, Backbone, React, etc.). To set it up, modify your `package.json` like so:

cat >add-to-package.json <<EOL
{
  "browserify-shim": {
    "jquery": "$"
  },
  "browserify": {
    "transform": [
      "browserify-shim"
    ]
  }
}
EOL

# If you’re getting JSHint errors in your editor for this file, you can turn them off with `echo "package.json" >> .jshintignore`.

echo "package.json" >> .jshintignore
git add .jshintignore

# ## Setting Up Gulp
# 
# Now that we have the `gulp` package installed, we’ll configure `gulp` tasks to lint our code, test it, trigger the compilation process, and copy our minified JS into the `public` folder. We’ll also set up a `watch` task that we can use to trigger a lint and recompile of our project whenever a source file is changed.
# 
# We’ll start by requiring the `gulp` packages we want in a `gulpfile.js` that lives in the root of the project.

cat >gulpfile.js <<EOL
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
EOL

git add gulpfile.js

# Now we can start defining some tasks.
# 
# 
# ### JSHint
# 
# To set up linting for our clientside code as well as our test code, we’ll add the following to the `gulpfile`:
# 

cat >>gulpfile.js <<EOL

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
EOL

# We’ll also need to define a `.jshintrc` in the root of our project, so that JSHint will know which rules to apply. If you have a JSHint plugin turned on in your editor, it will show you any linting errors as well. I use [jshint.vim](https://github.com/wookiehangover/jshint.vim). Here’s an example of a typical `.jshintrc` for one of my projects. You’ll notice that it has some predefined globals that we’ll be using in our testing environment.

cat >.jshintrc <<EOL
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
EOL

git add .jshintrc

# ### Mocha
# 
# I’m a Test-Driven Development junkie, so one of the first things I always do when setting up a project is to make sure I have a working testing framework. For clientside unit testing, I like to use [gulp-mocha-phantomjs](https://www.npmjs.org/package/gulp-mocha-phantomjs), which we already pulled in above.

# Before we can run any tests, we’ll need to create a `test/client/index.html` file for Mocha to load up in the headless PhantomJS browser environment. It will pull Mocha in from our `node_modules` folder, require `build/client-test.js` (more on this in a minute), then run the scripts:

mkdir -p test/client
cat >test/client/index.html <<EOL
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
EOL

git add test/client/index.html

exit;

# ## Setting Up Browserify
# 
# Now we need to set up Browserify to compile our code. First, we’ll define a couple of `gulp` tasks: one to build the app, and one to build the tests. We’ll copy the result of the compile to `public` so we can serve it unminified in development, and we’ll also put a copy into `build`, where we’ll grab it for minification. The compiled test file will also go into `build`. Finally, we’ll set up a `watch` task to trigger rebuilds of the app and test when one of the source files changes.

cat >>gulpfile.js <<EOL

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
EOL

# There’s one more thing we’ll need to do before we can run our `gulp` tasks, which is to make sure we actually have `index.js` files in each of the folders we’ve it to look at, so it doesn’t raise an error. Add one to the `client` and `test/client` folders.

touch client/index.js
touch test/client/index.js

# Now, when we run `gulp browserify-client` from the command line, we see new `build/car-finder.js` and `public/javascripts/car-finder.js` files. In the same way, `gulp browserify-test` creates a `build/client-test.js` file.

gulp browserify-client
gulp browserify-test

echo "\n"
echo "The first part of this workflow is done. Your further options are:\n";
echo " * more-testing.sh\n"
echo " * building-assets.sh\n"

