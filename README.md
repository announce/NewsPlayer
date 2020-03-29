NewsPlayer
===

[![Build Status](https://travis-ci.org/announce/NewsPlayer.svg?branch=master)](https://travis-ci.org/announce/NewsPlayer)

## What's this?
This is a source code repository of [‎Newsline on the App Store](https://apps.apple.com/app/id1046346302).

## Requirement
- Xcode v10.3.x
- Ruby v2.x.x

## Setup
1. Get Google's API key
  1. Go to [console.developers.google.com](https://console.developers.google.com/apis/credentials?project=newsplayer-1064)
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
Any of video contents in this app are played by [YouTube's official iOS helper library](https://github.com/youtube/youtube-ios-player-helper/tree/0.1.4) which internally uses "Embeddable Player".

Refering to ["4. General Use of the Service" in YouTube's Terms of Service](https://www.youtube.com/static?template=terms&gl=US),
YouTube allows third parties to distribute their videos through functionality offered by their Service ("Embeddable Player" is one of those).

As regards news and media outlets' rights, copyright owners grant each user of YouTube a non-exclusive license to access their Content, and to use, reproduce, distribute, display and perform such Content.

For more details, refer to ["6. Your Content and Conduct" in YouTube's Terms of Service](https://www.youtube.com/static?template=terms&gl=US).

Please let [@i05](https://twitter.com/intent/tweet?text=%40i05%20%0A&hashtags=ZapApp) know if there are any unclear points.
