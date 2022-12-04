rm lambda_function.zip
bundle config set --local without 'test'
bundle install
cd source
zip -r lambda_function.zip *.rb
mv lambda_function.zip ..
cd ..
rm -rf .bundle
