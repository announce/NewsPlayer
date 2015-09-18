NewsPlayer
===

## Requirement
- Xcode v7.0
- Ruby v2.1.x

## Setup
1. Get Google's API key
  1. Go to [console.developers.google.com](https://console.developers.google.com/project)
  1. Create Project > APIs & auth > Credentials > API key > iOS key
1. Run commands below

```bash
$ ruby --version  # ruby 2.1.5 is preferred
$ gem install bundler && bundle install
$ bundle exec rake app:setup GOOGLE_API_KEY="__YOUR_AUTH_KEY__"
$ # Congrats. Now you are ready to run app!
$ open NewsPlayer.xcworkspace
```
