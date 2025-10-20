# Changelog Natrium

## v8.4.0 (20-10-2025)
- !include

## v8.3.5 (21-03-2025)
- Fixed fatal error when creating temporary file

## v8.3.4 (17-03-2025)
- Only write plist when there are changes

## v8.3.2 (04-04-2024)
- Use natrium variables in arrays

## v8.3.1 (15-16-2023)
- Fixed #env

## v8.3.0 (08-03-2023)
- Added 'dry run'

## v8.2.0 (08-06-2022)
- Xcode14 universal app icons

## v8.1.1 (07-03-2022)
- Use type definition in .plist file parsers

## v8.1.0 (18-10-2021)
- [Issue 31](https://github.com/e-sites/Natrium/issues/31). Support yaml arrays

## v8.0.5 (18-06-2021)
- Fat binary

## v8.0.4 (11-06-2021)
- Removed Natrium.swift from Cocoapods sources

## v8.0.3 (03-03-2021)
- No variables would not create Natrium.swift

## v8.0.2 (02-03-2021)
- x86_64 build

## v8.0.1 (18-01-2021)
- Added `project_dir` argument to natrium cli

## v8.0.0 (18-01-2021)
- [Issue 29](https://github.com/e-sites/Natrium/issues/29). Support Swift Package Manager

## v7.3.0 (10-12-2020)
- Added `settings.stringType`

## v7.2.8 (07-12-2020)
- [Issue #30](https://github.com/e-sites/Natrium/issues/30). String variables should have `StaticString` type

## v7.2.7 (28-10-2020)
- Only use environment variables if a single argument is given

## v7.2.6 (28-10-2020)
- You can also copy directories when using the `files` directive

## v7.2.5 (15-05-2020)
- Fixed build / CommandLineKit

## v7.2.4 (31-01-2020)
- Fixed a bug that would not properly trim spaces within environment / configuration names

## v7.2.3 (22-01-2020)
- Fixed a bug where the logs were not cleared before running Natrium.

## v7.2.2 (29-11-2019)
- Minor improvements.

## v7.2.1 (28-11-2019)
- CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION

## v7.2.0 (27-11-2019)
- Be able to remove a key from a plist file
- Be able to add arrays to plist keys

## v7.1.1 (25-11-2019)
- Fixed rewrite of unchanged files. [Issue #27](https://github.com/e-sites/Natrium/pull/27). Thanks to [mpsnp](https://github.com/mpsnp)

## v7.1.0 (18-09-2019)
- Use `MARKETING_VERSION` for `launch_screen_versioning` where possible

## v7.0.3 (31-05-2019)
- Cocoapods v1.7.0 compatible

## v7.0.2 (21-05-2019)
- Fixed a bug in the shell execute helper

## v7.0.1 (02-05-2019)
- Fixed a bug where `launch_screen_versioning` would be required

## v7.0.0 (22-02-2019)
- Complete refactor
- Removed `natrium install`
- Updated to Swift 5.0

## v6.4.0 (06-02-2019)
- Make use of the `.natrium-env` file

## v6.3.4 (05-02-2019)
- Show the ENV variables in the natrium log

## v6.3.3 (16-01-2019)
- Fixed a bug in parsing `xcconfig` `target_specific` parameters

## v6.3.2 (11-01-2019)
- Fixed a bug where xcconfig parameters would not parse the natrium_variables correctly

## v6.3.1 (09-01-2019)
- CocoaPods abstract targets did not change xcconfig files

## v6.3.0 (04-01-2019)
- Make `target_specific` able to parse `natrium_variables`.

## v6.2.0 (26-12-2018)
- [PR #17](https://github.com/e-sites/Natrium/pull/17): Now actually using labelName in LaunchStoryboard versioning
- [PR #19](https://github.com/e-sites/Natrium/pull/19): Generate environment variable as Swift String

## v6.1.3 (13-12-2018)
- Version bump

## v6.1.2 (09-12-2018)
- Fixed 'Cannot change Bundle Identifier'. [Issue #13](https://github.com/e-sites/Natrium/issues/13).
- Autocreate not existing keys for `target_specific` purposes.

## v6.1.1 (06-11-2018)
- Fixed invalid "natrium.lock file is malformed, please rebuild" errors in `natrium install`

## v6.1.0 (31-10-2018)
- Added the `#env(KEY)` option to the `variables` list.

## v6.0.4 (31-10-2018)
- Fixed 'INFOPLIST_FILE path is not work'. [Issue #11](https://github.com/e-sites/Natrium/issues/11). `SRC_ROOT` and `PROJECT_DIR` are now parsed.

## v6.0.3 (22-10-2018)
- Make AppIcon.appiconset directory readable

## v6.0.2 (11-10-2018)
- Make AppIcon.appiconset Content.json structure the same as Xcode10
- Create appiconset directory if it doesn't exists

## v6.0.1 (03-09-2018)
- Fixed '"Config.swift" file not generate '. [Issue #8](https://github.com/e-sites/Natrium/issues/8).

## v6.0.0 (27-09-2018)
- Made available for Xcode 10's new build system

## v5.9.0 (19-09-2018)
- Updated to Swift 4.2 / Xcode10
- Changed `#error` handling
- Added `#error` type

## v5.8.2 (02-09-2018)
- Resolved #7 ("Config.swift" file not generate)

## v5.8.1 (20-07-2018)
- Fixed a bug that would not write to `Config.swift`

## v5.8.0 (13-07-2018)
- Implemented Francium for file system operations

## v5.7.2 (10-07-2018)
- Only update icon assets if the original icon is updated.

## v5.7.1 (09-07-2018)
- Fixed 'Bool and Int values are not overridden per target'. [Issue #4](https://github.com/e-sites/Natrium/issues/4).

## v5.7.0 (04-07-2018)
- A seperate `NatriumConfig` objective-c file is generated.

## v5.6.1 (03-07-2018)
- Fixed a bug where target specific plist settings would not parse. [Issue #3](https://github.com/e-sites/Natrium/issues/3)

## v5.6.0 (19-12-2017)
- Added carthage support

## v5.5.0 (13-12-2017)
- Manual installation, without CocoaPods
- Removed `update_podfile` setting
- Added `class_name` setting (for manual installation)

## v5.4.1 (17-11-2017)
- Non-breaking linespaces in logging

## v5.4.0 (17-11-2017)
- Added a `objective-c` setting. To use Natrium in objective-c classes.

## v5.3.6 (17-11-2017)
- Fixed a bug where a XcodeEdit dictionary would not parse to `[String: String]`. Changed it to `[String: Any]`

## v5.3.5 (08-11-2017)
- Fixed a bug when using spaces in file paths in the `plists` directive
- Added `line_length` swiftlint ignore in Config.swift

## v5.3.4 (07-11-2017)
- Fixed a bug when scaling the app-icon 

## v5.3.3 (06-11-2017)
- Fixed a bug where Natrium would use the .lock file incorectly

## v5.3.2 (03-11-2017)
- Fixed a bug in the `launch_screen_versioning` parser for launchscreens with multiple labels

## v5.3.1 (02-11-2017)
- Fixed a bug when app icon images are not 1024x1024
- Fixed a bug conserning the lock file
- Set the xcconfig include path to an absolute path instead of relative

## v5.3.0 (26-10-2017)
- Added unit tests
- natrium.log output

## v5.2.1 (26-10-2017)
- Fixed a bug in the `Config.swift` creation

## v5.2.0 (26-10-2017)
- `Package.swift`

## v5.1 (24-10-2017)
- `no_timestamp` argument

## v5.0 (23-10-2017)
- Converted it into a swift script instead of ruby

## v4.1 (09-10-2017)
- Allow `"*"` as environment to match all the environments
- Made `Config.swift` (default) swiftlint valid

## v4.0.1 (09-10-2017)
- Fixed a bug when the `appicon.original` could not be found

## v4.0 (23-08-2017)
- Xcode9 and swift4 compatible

## v3.0 (27-06-2017)
- Added `idioms` to the `appicon` configuration
- Renamed `build-config.yml` to `.natrium.yml`

## v2.3 (20-03-2017)
- Add the [Natrium] build phase automatically

## v2.2.3 (10-03-2017)
- Get app version beforehand

## v2.2.2 (28-11-2016)
- Better swift version check

## v2.2.1 (18-10-2016)
- Prepend "v" for version in `launchScreenStoryboard`

## v2.2 (07-10-2016)
- Added `misc` and `launchScreenStoryboard` 

## v2.1.3 (28-09-2016)
- bash script alteration

## v2.1.2 (26-09-2016)
- ruby location

## v2.1.1 (23-09-2016)
- Improved logging

## v2.1 (20-09-2016)
- Automatically detect swift2.2, swift2.3 or swift3.0
- Removed `legacy` input for `app_ribbon`

## v2.0.2 (02-09-2016)
- Use proper asset filenames (@2x, @3x)

## v2.0.1 (01-09-2016)
- Minor bug fixes

## v2.0.0 (30-08-2016)
- Changed the way xcconfig files are generated

## v1.7.5 (30-08-2016)
- Added `configuration` default variable to `Config.swift`

## v1.7.4 (23-08-2016)
- Added backwards compatibility for ruby 2.0
- Added `legacy` handler for `appicon` variable

## v1.7.3 (22-08-2016)
- Improved app ribbon creation

## v1.7.2 (12-08-2016)
- Extra logging for `xcconfig` variables

## v1.7.1 (10-08-2016)
- Fixed small `natrium_variables` bug

## v1.7 (10-08-2016)
- Xcconfig variables per configuration

## v1.6.2 (04-08-2016)
- Allow editing entitlements files

## v1.6.1 (28-07-2016)
- Example bug fix

## v1.6 (28-07-2016)
- Added `natrium_variables`

## v1.5.1 (25-07-2016)
- `Imagemagick` for ribbon creation is optional. Does not throw an error

## v1.5 (21-07-2016)
- Added `target_specific` values

## v1.4.1 (15-07-2016)
- Fixed a bug where paths contaning a space would throw an shell error

## v1.4 (04-07-2016)
- Added support to alter other plist files then the `Info.plist`

## v1.3.3 (04-07-2016)
- Fixed `files` directive

## v1.3.2 (04-07-2016)
- Extra error checking when parsing .yml file

## v1.3.1 (15-06-2016)
- Increased ribbon font size

## v1.3 (15-06-2016)
- Added `appicon` directive

## v1.2 (09-06-2016)
- Added `files` directive

## v1.1 (12-05-2016)
- Easier setup with CocoaPods
- Multiple platforms (iOS / OSX)

## v1.0 (11-05-2016)
- Initial release
