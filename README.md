# BXSwiftUtils
![lines of code](https://tokei.rs/b1/github/boinx/bxswiftutils?category=code) ![comments](https://tokei.rs/b1/github/boinx/bxswiftutils?category=comments)

Swift Extensions and Classes written by Boinx Software Ltd. & IMAGINE GbR

This framework/package provides many useful classes, extensions, or utils that where written purely in Swift. Documentation is currently not available, so check the source code comments.

Feel free to browse the [BXSwiftUtils](BXSwiftUtils) directory.
Also, check our [Styleguide](STYLEGUIDE.md).

## Continuous Integration
Since this project will be embedded in most (if not all) of our products, we want to make sure that it always compiles and functions as expected.
Therefore, [travis-ci](https://travis-ci.org/boinx/BXSwiftUtils) will build every commit and run the tests on both macOS and iOS.
Afterwards, a slack notification will be sent to the `#dev` channel.

The process is described in [ `.travis.yml`](.travis.yml).
Setting the Xcode version also implies a certain macOS and iOS version (This information can be found in the [Travis CI Guides](https://docs.travis-ci.com/user/reference/osx/#Xcode-version)).
When changing the Xcode version, keep in mind to also update the build destination versions, or the build will fail.
