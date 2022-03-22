
# Assignment 4 - Modified XV6-RISCV
----
## Run the shell
>Run the command `make && make qemu`
>Add the flag SCHEDULER to choose between RR, FCFS, PBS and MLFQ.

## Specification 1: SYSCALL TRACING
> We add a new system call `trace` and an accompanying user program `strace`.\
> It intercepts and records the system calls which are called by a process during its execution.\ 
> It takes one argument, an integer mask, whose bits specify which system calls to trace.\
> Process ID | name of the system call | decimal value of the arguments | return value of the syscall

### CHANGES
### Makefile
Add `$U/_strace\` to `UPROGS`

### proc.h
Add `int mask;` in `struct proc`

### proc.c
Modified `int fork(void)`to create a new process and inherit the mask value of the parent process.\
`np->mask = p->mask;`

### sysproc.c
Add the *handler* for `trace` system call.

````cpp
uint64 sys_trace(void)
{
  //handler
  int mask = 0;
  if (argint(0, &mask) < 0)
    return -1;
  myproc()->mask = mask;
  return 0;
}
```` 
`argint` helps to retrieve system call arguments from user space.


### syscall.c

Add\
`extern uint64 sys_trace(void);`

`[SYS_trace] sys_trace,`

```cpp
// array of syscall names to index into
char *syscall_list[] = {
    "",
    "fork",
    "exit",
    "wait",
    "pipe",
    "read",
    "kill",
    "exec",
    "fstat",
    "chdir",
    "dup",
    "getpid",
    "sbrk",
    "sleep",
    "uptime",
    "open",
    "write",
    "mknod",
    "unlink",
    "link",
    "mkdir",
    "close",
    "trace",
};
int syscall_arg_count[] = {
    [SYS_fork] 0,
    [SYS_exit] 1,
    [SYS_wait] 1,
    [SYS_pipe] 0,
    [SYS_read] 3,
    [SYS_kill] 2,
    [SYS_exec] 2,
    [SYS_fstat] 1,
    [SYS_chdir] 1,
    [SYS_dup] 1,
    [SYS_getpid] 0,
    [SYS_sbrk] 1,
    [SYS_sleep] 1,
    [SYS_uptime] 0,
    [SYS_open] 2,
    [SYS_write] 3,
    [SYS_mknod] 3,
    [SYS_unlink] 1,
    [SYS_link] 2,
    [SYS_mkdir] 1,
    [SYS_close] 1,
    [SYS_trace] 1,
};
````

MODIFY `void syscall(void)` to print the trace output

```c
void syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
  {
    // get the return value from the syscall
    int register0 = p->trapframe->a0;
    int register1 = p->trapframe->a1;
    int register2 = p->trapframe->a2;
    int register3 = p->trapframe->a3;
    int register4 = p->trapframe->a4;
    p->trapframe->a0 = syscalls[num]();
    
    if (p->mask >> num & 0x1)
    {
      printf("%d: syscall %s ( ", p->pid, syscall_list[num]);
      for (int i = 0; i < syscall_arg_count[num]; i++)
      {
        if (i == 0)
          printf("%d ", register0);
        else if (i == 1)
          printf("%d ", register1);
        else if (i == 2)
          printf("%d ", register2);
        else if (i == 3)
          printf("%d ", register3);
        else if (i == 4)
          printf("%d ", register4);
      }
      printf(") -> %d\n", p->trapframe->a0);
    }
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}

````


### syscall.h
Add `#define SYS_trace 22`

### user.h
Add `int trace(int);`

### usys.pl
Add `entry("trace");`

### strace.c
Create a new file in `users`
```cpp
#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int i;
    char *new_arguments[MAXARG];

    int is_valid_num = (argv[1][0] < '0' || argv[1][0] > '9');
    int valid_num_args = argc >= 3;
    if (!valid_num_args || is_valid_num)
    {
        fprintf(2, "Usage: %s <mask> <command>\n", argv[0]);
        exit(1);
    }
    if (trace(atoi(argv[1])) < 0)
    {
        fprintf(2, "%s: strace failed\n", argv[0]);
        exit(1);
    }

    for (i = 2; i < argc && i < MAXARG; i++)
    {
        new_arguments[i - 2] = argv[i];
    }
    exec(new_arguments[0], new_arguments);
    exit(0);
}
````
### syscall.h

Add `#define SYS_trace 22`

----

## Specification 2: Scheduling

## FCFS
> Selects the process with the lowest creation time

#### Makefile


#### proc.h
Add `unsigned int ctime;` in `struct proc`


#### proc.c

MODIFY `void scheduler(void)` as
```cpp
void scheduler(void)
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for (;;)
  {

#if SCHEDULER == RR
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }

#elif SCHEDULER == FCFS
    intr_on();
    unsigned int min_creation_time = ticks + 100;
    struct proc *choosen_process = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if (p->ctime < min_creation_time)
        {
          min_creation_time = p->ctime;
          choosen_process = p;
        }
      }
    }
    if (choosen_process != 0)
    {
      choosen_process->state = RUNNING;
      c->proc = choosen_process;
      swtch(&c->context, &choosen_process->context);
      c->proc = 0;
      release(&p->lock);
    }
    else
    {

      release(&p->lock);
      continue;
    }

#elif SCHEDULER == PBS
#elif SCHEDULER == MLFQ
#endif
}
````

And initialise `ctime` in `static struct proc *allocproc(void)`
```cpp
found:
  p->ctime = ticks;
````




#### trap.c
In `void usertrap(void)` modify `yield()` as 
```cpp
#if SCHEDULER == RR
  if (which_dev == 2)
    yield();
#endif
````
Do the same in `void kerneltrap(void)`

```cpp
#if SCHEDULER == RR
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    yield();
  // the yield() may have caused some traps to occur,
  // so restore trap registers for use by kernelvec.S's sepc instruction.
  w_sepc(sepc);
  w_sstatus(sstatus);
#endif
````

## PBS

#### proc.h
non-preemptive priority-based scheduler that selects the process
with the highest priority for execution
Added a bunch of variables in `struct proc` in `proc.h`

```cpp
   unsigned int static_priority;  // = 60 by default, can be changed only using the set_priority system call  // lower the value, higher the priority
    unsigned int dynamic_priority; // = max(0, min(100, SP - niceness + 5))
    unsigned int niceness;         // what percentage of time the process was sleeping = stime/(stime + rtime) * 10
    unsigned int times_scheduled;  // number of times the process has been scheduled on a CPU -- tie breaker for PBS
    unsigned int rtime_lastrun;    // number of ticks for which the process was running from the last time it was scheduled by the kernel
    unsigned int stime_lastrun;    // number of ticks for which the process was sleeping from the last time it was scheduled by the kernel
    unsigned int rtime_total;
    unsigned int stime_total;
    unsigned int etime; //when did the process exit
````

### proc.c
Added the #ifdef block for PBS in `void scheduler(void)`

```cpp
#ifdef PBS
    struct proc *p;
    struct cpu *c = mycpu();
    c->proc = 0;
    for (;;)
    {
        intr_on();
        struct proc *selected_proc = NULL;
        uint selected_proc_priority = 101;
        //Schedule/Select the processes with minimum dynamic priority
        //factors used to calculate dynamic priority - niceness and static priority
        //factors used to calculate niceness - rtime_lastrun and stime_lastrun
        //factors used to break tie - ctime and times_scheduled
        for (p = proc; p < &proc[NPROC]; p++)
        {
            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
                p->niceness = 5;
                p->rtime_lastrun = p->rtime_total - p->last_sched_time;
                p->stime_lastrun = p->stime_total - p->last_sched_time;

                if (p->rtime_lastrun + p->stime_lastrun != 0)
                    p->niceness = (p->rtime_lastrun / (p->rtime_lastrun + p->stime_lastrun)) * 10;

                int x = p->static_priority - p->niceness + 5;
                if (x > 100)
                    x = 100;
                if (x < 0)
                    x = 0;

                p->dynamic_priority = x;

                int this_priority = p->dynamic_priority;

                if (selected_proc == NULL)
                {
                    //If no process has been choosen until now
                    selected_proc = p;
                    selected_proc_priority = this_priority;
                    continue;
                }
                else if (selected_proc_priority > this_priority)
                {
                    // release the lock of already selected proc
                    release(&selected_proc->lock);
                    selected_proc = p;
                    selected_proc_priority = this_priority;
                    continue;
                }

                else if (selected_proc_priority == this_priority && selected_proc->times_scheduled > p->times_scheduled)
                {
                    // tie breaker
                    release(&selected_proc->lock);
                    selected_proc = p;
                    selected_proc_priority = this_priority;
                    continue;
                }
                else if (selected_proc->ctime > p->ctime)
                {
                    release(&selected_proc->lock);
                    selected_proc = p;
                    selected_proc_priority = this_priority;
                    continue;
                }
            }
            release(&p->lock);
        }
        if (selected_proc == NULL)
            continue;

        selected_proc->state = RUNNING;
        selected_proc->times_scheduled++;
        selected_proc->last_sched_time = ticks;

        selected_proc->rtime_lastrun = 0; //Scheduled for next time
        selected_proc->stime_lastrun = 0; //scheduled for the next time
        c->proc = selected_proc;
        swtch(&c->context, &selected_proc->context);
        c->proc = 0;
        release(&selected_proc->lock);
    }
````

Initialised the variables in declared in `proc.h` in `allocproc` function

```cpp
found:
    p->ctime = ticks;   //for waitx and FCFS
    p->rtime_total = 0; //waitx initialisation
    p->stime_total = 0;
    p->etime = 0; //waitx initialisation

    p->pid = allocpid();
    p->state = USED;
    p->niceness = 5;
    p->static_priority = 60;
    p->last_sched_time = 0;
    p->times_scheduled = 0;
    p->rtime_lastrun = 0;
    p->stime_lastrun = 0;
````

Added the update_time function (also used in `waitx` system call)

```cpp
void update_time()
{
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);

        if (p->state == RUNNING)
        {
            p->rtime_total++;
        }
        else if (p->state == SLEEPING)
            p->stime_total++;
        else if (p->state == RUNNABLE)
            p->wtime_total++;

        release(&p->lock);
    }

}
````




## set_priority syscall
>set_priority() is a system call used to change the Static Priority of a process.\
It resets the niceness to 5 as well.

>The system call returns the old static priority of the process. 
In case the priority of the process increases(the value is lower than before), then rescheduling
should be done.
>It takes the process pid and new static priority as command line arguments.

### Makefile
Add `$U/_set_priority\` to `UPROGS`

### proc.c
Added functions
```cpp
int is_valid_priority(int p)
{
    if (p >= 0 && p <= 100)
        return 1;

    printf("Invalid Static Priority\n");
    return 0;
}

int set_priority(int new, int pid)
{
    if (is_valid_priority(new) == 0)
        return -1;

    int old = -1;
    int flag = 0;
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->pid == pid)
        {
            flag = 1;
            old = p->static_priority;
            p->static_priority = new;
            break;
        }
        release(&p->lock);
    }

    if (flag == 0)
    {
        printf("No process with pid %d exists\n", pid);
        return -1;
    }

    printf("Process PID = %d\n, Old Static Priority = %d \nNew Static Priority = %d\n", p->pid, old, new);
    release(&p->lock);

    if (old < new)
    {
#ifdef PBS
        yield(); //rescheduling
#endif
    }

    return old;
}
````
### sysproc.c
Add the *handler* for `set_priority` system call.

````cpp

uint64
sys_set_priority(void) {
    int new;
    int pid;

    int flag1 = argint(0, &new);

    if (flag1 < 0)
        return -1;

    int flag2 = argint(1, &pid);

    if (flag2 < 0)
        return -1;

    return set_priority(new, pid);
}
```` 
`argint` helps to retrieve system call arguments from user space.

### syscall.c

Add\
`extern uint64 sys_set_priority(void);`

`[SYS_set_priority] sys_set_priority,`

Also add set_priority at the end of two arrays created in Specification 1

`"set_priority"`

` [SYS_set_priority] 2,`

### syscall.h
Add `#define SYS_set_priority 23`

### user.h
Add `int set_priority(int, int);`

### usys.pl
Add `entry("set_priority");`

### setpriority.c
Create a new file in `users`
```cpp
#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv) {

    if (argc != 3) {
        printf("Invalid Command\n");
        return 1;
    }

    int new = atoi(argv[1]);
    int pid = atoi(argv[2]);

    int old = set_priority(new, pid);
    if (old == -1)
        return 0;

    return 1;
}
````
## MLFQ
A simplified preemptive MLFQ scheduler that allows processes to move between different priority queues based on their behavior and CPU bursts.

### proc.h

Added another bunch of variables in `proc.h`
```cpp
    unsigned int last_sched_time; //ticks when the process was last scheduled on a CPU

    unsigned int cqueue;      //queue number in which the process is currently in
    unsigned int cqueue_time; //

    unsigned int cqueue_enter_time;  //
    unsigned int change_queue_flag;  //
    unsigned int ticks_in_queues[5]; //ticks spent by the process in each queue
    unsigned int mlfq_wtime;
    unsigned int isQueue;

    unsigned int wtime_total;
````

### proc.c
Declare the queue structure and add the `push_to_queue` and `remove_from_queue` functions to handle it

```cpp
struct proc *MLFQ_queue[5][NPROC];

unsigned int queue_size[5] = {0};

int push_to_queue(struct proc *p, int queue_number)
{

    int s = queue_size[queue_number];
    if (s >= NPROC)
    {
        printf("Can't add more processes\n");
        return 0;
    }
    for (int j = 0; j < 5; j++)
    {
        for (int i = 0; i < s; i++)
        {
            if (MLFQ_queue[j][i]->pid == p->pid)
            {
                printf("Process already exists in the given queue\n");
                return 1;
            }
        }
    }

    MLFQ_queue[queue_number][s] = p;
    queue_size[queue_number]++;

    return 1;
}

int remove_from_queue(struct proc *p, int queue_number)
{

    if (queue_size[queue_number] == 0)
    {
        printf("Queue is empty");
        return 0;
    }
    int s = queue_size[queue_number];
    int flag = 0;
    int found_index = 0;

    for (int i = 0; i < s; i++)
    {
        if (MLFQ_queue[queue_number][i]->pid == p->pid)
        {
            flag = 1;
            found_index = i;
            break;
        }
    }

    if (flag == 0)
    {
        printf("Can't found process\n");
        return 0;
    }

    for (int i = found_index; i < s; i++)
    {
        MLFQ_queue[queue_number][i] = MLFQ_queue[queue_number][i + 1];
    }
    queue_size[queue_number]--;
    return 1;
}
````


Added the #ifdef block for MLFQ in `void scheduler()`

```cpp
#ifdef MLFQ
    //struct proc *p;
    printf("IN MLFQ\n");
    struct cpu *c = mycpu();
    c->proc = 0;

    for (;;)
    {
        intr_on();
        //Consider only RUNNABLE processes for scheduling - remove the ZOMBIE and SLEEPING processes from Queue Structure
        for (int i = 0; i < 5; i++)
        {
            if (queue_size[i] > 0)
            {
                for (int j = 0; j < queue_size[i]; j++)
                {
                    acquire(&MLFQ_queue[i][j]->lock);

                    if (MLFQ_queue[i][j]->state == ZOMBIE || MLFQ_queue[i][j]->state == SLEEPING)
                    {
                        release(&MLFQ_queue[i][j]->lock);
                        MLFQ_queue[i][j]->cqueue = -1;
                        remove_from_queue(MLFQ_queue[i][j], i);
                    }
                    else
                        release(&MLFQ_queue[i][j]->lock);
                }
            }
        }

       // printf("HERE 1\n");
        // IMPLEMENT AGING FOR QUEUE > 0
        // Increase priority - upgrade to a higher queue if wtime i.e. ticks - current queue entry time is greater than a certain threshold

        for (int i = 1; i < 5; i++)
        {
            for (int j = 0; j < queue_size[i]; j++)
            {
                if (ticks - MLFQ_queue[i][j]->cqueue_enter_time > 20)
                {
                    struct proc *temp = MLFQ_queue[i][j];
                    MLFQ_queue[i][j]->cqueue = -1;
                    remove_from_queue(MLFQ_queue[i][j], i);
                    temp->cqueue_enter_time = ticks;
                    temp->cqueue_time = 0;
                    temp->cqueue = i - 1;
                    temp->change_queue_flag = 0;
                    temp->mlfq_wtime = 0;
                    push_to_queue(temp, i - 1);
                }
            }
        }

        //printf("HERE 2\n");

        //SELECT THE FIRST RUNNING PROCESS IN TOP MOST QUEUE TO BE SCHEDULED

        struct proc *selected_proc = NULL;
        for (int i = 0; i < 5; i++)
        {

            for (int j = 0; j < queue_size[i]; j++)
            {
                acquire(&MLFQ_queue[i][j]->lock);

                if (MLFQ_queue[i][j]->state == RUNNABLE)
                {
                    selected_proc = MLFQ_queue[i][j];
                    MLFQ_queue[i][j]->cqueue = -1;
                    remove_from_queue(MLFQ_queue[i][j], i);
                    break;
                }

                release(&MLFQ_queue[i][j]->lock);
            }
        }

        if (!selected_proc)
            continue;
        if (selected_proc->state != RUNNABLE)
        {
            release(&selected_proc->lock);
            continue;
        }

        //printf("HERE 3\n");
        //printf("%d\n", selected_proc->pid);

        //IF A PROCESS WAS SELECTED AND IT IS STILL RUNNABLE SCHEDULE IT ON CPU C

        selected_proc->times_scheduled++;
        selected_proc->state = RUNNING;
        c->proc = selected_proc;

        //printf("HERE 4\n");
        swtch(&c->context, &selected_proc->context);
        //PROCESS IS DONE RUNNING FOR NOW
        c->proc = 0;
        release(&selected_proc->lock);
        //printf("HERE 5\n");
        //PROCESS IS RUNNABLE AGAIN / COMPELTED IT'S TIME SLICE/ INSERT BACK INTO QUEUE STRUCTURE

        if (selected_proc != NULL)
        {
            acquire(&selected_proc->lock);
            if (selected_proc->state == RUNNABLE && selected_proc->cqueue == -1)
            {
                int queue_num = selected_proc->cqueue;
                if (selected_proc->change_queue_flag == 1)
                {
                    if (queue_num <= 3)
                        queue_num++;
                }
                selected_proc->cqueue_enter_time = ticks;
                selected_proc->cqueue_time = 0;
                selected_proc->change_queue_flag = 0;
                selected_proc->cqueue = queue_num;
                selected_proc->mlfq_wtime = 0;
                push_to_queue(selected_proc, queue_num);
            }

            release(&selected_proc->lock);
        }

        //printf("HERE 6\n");
    }
#endif
````
Add push_to_queue in `userinit`, `fork`, `wakeup` and `kill` functions

For example the kill function in `proc.c`
```cpp
int kill(int pid)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->pid == pid)
        {
            p->killed = 1;
            if (p->state == SLEEPING)
            {
                // Wake process from sleep().
                p->state = RUNNABLE;
#ifdef MLFQ
                p->cqueue_enter_time = ticks;
                p->cqueue_time = 0;
                p->change_queue_flag = 0;
                p->cqueue = 0;
                p->mlfq_wtime = 0;
                push_to_queue(p, p->cqueue);
#endif
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    }
    return -1;
}
````

### trap.c

Add this #ifdef MLFQ block in `usertrap` and `kerneltrap`
```cpp
#ifdef MLFQ
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
  {
    if (myproc() && myproc()->cqueue_time >= (1 << myproc()->cqueue))
    {
      myproc()->change_queue_flag = 1;
      printf("Here %d\n", myproc()->pid);
      yield();
    }
  }

#endif

```

Add a function `updatetime` in `proc.c` and call it from function `clockintr()` in `trap.c`
```cpp
void clockintr()
{
  acquire(&tickslock);
  ticks++;
  update_time();
  updatetime();
  wakeup(&ticks);
  release(&tickslock);
}
````

## Procdump

procdump is a function that is useful for debugging (see kernel/proc.c). It prints a list of processes to the console when a user types Ctrl-p on the console.
```cpp
void procdump(void)
{
    struct proc *p;
    static char *states[] = {
        [UNUSED] "unused",
        [SLEEPING] "sleep ",
        [RUNNABLE] "runble",
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    char *state;

    printf("\n");
    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
        else
            state = "???";
        printf("%d %s %s", p->pid, state, p->name);

#ifdef PBS
        printf("%d\t\t%d\t\t%s\t\t%d\t\t%d\t\t%d\n", p->pid, p->static_priority, state, p->rtime_total, p->wtime_total, p->times_scheduled);
#endif
        printf("\n");
    }
}
````

For `wtime_total`, add it in `struct proc`, initialise it in `allocproc` and update it in `update_time` in `proc.c`. 