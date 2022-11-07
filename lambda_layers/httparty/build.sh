rm -rf .bundle
rm -rf ruby
rm layer.zip
rm Gemfile.lock
docker run --rm -it -v $PWD:/var/gem_build -w /var/gem_build lambci/lambda:build-ruby2.7 bundle install --path=.
zip -r layer.zip ./ruby/ -x ./ruby/2.7.0/cache/\*
