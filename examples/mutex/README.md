This is an implementation of mutexes. In the example, access to output ports is
exclusive. Each thread locks the mutex, switches some ports on, waits, switches
the ports back off, and unlocks the mutex. Each thread repeats this forever. You
will probably see a consistent pattern because the mutex is fair.

To run the Makefile with this, run make like the following in the project root:

```
make ex=mutex CFLAGS='-DMUTEX_QUEUE_SIZE=...' ...
```

If the `MUTEX_QUEUE_SIZE` flag is unspecified, the program will still work fine.
Specifying a low number might make the mutex less fair.
