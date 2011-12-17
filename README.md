# Stsh

[<img src="https://github.com/jakedahn/stsh-client/blob/393e8b60c24caa539f1d576c3ba2b57a1f76ff80/resources/stacheicon.png?raw=true" />]

Take a screenshot in OS X and have a URL to the picture in your pasteboard a second later.

*A free and open source version of the different commercial variants (GrabUp, Tiny Grab, etc).*

For Mac OS X 10.6 Snow Leopard.

## Building

You'll need libpngcrush to build stsh-client. libpngcrush is an external submodule of stsh-client which you'll need to update after you've checked out the stsh-client source:

	cd stsh-client
	git submodule update --init pngcrush

You only need to do this once. Now, build Scrup in Xcode.


## Authors

- Rasmus Andersson <http://hunch.se/>
- Jake Dahn <http://stsh.me>
- Jesse Andrews <http://overstimulate.com>
- You - send me a pull request


## License

Open source licensed under MIT (see _LICENSE_ file for details).
