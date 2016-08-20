NewsPlayer
===

[![Build Status](https://travis-ci.org/announce//NewsPlayer.svg?branch=master)](https://travis-ci.org/ymkjp/NewsPlayer)

## What's this?
This is a news player iOS App source code.

![iPhone4 Screenshot #1](https://dl.dropboxusercontent.com/u/6998388/NewsPlayer/3.5-inch%20%28iPhone%204%29%20-%20Screenshot%201.jpg)

## Requirement
- Xcode v7.3.x
- Ruby v2.x.x

## Setup
1. Get Google's API key
  1. Go to [console.developers.google.com](https://console.developers.google.com/project)
  1. Create Project > APIs & auth > Credentials > API key > iOS key
1. Run commands below

```bash
$ ruby --version  # e.g., ruby 2.1.5
$ gem install bundler && bundle install
$ bundle exec rake app:setup GOOGLE_API_KEY="__YOUR_AUTH_KEY__"
$ # Congrats. Now you are ready to run app!
$ open NewsPlayer.xcworkspace
```

## About the Rights of Another Party
Any of video contents in this app are played by YouTube's official iOS helper library which internally uses "Embeddable Player".

Refering to ["4. General Use of the Service" in YouTube's Terms of Service](https://www.youtube.com/static?template=terms&gl=US),
YouTube allows third parties to distribute their videos through functionality offered by their Service ("Embeddable Player" is one of those).

As regards news and media outlets' rights, copyright owners grant each user of YouTube a non-exclusive license to access their Content, and to use, reproduce, distribute, display and perform such Content.

For more details, refer to ["6. Your Content and Conduct" in YouTube's Terms of Service](https://www.youtube.com/static?template=terms&gl=US).

Please let [@i05](https://twitter.com/intent/tweet?text=%40i05%20%0A&hashtags=ZapApp) know if there are any unclear points.
