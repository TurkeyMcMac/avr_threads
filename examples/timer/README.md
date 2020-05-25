This is an example of blocking. The sleep timer keeps track of all sleeping
threads, which are blocked. When the time specified by `timer_sleep` runs out,
the sleeping thread is unblocked. Different port bits are turned on after one,
two, and three seconds.

To run the Makefile with this, run make like the following in the project root:

```
make ex=timer ...
```
