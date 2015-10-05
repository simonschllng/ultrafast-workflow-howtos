# ## [Setting Up A JS App With Gulp and Browserify](https://quickleft.com/blog/setting-up-a-clientside-javascript-project-with-gulp-and-browserify/)
# 
# ...
#
# ## Building Assets
# 
# Next, let’s turn our attention to the rest of our build process. I like to use `less` for styling. We’ll need a `styles` task to compile it down to CSS. In the process, we’ll use [gulp-autoprefixer](https://www.npmjs.org/package/gulp-autoprefixer) so that we don’t have to write vendor prefixes in our CSS rules. As we did with the app, we’ll create a development copy and a build copy, and place them in `public/stylesheets` and `build`, respectively. We’ll also add the `less` directory to our `watch`, so changes to our styles will get picked up.
# 
# We should also uglify our JavaScript files to improve page load time. We’ll write tasks for minification and uglification, then copy the minified production versions of the files to `public/stylesheets` and `public/javascripts`. Finally, we’ll wrap it all up into a `build` task.
# 
# Here are the changes to the `gulpfile`:

cat >gulpfile.js <<EOL

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
...
EOL

# If we now run `gulp build`, we see the following files appear:  
# – `build/car-finder.css`  
# – `public/javascripts/car-finder.min.js`  
# – `public/stylesheets/car-finder.css`  
# – `public/stylesheets/car-finder.min.css`

gulp build

# ## Did It Work?
# 
# We’ll want to check that what we’ve built is actually going to work. Let’s add a little bit of styling and JS code to make sure it’s all getting compiled and served the way we hope it is. We’ll start with an `index.html` file in the `public` folder. It will load up the development versions of our CSS and JS files.

cat >public/index.html <<EOL
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
...
EOL

# We’ll add some styling in `client/less/index.less`:

cat >client/less/index.less <<EOL
body {
  background-color: DarkOliveGreen;
}
...
EOL

# Now we’ll write our million dollar app in `client/index.js`:

cat >client/index.js <<EOL
alert('I found your car!');
...
EOL

# Let’s put it all together. Run `grunt build`, then `open public/index.html`. Our default browser opens a beautiful olive green screen with an alert box. Profit!
# 
# 
# ## One Task To Rule Them All
# 
# At this point, I usually like to tie it all together with a `default` Gulp task, so all I have to do is run `gulp` to check that everything’s going together the way I expect, and start watching for changes. Since `test` already does the linting and browserifying, all we really need here is `test`, `build`, and `watch`.

cat >gulpfile.js <<EOL

gulp.task('default', ['test', 'build', 'watch']);
...
EOL

# ## Wrapping Up
# 
# We’ve now set up our project to use Browserify and Gulp. The former took the headache out of requiring modules and dependencies, and the latter made defining tasks for linting, testing, `less` compilation, minification, and uglification a breeze.
# 
# I hope you’ve found this exploration of Gulp and Browserify has been enlightening. I personally love these tools. For the moment, they’re my defaults when creating a personal project. I hope this post helps make your day-to-day development more fun by simplifying things. Thanks for reading!
# 
# P.S. What do you think? Going to make the switch from Grunt and/or Requirejs? Think these tools are inferior? Leave a comment below.
# 

