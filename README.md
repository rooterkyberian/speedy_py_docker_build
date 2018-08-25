# speedy_py_docker_build

Python app dockerfile optimized for build time.

Example uses `pipenv`, which you probably should be using, but the same principles stand true for `requirements.txt`.

## Fixing the build caching

So your tyical Dockerfile for python app may look like [0-simple.Dockerfile](0-simple.Dockerfile).
And there is a problem with that. Every time ANYTHING in your repository is modified whole thing is being rebuilt.
That is including the dependency installation step, i.e. accessing external resources and maybe even compiling some stuff.
So basicilly all the time consuming stuff of your build.

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
Its not unusual to have a big app withhout any C extension complex enough for it to be a problem, but as soon as you do include `numpy` or something similar you are looking at extra 10+ minutes added to your build times.


Ok, but you still want to trim off some fat. In our, Python, case the easiest solution is to use `slim` version of Python docker image.
In [3-slim.Dockerfile](3-slim.Dockerfile), we are using `python:slim`, which is also Debian-based, but without extra bits.
