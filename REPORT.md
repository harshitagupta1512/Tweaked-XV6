## Scheduling in XV6

We run the schedulertest.c file using the command  `time schedulertest` for different scheduling policies - RR, FCFS, PBS, MLFQ.

### Performance Analysis

#### Round Robin
Average running time = 110
Average waiting time = 10

#### First Come First Serve
Average running time = 38
Average waiting time = 32

#### Priority Based Scheduling
Average running time = 110
Average waiting time = 25

#### Multi-level Feedback Queue Scheduling
Average running time = -
Average waiting time = -

### Possible Exploitation of MLFQ Policy by a Process
If a process voluntarily relinquishes control of the CPU, it leaves the queuing network, and when the process becomes ready again after the I/O, it is inserted at the tail of the same queue, from which it is relinquished earlier.

This can be exploited as just when the time-slice is about to expire, the process can voluntarily relinquish control of the CPU, and get inserted in the same queue again. 
If it ran as normal, then due to time-slice getting expired, it would have been put into a lower priority queue. The process, after completing the I/O will remain in the higher priority queue, so
that it can run again soon and with a larger time slice.
