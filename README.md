# speedy_py_docker_build

Python app dockerfile optimized for build time.

Example uses `pipenv`, which you probably should be using, but the same principles stand true for `requirements.txt`.

## Fixing the build caching

So your typical Dockerfile for python app may look like [0-simple.Dockerfile](0-simple.Dockerfile).
And there is a problem with that. Every time ANYTHING in your repository is modified whole thing is being rebuilt.
That is including the dependency installation step, i.e. accessing external resources and maybe even compiling some stuff.
So basically all the time consuming stuff of your build.

[1-cached.Dockerfile](1-cached.Dockerfile) is a fixed version.

The difference is that instead:
1) COPY whole source to image
2) RUN install dependencies

we do:this: 
1) COPY dependencies lock file to image
2) RUN install dependencies 
3) COPY whole source to image

and thanks to build cache the 1 and 2 step can be cached as long as dependencies lock file has not been updated.
The source code changes (basically any file change) of course invalidates cache for step 3, but the COPY operation is super fast relatively.

In approach from [0-simple.Dockerfile](0-simple.Dockerfile), even single file cache would invalidate cache at step 1 making us redo the whole build.

## Smaller image

Ok, so this really shouldn't be an issue and won't save you as much time UNLESS your are deploying to hundreds of machines or sth.
But still, every now and then come a guy (or gal) and says "LIGHT IS BETTER", and proposes `alpine`.

[2-alpine.Dockerfile](2-alpine.Dockerfile) is a purposely skewed example of python app docker image based on alpine.

So how is it skewed?
Well, have you tried building it? Unless cached, it will take MUCH longer than when using the debian-based image.

As to why this is the case: if you look into `Pipfile` you will find `pandas` library in there.
The thing about `pandas` and `numpy` (its dependency) is that is a C extension, i.e. it has to be compiled.
In case of glibc-based debian system you can install the already precompiled version (wheel) directly from PyPI.
Wheel format does not support `musl`-based distros, such as Alpine (https://github.com/pypa/manylinux/issues/37).
So, on Alpine we have to compile every C extension.
Its not unusual to have a big app without any C extension complex enough for it to be a problem, but as soon as you do include `numpy` or something similar you are looking at extra 10+ minutes added to your build times.


Ok, but you still want to trim off some fat. In our, Python, case the easiest solution is to use `slim` version of Python docker image.
In [3-slim.Dockerfile](3-slim.Dockerfile), we are using `python:slim`, which is also Debian-based, but without extra bits.

## .dockerignore

Especially if you `COPY` the root directory of your project you will want to use the [`.dockerignore`](https://docs.docker.com/engine/reference/builder/#dockerignore-file).
Not only it will prevent from junk getting into your final image, it will prevent it from poisoning the build cache.

## Including development dependencies

In most cases you want (or should want) to test every image.
For that you need not only base dependencies of the project, but test (development) dependencies as well.

In such case you have two ways to deal with it:
1. use the same image with all dependencies installed for testing as well as production and have a single Dockerfile for it
2. build a separate image based on the one used in production, but with additional stuff installed

The PROS & CONS of these approches have been discussed here: https://stackoverflow.com/questions/52364220/pros-and-cons-of-splitting-development-dependencies

Going with the easy route 1. means that you just need to replace `pipenv install --system --deploy` with `pipenv install --system --deploy --dev`.
No additional slowdown between builds if only code source files were changed.

Choosing solution no. 2 you have to define a second dockerfile that will either:
 * be slightly changed copy&pasted of the first one (just like in first solution), or
 * derived using `FROM`, with just `pipenv install --system --deploy --dev`

and the last option means that no matter which file changes, the `pipenv install --system --deploy --dev` will have to be run.

The more refined than "copy&pasting" Dockerfile is to use [`ARG`](https://docs.docker.com/engine/reference/builder/#arg) instruction.
This way you will have a single Dockerfile to maintain.
Example of such file can be found in [4-slim-dev.Dockerfile](4-slim-dev.Dockerfile).
You can run `docker build -f 4-slim-dev.Dockerfile . --build-arg DEV=true` to get development image, or `docker build -f 4-slim-dev.Dockerfile .` for production one (note the same Dockerfile is used).
