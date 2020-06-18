# Warp Memory leak test

This tiny repo is intended to be useful for showing memory leaks in [Hyper]/[Warp].

## Motivation

In testing out my [Warp] application (private), I noticed a memory leak.  This 
lead me to look into [Hyper] and see [#1790], which sounds like it's been closed
because the issue has not been reproducable by the maintainers.  Hopefully,
this repository allows someone to reproduce the memory leak consistently.

[Warp]: https://github.com/seanmonstar/warp
[Hyper]: https://github.com/hyperium/hyper
[#1790]: https://github.com/hyperium/hyper/issues/1790

## Getting started

Assuming all of the prerequisites have been installed, from the top of the repo,
just run:

```shell
$ ./test-me.sh
```

### Environment variables

The following variables are used to control the application and benchmarking.

* `HOST` - the host name to use (default: 127.0.0.1)
* `PORT` - the port name to use (default: 3030)
* `DURATION` - the duration of the load test (default: 3 seconds)
* `WORKERS` - the number of simultaneous workers (default: 100)

These can be tweaked by adding a `.env` file in the root of the repository.

### Load Testing tool

The benchmark tool uses [Hey], though I suspect that any benchmarking tool could
be used.  More specifically, I noticed that this problem was relatively easy to
produce within a very short period of time (under 5 seconds), though it becomes
much more obvious over time.

For the mac, install was as simple as `brew install hey`.

[Hey]: https://github.com/rakyll/hey

## Environment setup

I have a 2015 mac running Macos 10.15.5.  I am using rustc 1.44.0 to produce the
results.  

I use [Tokio]'s ["full" feature] so that there's nothing missing 
(e.g. multithreading).

[Tokio]: https://github.com/tokio-rs/tokio
["full" feature]: https://github.com/tokio-rs/tokio/blob/master/tokio/Cargo.toml#L31-L48

## Interpreting numbers

For the following settings (.env):

```
TRIES=1
HOST=127.0.0.1
PORT=3030
DURATION=1s
WORKERS=1
```

Running `test-me.sh` yields something like:

```
----------------------------------------
Settings:
----------------------------------------
Iterating 1 times
Loading 127.0.0.1:3030
Running for 1s each iteration
Using 1 workers
----------------------------------------
Server running on PID: 72930
[Warp App] Serving on: 127.0.0.1:3030
===============================
Iteration: 1 of 1
-------------------------------
Requests/sec: 5895.6067
Latency (worst case): 0.0005 secs
-------------------------------
Starting memory: 2180 KB
Ending memory: 2644 KB
Memory leaked: 464 KB
===============================
```

In this case, we're seeing a 464 KB increase in RAM.  If we let this run for
100 iterations, some of them will appear to be 0.  We're using [ps] here, and
explicitly examining the [rss] (Resident Set Size) field.  Because of that, the 
numbers are in KB rather than B.  So the 0's being reported may actually be more 
than 0 B.

[ps]: https://man7.org/linux/man-pages/man1/ps.1.html
[rss]: https://linuxconfig.org/ps-output-difference-between-vsz-vs-rss-memory-usage
