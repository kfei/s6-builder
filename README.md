# s6-builder

This repository is just for building a Docker image which builds
[s6](http://skarnet.org/software/s6/). Also a place to store the built binaries
so that I can easily add them to other images.

## Build

Build the Docker image:
```bash
git clone https://github.com/kfei/s6-builder
cd s6-builder
docker build -t s6-builder .
```

Use that image to build s6 and its dependencies:
```bash
docker run -it --rm -v $PWD/dist:/dist s6-builder
```
Once you have s6 compiled, copy that tarball
`dist/s6-${s6_version}-musl-static.tar.xz` to your image's repository.

## Usage

Use `ADD` instruction in Dockerfile to layer s6 binaries onto it, e.g.,
```bash
ADD s6-1.1.3.2-musl-static.tar /
```

Then you can set your image's entrypoint to s6:
```bash
ENTRYPOINT ["/usr/bin/s6-svscan", "/service"]
```
Where `/service` is the *service directory* for s6. 

For more examples, have a look at my
[docktorrent](https://github.com/kfei/docktorrent) repository.
