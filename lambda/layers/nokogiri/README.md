# AWS Lambda Layer: Nokogiri

## Build

### Install Docker and gems

```
docker run --rm -it -v $PWD:/var/gem_build -w /var/gem_build lambci/lambda:build-ruby2.7 bundle install --path=.
```

### Package

```
zip -r nokogiri_layer.zip ./ruby/ -x ./ruby/2.7.0/cache/\*
```

### Add layer to lambda function

Use AWS web interface.

### Assign env var to lambda function

```
GEM_PATH = /opt/ruby/2.7.0
```
