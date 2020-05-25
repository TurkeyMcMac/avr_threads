# AVR Threads

AVR microcontrollers have timers which can fire interrupts at intervals. This
mechanism can be used to implement preemptive multitasking (no explicit context
switches needed) for the AVR. There is an overall speed penalty due to context
switching because AVR microcontrollers do not have multiple cores. I do not see
a practical use for this, but I think it's interesting.

## Platform support

This is written in assembly because of its low-level nature. I know it works on
an ATmega328P, but not much beyond that. The instructions `adiw`,
`ldd Z+q, ...`, `movw`, and `mul` are required, among others.

## Building

AVR GCC and AVR binutils are required. avrdude is needed to upload the example.

To make the static library:

```
make libavrt.a
```

To make the example:

```
make example.hex
```

To upload the example:

```
make upload
```

You might need to set `port=...` if the board is not connected to
`/dev/ttyUSB0`. For example, if the board is on `/dev/ttyUSB1`, use
`make port=/dev/ttyUSB1 ...`.

## Examples

Examples are in the `examples` directory. Read more about each example in its
directory.

## Testing

The only test right now are the examples. I might add more later.
