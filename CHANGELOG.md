## Unreleased

## 2.18.0 (March 12th, 2022)

IMPROVEMENTS:

* Minor build system updates have been made, including Rubocop linting.

## 2.17.0 (March 12th, 2022)

IMPROVEMENTS:

* The `Build` task now supports a `platform` parameter.
* The `Image` taskset now supports a `platform` parameter to pass on to `Build`.

## 0.16.0 (October 18th, 2018)

IMPROVEMENTS:

* The `All` and `Build` tasks now support `build_args` being passed as a hash.

## 0.11.0 (January 9th, 2018)

IMPROVEMENTS:

* If credentials are provided, the build task will now authenticate prior to
  building to allow images to be built with private base images.

## 0.10.0 (October 24th, 2017)

BACKWARDS INCOMPATIBILITIES / NOTES:

* The push and tag rake tasks now accept an `argument_names` parameter 
  providing names of the arguments passed to the task. These arguments are in 
  turn passed to any factory functions. Previously the factory functions took 
  the task parameters as the first argument, now they take the task arguments 
  as the first argument and the task parameters as the second.

IMPROVEMENTS:

* All factory functions now take the task arguments for the push and tag rake 
  tasks.
