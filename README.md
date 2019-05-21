# ActivestorageEx

This project was started with the intention of easing the transition between a Rails project and an Elixir one.

Since this is being created with our needs in mind, it'll start by only allowing reads and creating variations from the local file system and AWS S3. Direct uploads and other providers may come in future, but they aren't an immediate goal.

## TODO

- ~~Allow reading of originals from disk~~
- Allow reading of variants from disk
- Allow creation of variants from disk
- Allow reading of originals from s3
- Allow reading of variants from s3
- Allow creation of variants from s3
- Allow original uploads to disk (maybe)
- Allow original uploads to s3 (maybe)
- Improve testing situation between external Phoenix and Rails projects
- Turn endpoints into a phoenix plug
