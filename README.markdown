GreenArrow Docker
=================

Provide the following build arguments to `docker build`:

* `GA_REPO_KEY` is the repo key provided to you by GreenArrow.
* `GA_VERSION` is the version number of GreenArrow you'd like to install. See [the GreenArrow Change Log](https://www.greenarrowemail.com/docs/greenarrow-engine/Change-Log/) for more information on version numbers.

For example:

```
docker build \
  --tag greenarrow:4.202.0 \
  --build-arg GA_REPO_KEY=abcdef123456 \
  --build-arg GA_VERSION=4.202.0 \
  .
```
