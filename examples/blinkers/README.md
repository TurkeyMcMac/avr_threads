This is a basic example. Three threads are used, including the main thread. Each
thread blinks a port. The main thread blinks port B bit 3 four times quickly.
The next thread blinks port B bit 4 five times at a slower pace. The final
thread blinks port B bit 5 six times even slower. To run this example, connect
LEDs or something to the ports. Notice that everything gets faster as threads
finish, since the time is being shared between fewer threads.

To run the Makefile with this, run make like the following in the project root:

```
make ex=blinkers ...
```
