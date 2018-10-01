# SubEtha Code

General Purpose Plain-Text Editor for macOS. Direct descendant from Hydra and SubEthaEdit. Widely known for its live Collaboration feature.

https://github.com/LoneMonkeyProductions/SubEthaCode is the main development repo.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Development is done on most recent macOS and you are expected to have a apple developer account.

* Clone the repo, and switch to the develop branch
* Initialise the submodules by

```bash
git submodule update --init
```
* Edit the `BuildConfig/Identity.xcconfig` with your team ID, Product Name and CFBundleIdentifier base. You can use `security find-identity -v` to find out your Team ID.
* [optional] tell git to ignore those changes to get out of your way by `git update-index --skip-worktree BuildConfig/Identity.xcconfig`

You should be all set to open up the shared workspace at `SubEthaEdit.xcworkspace` and build the app.

## Contributing

Please read [contributing](Contributing.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Active contributors

* Dominik [@monkeydom](https://mastodon.technology/@monkeydom) Wagner - [GitHub](https://github.com/monkeydom) [Mastodon](https://mastodon.technology/@monkeydom) [Twitter](https://twitter.com/monkeydom) [Blog](https://coding.monkeydom.de/)

Project email: subetha-code at lone.monkey.productions

See the full list of [contributors](Contributors.md).

## License

This project is distributed under the MIT License - see the [LICENSE.txt](LICENSE.txt) file for details

* **SubEtha Code** and the App Icon is trademarked by LoneMonkeyProductions.
* **SubEthaEdit** is trademarked by TheCodingMonkeys.

## Acknowledgments

* Thanks to the Xerox Parc Jupiter Project for [Transactional Transformations](https://www.semanticscholar.org/paper/High-Latency%2C-Low-Bandwidth-Windowing-in-the-System-Nichols-Curtis/369c52d8214b73a86b1e3f31d287823ea91884d6).
* Thanks to the [MiniUPnP](http://miniupnp.free.fr) project.
* For a full list of licenses and Acknowlegdements see [acknowledgements](Acknowledgements.md)
