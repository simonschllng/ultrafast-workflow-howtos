# ## [Setting Up A JS App With Gulp and Browserify](https://quickleft.com/blog/setting-up-a-clientside-javascript-project-with-gulp-and-browserify/)
# 
# ...
#
# ## More Testing
# 
# Now that we have Browserify set up, we can finish getting our test environment up and running. Let’s define a `test` Gulp task and add it to our `watch`. We’ll add `browserify-test` as a dependency for the `test` task, so our `watch` will just require `test`. We should also update our watch to run the tests whenever we change any of the app _or_ test files.

cat >>gulpfile.js <<EOL

gulp.task('test', ['lint-test', 'browserify-test'], function() {
  return gulp.src('test/client/index.html')
    .pipe(mochaPhantomjs());
});

gulp.task('watch', function() {
  gulp.watch('client/**/*.js', ['browserify-client', 'test']);
  gulp.watch('test/client/**/*.js', ['test']);
});
EOL

# To verify that this is working, let’s write a simple test in `test/client/index.js`:

cat >test/client/index.js <<EOL
var expect = require('chai').expect;

describe('test setup', function() {
  it('should work', function() {
    expect(true).to.be.true;
  });
});
EOL

# Now, when we run `gulp test`, we should see Gulp run the `lint-test`, `browserify-test`, and `test` tasks and exit with one passing example. We can also test the `watch` task by running `gulp watch`, then making changes to `test/client/index.js` or `client/index.js`, which should trigger the tests.

gulp test

