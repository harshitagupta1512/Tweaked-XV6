#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "stddef.h"

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

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);

static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        char *pa = kalloc();
        if (pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int)(p - proc));
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    }
}

// initialize the proc table at boot time.
void procinit(void)
{
    struct proc *p;

    initlock(&pid_lock, "nextpid");
    initlock(&wait_lock, "wait_lock");
    for (p = proc; p < &proc[NPROC]; p++)
    {
        initlock(&p->lock, "proc");
        p->kstack = KSTACK((int)(p - proc));
    }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    int id = r_tp();
    return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    int id = cpuid();
    struct cpu *c = &cpus[id];
    return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    push_off();
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    pop_off();
    return p;
}

int allocpid()
{
    int pid;
    acquire(&pid_lock);
    pid = nextpid;
    nextpid = nextpid + 1;
    release(&pid_lock);

    return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *allocproc(void)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->state == UNUSED)
        {
            goto found;
        }
        else
        {
            release(&p->lock);
        }
    }
    return 0;

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
    p->mlfq_wtime = 0;
    p->cqueue = -1;
    p->cqueue_time = 0;
    p->cqueue_enter_time = -1;
    p->change_queue_flag = 0;

    p->wtime_total = 0;

    for (int i = 0; i < 5; i++)
        p->ticks_in_queues[i] = 0;

    // Allocate a trapframe page.
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    // An empty user page table.
    p->pagetable = proc_pagetable(p);
    if (p->pagetable == 0)
    {
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    // Set up new context to start executing at forkret,
    // which returns to user space.
    memset(&p->context, 0, sizeof(p->context));
    p->context.ra = (uint64)forkret;
    p->context.sp = p->kstack + PGSIZE;

    return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
    if (p->trapframe)
        kfree((void *)p->trapframe);
    p->trapframe = 0;
    if (p->pagetable)
        proc_freepagetable(p->pagetable, p->sz);
    p->pagetable = 0;
    p->sz = 0;
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->chan = 0;
    p->killed = 0;
    p->xstate = 0;
    p->state = UNUSED;
}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p)
{
    pagetable_t pagetable;

    // An empty page table.
    pagetable = uvmcreate();
    if (pagetable == 0)
        return 0;

    // map the trampoline code (for system call return)
    // at the highest user virtual address.
    // only the supervisor uses it, on the way
    // to/from user space, so not PTE_U.
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
                 (uint64)trampoline, PTE_R | PTE_X) < 0)
    {
        uvmfree(pagetable, 0);
        return 0;
    }

    // map the trapframe just below TRAMPOLINE, for trampoline.S.
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
                 (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
    {
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
        uvmfree(pagetable, 0);
        return 0;
    }

    return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
    struct proc *p;

    p = allocproc();
    initproc = p;

    // allocate one user page and copy init's instructions
    // and data into it.
    uvminit(p->pagetable, initcode, sizeof(initcode));
    p->sz = PGSIZE;

    // prepare for the very first "return" from kernel to user.
    p->trapframe->epc = 0;     // user program counter
    p->trapframe->sp = PGSIZE; // user stack pointer

    safestrcpy(p->name, "initcode", sizeof(p->name));
    p->cwd = namei("/");

    p->state = RUNNABLE;
    p->cqueue_enter_time = ticks;

#ifdef MLFQ
    p->cqueue = 0;
    push_to_queue(p, 0);

#endif
    release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
    uint sz;
    struct proc *p = myproc();

    sz = p->sz;
    if (n > 0)
    {
        if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
        {
            return -1;
        }
    }
    else if (n < 0)
    {
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    }
    p->sz = sz;
    return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{

    //modified to create a new process and inherit the mask value of the parent process (for trace system call)

    int i, pid;
    struct proc *np;
    struct proc *p = myproc();

    // Allocate process.
    if ((np = allocproc()) == 0)
    {
        return -1;
    }

    // Copy user memory from parent to child.
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    {
        freeproc(np);
        release(&np->lock);
        return -1;
    }
    np->sz = p->sz;

    // copy saved user registers.
    *(np->trapframe) = *(p->trapframe);

    // Cause fork to return 0 in the child.

    np->mask = p->mask;
    np->trapframe->a0 = 0;

    // increment reference counts on open file descriptors.
    for (i = 0; i < NOFILE; i++)
        if (p->ofile[i])
            np->ofile[i] = filedup(p->ofile[i]);
    np->cwd = idup(p->cwd);

    safestrcpy(np->name, p->name, sizeof(p->name));

    pid = np->pid;

    release(&np->lock);

    acquire(&wait_lock);
    np->parent = p;
    release(&wait_lock);

    acquire(&np->lock);
    np->state = RUNNABLE;

    np->cqueue_enter_time = ticks;

#ifdef MLFQ
    np->cqueue = 0;
    push_to_queue(np, 0);

#endif
    release(&np->lock);
    return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
    struct proc *pp;

    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
        if (pp->parent == p)
        {
            pp->parent = initproc;
            wakeup(initproc);
        }
    }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
    struct proc *p = myproc();

    if (p == initproc)
        panic("init exiting");

    // Close all open files.
    for (int fd = 0; fd < NOFILE; fd++)
    {
        if (p->ofile[fd])
        {
            struct file *f = p->ofile[fd];
            fileclose(f);
            p->ofile[fd] = 0;
        }
    }

    begin_op();
    iput(p->cwd);
    end_op();
    p->cwd = 0;

    acquire(&wait_lock);

    // Give any children to init.
    reparent(p);

    // Parent might be sleeping in wait().
    wakeup(p->parent);

    acquire(&p->lock);

    p->xstate = status;
    p->state = ZOMBIE;
    p->etime = ticks;

    release(&wait_lock);

    // Jump into the scheduler, never to return.
    sched();
    panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();

    acquire(&wait_lock);

    for (;;)
    {
        // Scan through table looking for exited children.
        havekids = 0;
        for (np = proc; np < &proc[NPROC]; np++)
        {
            if (np->parent == p)
            {
                // make sure the child isn't still in exit() or swtch().
                acquire(&np->lock);

                havekids = 1;
                if (np->state == ZOMBIE)
                {
                    // Found one.
                    pid = np->pid;
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                             sizeof(np->xstate)) < 0)
                    {
                        release(&np->lock);
                        release(&wait_lock);
                        return -1;
                    }
                    freeproc(np);
                    release(&np->lock);
                    release(&wait_lock);
                    return pid;
                }
                release(&np->lock);
            }
        }

        // No point waiting if we don't have any children.
        if (!havekids || p->killed)
        {
            release(&wait_lock);
            return -1;
        }

        // Wait for a child to exit.
        sleep(p, &wait_lock); //DOC: wait-sleep
    }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
#ifdef RR
    struct proc *p;
    struct cpu *c = mycpu();
    c->proc = 0;
    for (;;)
    {
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
    }
#else
#ifdef FCFS
    struct proc *p;
    struct cpu *c = mycpu();
    c->proc = 0;
    for (;;)
    {
        intr_on();
        for (p = proc; p < &proc[NPROC]; p++)
        {
            acquire(&p->lock);
            if (p->state == RUNNABLE)
            {
                struct proc *selected_proc = p;
                struct proc *next;
                for (next = proc; next < &proc[NPROC]; next++)
                {
                    if (next->state != RUNNABLE)
                    {
                        continue;
                    }
                    if (next->pid <= 2)
                    {
                        continue;
                    }
                    if (next->ctime < p->ctime)
                    {
                        selected_proc = next;
                    }
                }
                p = selected_proc;
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
#else
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
#else
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
#endif
#endif
#endif
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.

void sched(void)
{
    int intena;
    struct proc *p = myproc();

    if (!holding(&p->lock))
        panic("sched p->lock");
    if (mycpu()->noff != 1)
        panic("sched locks");
    if (p->state == RUNNING)
        panic("sched running");
    if (intr_get())
        panic("sched interruptible");

    intena = mycpu()->intena;
    swtch(&p->context, &mycpu()->context);
    mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
    struct proc *p = myproc();
    acquire(&p->lock);
    p->state = RUNNABLE;
    sched();
    release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);

    if (first)
    {
        // File system initialization must be run in the context of a
        // regular process (e.g., because it calls sleep), and thus cannot
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc();

    // Must acquire p->lock in order to
    // change p->state and then call sched.
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); //DOC: sleeplock1
    release(lk);

    // Go to sleep.
    p->chan = chan;
    p->state = SLEEPING;

    sched();

    // Tidy up.
    p->chan = 0;

    // Reacquire original lock.
    release(&p->lock);
    acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
            {
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
        }
    }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
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

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    struct proc *p = myproc();
    if (user_dst)
    {
        return copyout(p->pagetable, dst, src, len);
    }
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    struct proc *p = myproc();
    if (user_src)
    {
        return copyin(p->pagetable, dst, src, len);
    }
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
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
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();

    acquire(&wait_lock);

    for (;;)
    {
        // Scan through table looking for exited children.
        havekids = 0;
        for (np = proc; np < &proc[NPROC]; np++)
        {
            if (np->parent == p)
            {
                // make sure the child isn't still in exit() or swtch().
                acquire(&np->lock);

                havekids = 1;
                if (np->state == ZOMBIE)
                {
                    // Found one.
                    pid = np->pid;

                    *rtime = np->rtime_total;
                    *wtime = np->etime - np->rtime_total - np->ctime;

                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                             sizeof(np->xstate)) < 0)
                    {
                        release(&np->lock);
                        release(&wait_lock);
                        return -1;
                    }
                    freeproc(np);
                    release(&np->lock);
                    release(&wait_lock);
                    return pid;
                }
                release(&np->lock);
            }
        }

        // No point waiting if we don't have any children.
        if (!havekids || p->killed)
        {
            release(&wait_lock);
            return -1;
        }

        // Wait for a child to exit.
        sleep(p, &wait_lock); //DOC: wait-sleep
    }
}

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

    for (int q = 0; q < 5; q++)
    {
        for (int i = 0; i < queue_size[q]; i++)
        {
            acquire(&MLFQ_queue[q][i]->lock);
            if (MLFQ_queue[q][i]->state == RUNNABLE)
                MLFQ_queue[q][i]->mlfq_wtime++;
            release(&MLFQ_queue[q][i]->lock);
        }
    }
}
void updatetime()
{
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    {
        acquire(&p->lock);
        if (p->state == RUNNING)
        {
#ifdef MLFQ
            p->cqueue_time++;
            myproc()->ticks_in_queues[myproc()->cqueue]++;
#endif
        }
        release(&p->lock);
    }
}

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