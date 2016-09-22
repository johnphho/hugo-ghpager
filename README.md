##hugo-ghpager is a hugo static site automator

- built github ghpages
- automated using circleci
- copy your config.toml
- fill your github username and email and repo names (use *.github.io)
- fill in your github access key and your circleci access key
- just run `./hugo-ghpager.sh --create` and you are all set
- to delete whatever you have created just run `./hugo-ghpager.sh --delete` 

####TODO
- dockerize (add github ssh keys and live edit)
- delete ssh keys from github and circleci (so we don't duplicates sitting around in case we want to start from stratch again)
- bulk add posts (in case we want to start from stratch and re-add our posts)
- timing issues when delete and recreating repos
- lastly a UI to do this in order to support multiple projects ghpages
