This example kind of serves as a test. It makes sure that up to
`AVRT_MAX_THREADS` threads can exist at a time, and that trying to allocate more
gives an error. If the test is successful, `PB4` is switched on. Otherwise,
`PB3` is switched on.

To run the Makefile with this, run make like the following in the project root:

```
make ex=resources ...
```
