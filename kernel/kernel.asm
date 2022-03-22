
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	2bc78793          	addi	a5,a5,700 # 80006320 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	558080e7          	jalr	1368(ra) # 80002684 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	97a080e7          	jalr	-1670(ra) # 80001b3e <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	0aa080e7          	jalr	170(ra) # 8000227e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	41e080e7          	jalr	1054(ra) # 8000262e <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	3e8080e7          	jalr	1000(ra) # 800026da <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fc4080e7          	jalr	-60(ra) # 8000240a <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	0b878793          	addi	a5,a5,184 # 80023530 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	b6a080e7          	jalr	-1174(ra) # 8000240a <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	952080e7          	jalr	-1710(ra) # 8000227e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00027797          	auipc	a5,0x27
    80000a10:	5f478793          	addi	a5,a5,1524 # 80028000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00027517          	auipc	a0,0x27
    80000ae0:	52450513          	addi	a0,a0,1316 # 80028000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	fa4080e7          	jalr	-92(ra) # 80001b22 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	f72080e7          	jalr	-142(ra) # 80001b22 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	f66080e7          	jalr	-154(ra) # 80001b22 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	f4e080e7          	jalr	-178(ra) # 80001b22 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	f0e080e7          	jalr	-242(ra) # 80001b22 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ee2080e7          	jalr	-286(ra) # 80001b22 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	c7c080e7          	jalr	-900(ra) # 80001b12 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	c60080e7          	jalr	-928(ra) # 80001b12 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	cb4080e7          	jalr	-844(ra) # 80002b88 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	484080e7          	jalr	1156(ra) # 80006360 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	1e8080e7          	jalr	488(ra) # 800020cc <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	b1e080e7          	jalr	-1250(ra) # 80001a62 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	c14080e7          	jalr	-1004(ra) # 80002b60 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c34080e7          	jalr	-972(ra) # 80002b88 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	3ee080e7          	jalr	1006(ra) # 8000634a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	3fc080e7          	jalr	1020(ra) # 80006360 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	5d4080e7          	jalr	1492(ra) # 80003540 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	c64080e7          	jalr	-924(ra) # 80003bd8 <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	c0e080e7          	jalr	-1010(ra) # 80004b8a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	4fe080e7          	jalr	1278(ra) # 80006482 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	eee080e7          	jalr	-274(ra) # 80001e7a <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	78c080e7          	jalr	1932(ra) # 800019cc <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <push_to_queue>:
struct proc *MLFQ_queue[5][NPROC];

unsigned int queue_size[5] = {0};

int push_to_queue(struct proc *p, int queue_number)
{
    8000183e:	1141                	addi	sp,sp,-16
    80001840:	e406                	sd	ra,8(sp)
    80001842:	e022                	sd	s0,0(sp)
    80001844:	0800                	addi	s0,sp,16

    int s = queue_size[queue_number];
    80001846:	00259713          	slli	a4,a1,0x2
    8000184a:	00010797          	auipc	a5,0x10
    8000184e:	a5678793          	addi	a5,a5,-1450 # 800112a0 <queue_size>
    80001852:	97ba                	add	a5,a5,a4
    80001854:	0007a883          	lw	a7,0(a5)
    80001858:	0008831b          	sext.w	t1,a7
    if (s >= NPROC)
    8000185c:	03f00793          	li	a5,63
    80001860:	0667cb63          	blt	a5,t1,800018d6 <push_to_queue+0x98>
    80001864:	00017817          	auipc	a6,0x17
    80001868:	08480813          	addi	a6,a6,132 # 800188e8 <MLFQ_queue>
    8000186c:	fff8869b          	addiw	a3,a7,-1
    80001870:	1682                	slli	a3,a3,0x20
    80001872:	9281                	srli	a3,a3,0x20
    80001874:	068e                	slli	a3,a3,0x3
    80001876:	00017797          	auipc	a5,0x17
    8000187a:	07a78793          	addi	a5,a5,122 # 800188f0 <MLFQ_queue+0x8>
    8000187e:	96be                	add	a3,a3,a5
    80001880:	00018e17          	auipc	t3,0x18
    80001884:	a68e0e13          	addi	t3,t3,-1432 # 800192e8 <tickslock>
        printf("Can't add more processes\n");
        return 0;
    }
    for (int j = 0; j < 5; j++)
    {
        for (int i = 0; i < s; i++)
    80001888:	00605b63          	blez	t1,8000189e <push_to_queue+0x60>
        {
            if (MLFQ_queue[j][i]->pid == p->pid)
    8000188c:	5910                	lw	a2,48(a0)
    8000188e:	87c2                	mv	a5,a6
    80001890:	6398                	ld	a4,0(a5)
    80001892:	5b18                	lw	a4,48(a4)
    80001894:	04c70b63          	beq	a4,a2,800018ea <push_to_queue+0xac>
        for (int i = 0; i < s; i++)
    80001898:	07a1                	addi	a5,a5,8
    8000189a:	fed79be3          	bne	a5,a3,80001890 <push_to_queue+0x52>
    for (int j = 0; j < 5; j++)
    8000189e:	20068693          	addi	a3,a3,512 # 1200 <_entry-0x7fffee00>
    800018a2:	20080813          	addi	a6,a6,512
    800018a6:	ffc811e3          	bne	a6,t3,80001888 <push_to_queue+0x4a>
                return 1;
            }
        }
    }

    MLFQ_queue[queue_number][s] = p;
    800018aa:	00659793          	slli	a5,a1,0x6
    800018ae:	933e                	add	t1,t1,a5
    800018b0:	030e                	slli	t1,t1,0x3
    800018b2:	00017797          	auipc	a5,0x17
    800018b6:	03678793          	addi	a5,a5,54 # 800188e8 <MLFQ_queue>
    800018ba:	933e                	add	t1,t1,a5
    800018bc:	00a33023          	sd	a0,0(t1)
    queue_size[queue_number]++;
    800018c0:	058a                	slli	a1,a1,0x2
    800018c2:	00010797          	auipc	a5,0x10
    800018c6:	9de78793          	addi	a5,a5,-1570 # 800112a0 <queue_size>
    800018ca:	95be                	add	a1,a1,a5
    800018cc:	2885                	addiw	a7,a7,1
    800018ce:	0115a023          	sw	a7,0(a1) # 4000000 <_entry-0x7c000000>

    return 1;
    800018d2:	4505                	li	a0,1
    800018d4:	a025                	j	800018fc <push_to_queue+0xbe>
        printf("Can't add more processes\n");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	caa080e7          	jalr	-854(ra) # 80000588 <printf>
        return 0;
    800018e6:	4501                	li	a0,0
    800018e8:	a811                	j	800018fc <push_to_queue+0xbe>
                printf("Process already exists in the given queue\n");
    800018ea:	00007517          	auipc	a0,0x7
    800018ee:	90e50513          	addi	a0,a0,-1778 # 800081f8 <digits+0x1b8>
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	c96080e7          	jalr	-874(ra) # 80000588 <printf>
                return 1;
    800018fa:	4505                	li	a0,1
}
    800018fc:	60a2                	ld	ra,8(sp)
    800018fe:	6402                	ld	s0,0(sp)
    80001900:	0141                	addi	sp,sp,16
    80001902:	8082                	ret

0000000080001904 <remove_from_queue>:

int remove_from_queue(struct proc *p, int queue_number)
{
    80001904:	1141                	addi	sp,sp,-16
    80001906:	e406                	sd	ra,8(sp)
    80001908:	e022                	sd	s0,0(sp)
    8000190a:	0800                	addi	s0,sp,16

    if (queue_size[queue_number] == 0)
    8000190c:	00259713          	slli	a4,a1,0x2
    80001910:	00010797          	auipc	a5,0x10
    80001914:	99078793          	addi	a5,a5,-1648 # 800112a0 <queue_size>
    80001918:	97ba                	add	a5,a5,a4
    8000191a:	0007a803          	lw	a6,0(a5)
    8000191e:	04080463          	beqz	a6,80001966 <remove_from_queue+0x62>
    {
        printf("Queue is empty");
        return 0;
    }
    int s = queue_size[queue_number];
    80001922:	0008061b          	sext.w	a2,a6
    int flag = 0;
    int found_index = 0;

    for (int i = 0; i < s; i++)
    80001926:	02c05363          	blez	a2,8000194c <remove_from_queue+0x48>
    {
        if (MLFQ_queue[queue_number][i]->pid == p->pid)
    8000192a:	5908                	lw	a0,48(a0)
    8000192c:	00959793          	slli	a5,a1,0x9
    80001930:	00017717          	auipc	a4,0x17
    80001934:	fb870713          	addi	a4,a4,-72 # 800188e8 <MLFQ_queue>
    80001938:	97ba                	add	a5,a5,a4
    for (int i = 0; i < s; i++)
    8000193a:	4701                	li	a4,0
        if (MLFQ_queue[queue_number][i]->pid == p->pid)
    8000193c:	6394                	ld	a3,0(a5)
    8000193e:	5a94                	lw	a3,48(a3)
    80001940:	02a68d63          	beq	a3,a0,8000197a <remove_from_queue+0x76>
    for (int i = 0; i < s; i++)
    80001944:	2705                	addiw	a4,a4,1
    80001946:	07a1                	addi	a5,a5,8
    80001948:	fee61ae3          	bne	a2,a4,8000193c <remove_from_queue+0x38>
        }
    }

    if (flag == 0)
    {
        printf("Can't found process\n");
    8000194c:	00007517          	auipc	a0,0x7
    80001950:	8ec50513          	addi	a0,a0,-1812 # 80008238 <digits+0x1f8>
    80001954:	fffff097          	auipc	ra,0xfffff
    80001958:	c34080e7          	jalr	-972(ra) # 80000588 <printf>
        return 0;
    8000195c:	4501                	li	a0,0
    {
        MLFQ_queue[queue_number][i] = MLFQ_queue[queue_number][i + 1];
    }
    queue_size[queue_number]--;
    return 1;
}
    8000195e:	60a2                	ld	ra,8(sp)
    80001960:	6402                	ld	s0,0(sp)
    80001962:	0141                	addi	sp,sp,16
    80001964:	8082                	ret
        printf("Queue is empty");
    80001966:	00007517          	auipc	a0,0x7
    8000196a:	8c250513          	addi	a0,a0,-1854 # 80008228 <digits+0x1e8>
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	c1a080e7          	jalr	-998(ra) # 80000588 <printf>
        return 0;
    80001976:	4501                	li	a0,0
    80001978:	b7dd                	j	8000195e <remove_from_queue+0x5a>
    for (int i = found_index; i < s; i++)
    8000197a:	02c75e63          	bge	a4,a2,800019b6 <remove_from_queue+0xb2>
    8000197e:	00659613          	slli	a2,a1,0x6
    80001982:	963a                	add	a2,a2,a4
    80001984:	00361793          	slli	a5,a2,0x3
    80001988:	00017697          	auipc	a3,0x17
    8000198c:	f6068693          	addi	a3,a3,-160 # 800188e8 <MLFQ_queue>
    80001990:	97b6                	add	a5,a5,a3
    80001992:	fff8069b          	addiw	a3,a6,-1
    80001996:	40e6873b          	subw	a4,a3,a4
    8000199a:	1702                	slli	a4,a4,0x20
    8000199c:	9301                	srli	a4,a4,0x20
    8000199e:	9732                	add	a4,a4,a2
    800019a0:	070e                	slli	a4,a4,0x3
    800019a2:	00017697          	auipc	a3,0x17
    800019a6:	f4e68693          	addi	a3,a3,-178 # 800188f0 <MLFQ_queue+0x8>
    800019aa:	9736                	add	a4,a4,a3
        MLFQ_queue[queue_number][i] = MLFQ_queue[queue_number][i + 1];
    800019ac:	6794                	ld	a3,8(a5)
    800019ae:	e394                	sd	a3,0(a5)
    for (int i = found_index; i < s; i++)
    800019b0:	07a1                	addi	a5,a5,8
    800019b2:	fee79de3          	bne	a5,a4,800019ac <remove_from_queue+0xa8>
    queue_size[queue_number]--;
    800019b6:	058a                	slli	a1,a1,0x2
    800019b8:	00010797          	auipc	a5,0x10
    800019bc:	8e878793          	addi	a5,a5,-1816 # 800112a0 <queue_size>
    800019c0:	95be                	add	a1,a1,a5
    800019c2:	387d                	addiw	a6,a6,-1
    800019c4:	0105a023          	sw	a6,0(a1)
    return 1;
    800019c8:	4505                	li	a0,1
    800019ca:	bf51                	j	8000195e <remove_from_queue+0x5a>

00000000800019cc <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    800019cc:	7139                	addi	sp,sp,-64
    800019ce:	fc06                	sd	ra,56(sp)
    800019d0:	f822                	sd	s0,48(sp)
    800019d2:	f426                	sd	s1,40(sp)
    800019d4:	f04a                	sd	s2,32(sp)
    800019d6:	ec4e                	sd	s3,24(sp)
    800019d8:	e852                	sd	s4,16(sp)
    800019da:	e456                	sd	s5,8(sp)
    800019dc:	e05a                	sd	s6,0(sp)
    800019de:	0080                	addi	s0,sp,64
    800019e0:	89aa                	mv	s3,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800019e2:	00010497          	auipc	s1,0x10
    800019e6:	d0648493          	addi	s1,s1,-762 # 800116e8 <proc>
    {
        char *pa = kalloc();
        if (pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int)(p - proc));
    800019ea:	8b26                	mv	s6,s1
    800019ec:	00006a97          	auipc	s5,0x6
    800019f0:	614a8a93          	addi	s5,s5,1556 # 80008000 <etext>
    800019f4:	04000937          	lui	s2,0x4000
    800019f8:	197d                	addi	s2,s2,-1
    800019fa:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    800019fc:	00017a17          	auipc	s4,0x17
    80001a00:	eeca0a13          	addi	s4,s4,-276 # 800188e8 <MLFQ_queue>
        char *pa = kalloc();
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	0f0080e7          	jalr	240(ra) # 80000af4 <kalloc>
    80001a0c:	862a                	mv	a2,a0
        if (pa == 0)
    80001a0e:	c131                	beqz	a0,80001a52 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a10:	416485b3          	sub	a1,s1,s6
    80001a14:	858d                	srai	a1,a1,0x3
    80001a16:	000ab783          	ld	a5,0(s5)
    80001a1a:	02f585b3          	mul	a1,a1,a5
    80001a1e:	2585                	addiw	a1,a1,1
    80001a20:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a24:	4719                	li	a4,6
    80001a26:	6685                	lui	a3,0x1
    80001a28:	40b905b3          	sub	a1,s2,a1
    80001a2c:	854e                	mv	a0,s3
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	722080e7          	jalr	1826(ra) # 80001150 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a36:	1c848493          	addi	s1,s1,456
    80001a3a:	fd4495e3          	bne	s1,s4,80001a04 <proc_mapstacks+0x38>
    }
}
    80001a3e:	70e2                	ld	ra,56(sp)
    80001a40:	7442                	ld	s0,48(sp)
    80001a42:	74a2                	ld	s1,40(sp)
    80001a44:	7902                	ld	s2,32(sp)
    80001a46:	69e2                	ld	s3,24(sp)
    80001a48:	6a42                	ld	s4,16(sp)
    80001a4a:	6aa2                	ld	s5,8(sp)
    80001a4c:	6b02                	ld	s6,0(sp)
    80001a4e:	6121                	addi	sp,sp,64
    80001a50:	8082                	ret
            panic("kalloc");
    80001a52:	00006517          	auipc	a0,0x6
    80001a56:	7fe50513          	addi	a0,a0,2046 # 80008250 <digits+0x210>
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	ae4080e7          	jalr	-1308(ra) # 8000053e <panic>

0000000080001a62 <procinit>:

// initialize the proc table at boot time.
void procinit(void)
{
    80001a62:	7139                	addi	sp,sp,-64
    80001a64:	fc06                	sd	ra,56(sp)
    80001a66:	f822                	sd	s0,48(sp)
    80001a68:	f426                	sd	s1,40(sp)
    80001a6a:	f04a                	sd	s2,32(sp)
    80001a6c:	ec4e                	sd	s3,24(sp)
    80001a6e:	e852                	sd	s4,16(sp)
    80001a70:	e456                	sd	s5,8(sp)
    80001a72:	e05a                	sd	s6,0(sp)
    80001a74:	0080                	addi	s0,sp,64
    struct proc *p;

    initlock(&pid_lock, "nextpid");
    80001a76:	00006597          	auipc	a1,0x6
    80001a7a:	7e258593          	addi	a1,a1,2018 # 80008258 <digits+0x218>
    80001a7e:	00010517          	auipc	a0,0x10
    80001a82:	83a50513          	addi	a0,a0,-1990 # 800112b8 <pid_lock>
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	0ce080e7          	jalr	206(ra) # 80000b54 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001a8e:	00006597          	auipc	a1,0x6
    80001a92:	7d258593          	addi	a1,a1,2002 # 80008260 <digits+0x220>
    80001a96:	00010517          	auipc	a0,0x10
    80001a9a:	83a50513          	addi	a0,a0,-1990 # 800112d0 <wait_lock>
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	0b6080e7          	jalr	182(ra) # 80000b54 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001aa6:	00010497          	auipc	s1,0x10
    80001aaa:	c4248493          	addi	s1,s1,-958 # 800116e8 <proc>
    {
        initlock(&p->lock, "proc");
    80001aae:	00006b17          	auipc	s6,0x6
    80001ab2:	7c2b0b13          	addi	s6,s6,1986 # 80008270 <digits+0x230>
        p->kstack = KSTACK((int)(p - proc));
    80001ab6:	8aa6                	mv	s5,s1
    80001ab8:	00006a17          	auipc	s4,0x6
    80001abc:	548a0a13          	addi	s4,s4,1352 # 80008000 <etext>
    80001ac0:	04000937          	lui	s2,0x4000
    80001ac4:	197d                	addi	s2,s2,-1
    80001ac6:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001ac8:	00017997          	auipc	s3,0x17
    80001acc:	e2098993          	addi	s3,s3,-480 # 800188e8 <MLFQ_queue>
        initlock(&p->lock, "proc");
    80001ad0:	85da                	mv	a1,s6
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	080080e7          	jalr	128(ra) # 80000b54 <initlock>
        p->kstack = KSTACK((int)(p - proc));
    80001adc:	415487b3          	sub	a5,s1,s5
    80001ae0:	878d                	srai	a5,a5,0x3
    80001ae2:	000a3703          	ld	a4,0(s4)
    80001ae6:	02e787b3          	mul	a5,a5,a4
    80001aea:	2785                	addiw	a5,a5,1
    80001aec:	00d7979b          	slliw	a5,a5,0xd
    80001af0:	40f907b3          	sub	a5,s2,a5
    80001af4:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001af6:	1c848493          	addi	s1,s1,456
    80001afa:	fd349be3          	bne	s1,s3,80001ad0 <procinit+0x6e>
    }
}
    80001afe:	70e2                	ld	ra,56(sp)
    80001b00:	7442                	ld	s0,48(sp)
    80001b02:	74a2                	ld	s1,40(sp)
    80001b04:	7902                	ld	s2,32(sp)
    80001b06:	69e2                	ld	s3,24(sp)
    80001b08:	6a42                	ld	s4,16(sp)
    80001b0a:	6aa2                	ld	s5,8(sp)
    80001b0c:	6b02                	ld	s6,0(sp)
    80001b0e:	6121                	addi	sp,sp,64
    80001b10:	8082                	ret

0000000080001b12 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b12:	1141                	addi	sp,sp,-16
    80001b14:	e422                	sd	s0,8(sp)
    80001b16:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b18:	8512                	mv	a0,tp
    int id = r_tp();
    return id;
}
    80001b1a:	2501                	sext.w	a0,a0
    80001b1c:	6422                	ld	s0,8(sp)
    80001b1e:	0141                	addi	sp,sp,16
    80001b20:	8082                	ret

0000000080001b22 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b22:	1141                	addi	sp,sp,-16
    80001b24:	e422                	sd	s0,8(sp)
    80001b26:	0800                	addi	s0,sp,16
    80001b28:	8792                	mv	a5,tp
    int id = cpuid();
    struct cpu *c = &cpus[id];
    80001b2a:	2781                	sext.w	a5,a5
    80001b2c:	079e                	slli	a5,a5,0x7
    return c;
}
    80001b2e:	0000f517          	auipc	a0,0xf
    80001b32:	7ba50513          	addi	a0,a0,1978 # 800112e8 <cpus>
    80001b36:	953e                	add	a0,a0,a5
    80001b38:	6422                	ld	s0,8(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret

0000000080001b3e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b3e:	1101                	addi	sp,sp,-32
    80001b40:	ec06                	sd	ra,24(sp)
    80001b42:	e822                	sd	s0,16(sp)
    80001b44:	e426                	sd	s1,8(sp)
    80001b46:	1000                	addi	s0,sp,32
    push_off();
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	050080e7          	jalr	80(ra) # 80000b98 <push_off>
    80001b50:	8792                	mv	a5,tp
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    80001b52:	2781                	sext.w	a5,a5
    80001b54:	079e                	slli	a5,a5,0x7
    80001b56:	0000f717          	auipc	a4,0xf
    80001b5a:	74a70713          	addi	a4,a4,1866 # 800112a0 <queue_size>
    80001b5e:	97ba                	add	a5,a5,a4
    80001b60:	67a4                	ld	s1,72(a5)
    pop_off();
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	0d6080e7          	jalr	214(ra) # 80000c38 <pop_off>
    return p;
}
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6105                	addi	sp,sp,32
    80001b74:	8082                	ret

0000000080001b76 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b76:	1141                	addi	sp,sp,-16
    80001b78:	e406                	sd	ra,8(sp)
    80001b7a:	e022                	sd	s0,0(sp)
    80001b7c:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001b7e:	00000097          	auipc	ra,0x0
    80001b82:	fc0080e7          	jalr	-64(ra) # 80001b3e <myproc>
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	112080e7          	jalr	274(ra) # 80000c98 <release>

    if (first)
    80001b8e:	00007797          	auipc	a5,0x7
    80001b92:	e827a783          	lw	a5,-382(a5) # 80008a10 <first.1746>
    80001b96:	eb89                	bnez	a5,80001ba8 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001b98:	00001097          	auipc	ra,0x1
    80001b9c:	008080e7          	jalr	8(ra) # 80002ba0 <usertrapret>
}
    80001ba0:	60a2                	ld	ra,8(sp)
    80001ba2:	6402                	ld	s0,0(sp)
    80001ba4:	0141                	addi	sp,sp,16
    80001ba6:	8082                	ret
        first = 0;
    80001ba8:	00007797          	auipc	a5,0x7
    80001bac:	e607a423          	sw	zero,-408(a5) # 80008a10 <first.1746>
        fsinit(ROOTDEV);
    80001bb0:	4505                	li	a0,1
    80001bb2:	00002097          	auipc	ra,0x2
    80001bb6:	fa6080e7          	jalr	-90(ra) # 80003b58 <fsinit>
    80001bba:	bff9                	j	80001b98 <forkret+0x22>

0000000080001bbc <allocpid>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001bc8:	0000f917          	auipc	s2,0xf
    80001bcc:	6f090913          	addi	s2,s2,1776 # 800112b8 <pid_lock>
    80001bd0:	854a                	mv	a0,s2
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	012080e7          	jalr	18(ra) # 80000be4 <acquire>
    pid = nextpid;
    80001bda:	00007797          	auipc	a5,0x7
    80001bde:	e3a78793          	addi	a5,a5,-454 # 80008a14 <nextpid>
    80001be2:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001be4:	0014871b          	addiw	a4,s1,1
    80001be8:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001bea:	854a                	mv	a0,s2
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	0ac080e7          	jalr	172(ra) # 80000c98 <release>
}
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	60e2                	ld	ra,24(sp)
    80001bf8:	6442                	ld	s0,16(sp)
    80001bfa:	64a2                	ld	s1,8(sp)
    80001bfc:	6902                	ld	s2,0(sp)
    80001bfe:	6105                	addi	sp,sp,32
    80001c00:	8082                	ret

0000000080001c02 <proc_pagetable>:
{
    80001c02:	1101                	addi	sp,sp,-32
    80001c04:	ec06                	sd	ra,24(sp)
    80001c06:	e822                	sd	s0,16(sp)
    80001c08:	e426                	sd	s1,8(sp)
    80001c0a:	e04a                	sd	s2,0(sp)
    80001c0c:	1000                	addi	s0,sp,32
    80001c0e:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	72a080e7          	jalr	1834(ra) # 8000133a <uvmcreate>
    80001c18:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c1a:	c121                	beqz	a0,80001c5a <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c1c:	4729                	li	a4,10
    80001c1e:	00005697          	auipc	a3,0x5
    80001c22:	3e268693          	addi	a3,a3,994 # 80007000 <_trampoline>
    80001c26:	6605                	lui	a2,0x1
    80001c28:	040005b7          	lui	a1,0x4000
    80001c2c:	15fd                	addi	a1,a1,-1
    80001c2e:	05b2                	slli	a1,a1,0xc
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	480080e7          	jalr	1152(ra) # 800010b0 <mappages>
    80001c38:	02054863          	bltz	a0,80001c68 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c3c:	4719                	li	a4,6
    80001c3e:	05893683          	ld	a3,88(s2)
    80001c42:	6605                	lui	a2,0x1
    80001c44:	020005b7          	lui	a1,0x2000
    80001c48:	15fd                	addi	a1,a1,-1
    80001c4a:	05b6                	slli	a1,a1,0xd
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	462080e7          	jalr	1122(ra) # 800010b0 <mappages>
    80001c56:	02054163          	bltz	a0,80001c78 <proc_pagetable+0x76>
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret
        uvmfree(pagetable, 0);
    80001c68:	4581                	li	a1,0
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	8ca080e7          	jalr	-1846(ra) # 80001536 <uvmfree>
        return 0;
    80001c74:	4481                	li	s1,0
    80001c76:	b7d5                	j	80001c5a <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c78:	4681                	li	a3,0
    80001c7a:	4605                	li	a2,1
    80001c7c:	040005b7          	lui	a1,0x4000
    80001c80:	15fd                	addi	a1,a1,-1
    80001c82:	05b2                	slli	a1,a1,0xc
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	5f0080e7          	jalr	1520(ra) # 80001276 <uvmunmap>
        uvmfree(pagetable, 0);
    80001c8e:	4581                	li	a1,0
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	8a4080e7          	jalr	-1884(ra) # 80001536 <uvmfree>
        return 0;
    80001c9a:	4481                	li	s1,0
    80001c9c:	bf7d                	j	80001c5a <proc_pagetable+0x58>

0000000080001c9e <proc_freepagetable>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	e04a                	sd	s2,0(sp)
    80001ca8:	1000                	addi	s0,sp,32
    80001caa:	84aa                	mv	s1,a0
    80001cac:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cae:	4681                	li	a3,0
    80001cb0:	4605                	li	a2,1
    80001cb2:	040005b7          	lui	a1,0x4000
    80001cb6:	15fd                	addi	a1,a1,-1
    80001cb8:	05b2                	slli	a1,a1,0xc
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	5bc080e7          	jalr	1468(ra) # 80001276 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cc2:	4681                	li	a3,0
    80001cc4:	4605                	li	a2,1
    80001cc6:	020005b7          	lui	a1,0x2000
    80001cca:	15fd                	addi	a1,a1,-1
    80001ccc:	05b6                	slli	a1,a1,0xd
    80001cce:	8526                	mv	a0,s1
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	5a6080e7          	jalr	1446(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, sz);
    80001cd8:	85ca                	mv	a1,s2
    80001cda:	8526                	mv	a0,s1
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	85a080e7          	jalr	-1958(ra) # 80001536 <uvmfree>
}
    80001ce4:	60e2                	ld	ra,24(sp)
    80001ce6:	6442                	ld	s0,16(sp)
    80001ce8:	64a2                	ld	s1,8(sp)
    80001cea:	6902                	ld	s2,0(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret

0000000080001cf0 <freeproc>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	1000                	addi	s0,sp,32
    80001cfa:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001cfc:	6d28                	ld	a0,88(a0)
    80001cfe:	c509                	beqz	a0,80001d08 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	cf8080e7          	jalr	-776(ra) # 800009f8 <kfree>
    p->trapframe = 0;
    80001d08:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d0c:	68a8                	ld	a0,80(s1)
    80001d0e:	c511                	beqz	a0,80001d1a <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d10:	64ac                	ld	a1,72(s1)
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	f8c080e7          	jalr	-116(ra) # 80001c9e <proc_freepagetable>
    p->pagetable = 0;
    80001d1a:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d1e:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d22:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d26:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001d2a:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d2e:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001d32:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001d36:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001d3a:	0004ac23          	sw	zero,24(s1)
}
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret

0000000080001d48 <allocproc>:
{
    80001d48:	1101                	addi	sp,sp,-32
    80001d4a:	ec06                	sd	ra,24(sp)
    80001d4c:	e822                	sd	s0,16(sp)
    80001d4e:	e426                	sd	s1,8(sp)
    80001d50:	e04a                	sd	s2,0(sp)
    80001d52:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001d54:	00010497          	auipc	s1,0x10
    80001d58:	99448493          	addi	s1,s1,-1644 # 800116e8 <proc>
    80001d5c:	00017917          	auipc	s2,0x17
    80001d60:	b8c90913          	addi	s2,s2,-1140 # 800188e8 <MLFQ_queue>
        acquire(&p->lock);
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	e7e080e7          	jalr	-386(ra) # 80000be4 <acquire>
        if (p->state == UNUSED)
    80001d6e:	4c9c                	lw	a5,24(s1)
    80001d70:	cf81                	beqz	a5,80001d88 <allocproc+0x40>
            release(&p->lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001d7c:	1c848493          	addi	s1,s1,456
    80001d80:	ff2492e3          	bne	s1,s2,80001d64 <allocproc+0x1c>
    return 0;
    80001d84:	4481                	li	s1,0
    80001d86:	a85d                	j	80001e3c <allocproc+0xf4>
    p->ctime = ticks;   //for waitx and FCFS
    80001d88:	00007797          	auipc	a5,0x7
    80001d8c:	2a87a783          	lw	a5,680(a5) # 80009030 <ticks>
    80001d90:	16f4a423          	sw	a5,360(s1)
    p->rtime_total = 0; //waitx initialisation
    80001d94:	1804a423          	sw	zero,392(s1)
    p->stime_total = 0;
    80001d98:	1804a623          	sw	zero,396(s1)
    p->etime = 0; //waitx initialisation
    80001d9c:	1804a823          	sw	zero,400(s1)
    p->pid = allocpid();
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e1c080e7          	jalr	-484(ra) # 80001bbc <allocpid>
    80001da8:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001daa:	4785                	li	a5,1
    80001dac:	cc9c                	sw	a5,24(s1)
    p->niceness = 5;
    80001dae:	4795                	li	a5,5
    80001db0:	16f4ac23          	sw	a5,376(s1)
    p->static_priority = 60;
    80001db4:	03c00793          	li	a5,60
    80001db8:	16f4a823          	sw	a5,368(s1)
    p->last_sched_time = 0;
    80001dbc:	1804aa23          	sw	zero,404(s1)
    p->times_scheduled = 0;
    80001dc0:	1604ae23          	sw	zero,380(s1)
    p->rtime_lastrun = 0;
    80001dc4:	1804a023          	sw	zero,384(s1)
    p->stime_lastrun = 0;
    80001dc8:	1804a223          	sw	zero,388(s1)
    p->mlfq_wtime = 0;
    80001dcc:	1a04ae23          	sw	zero,444(s1)
    p->cqueue = -1;
    80001dd0:	57fd                	li	a5,-1
    80001dd2:	18f4ac23          	sw	a5,408(s1)
    p->cqueue_time = 0;
    80001dd6:	1804ae23          	sw	zero,412(s1)
    p->cqueue_enter_time = -1;
    80001dda:	1af4a023          	sw	a5,416(s1)
    p->change_queue_flag = 0;
    80001dde:	1a04a223          	sw	zero,420(s1)
    p->wtime_total = 0;
    80001de2:	1c04a223          	sw	zero,452(s1)
        p->ticks_in_queues[i] = 0;
    80001de6:	1a04a423          	sw	zero,424(s1)
    80001dea:	1a04a623          	sw	zero,428(s1)
    80001dee:	1a04a823          	sw	zero,432(s1)
    80001df2:	1a04aa23          	sw	zero,436(s1)
    80001df6:	1a04ac23          	sw	zero,440(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	cfa080e7          	jalr	-774(ra) # 80000af4 <kalloc>
    80001e02:	892a                	mv	s2,a0
    80001e04:	eca8                	sd	a0,88(s1)
    80001e06:	c131                	beqz	a0,80001e4a <allocproc+0x102>
    p->pagetable = proc_pagetable(p);
    80001e08:	8526                	mv	a0,s1
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	df8080e7          	jalr	-520(ra) # 80001c02 <proc_pagetable>
    80001e12:	892a                	mv	s2,a0
    80001e14:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e16:	c531                	beqz	a0,80001e62 <allocproc+0x11a>
    memset(&p->context, 0, sizeof(p->context));
    80001e18:	07000613          	li	a2,112
    80001e1c:	4581                	li	a1,0
    80001e1e:	06048513          	addi	a0,s1,96
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	ebe080e7          	jalr	-322(ra) # 80000ce0 <memset>
    p->context.ra = (uint64)forkret;
    80001e2a:	00000797          	auipc	a5,0x0
    80001e2e:	d4c78793          	addi	a5,a5,-692 # 80001b76 <forkret>
    80001e32:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e34:	60bc                	ld	a5,64(s1)
    80001e36:	6705                	lui	a4,0x1
    80001e38:	97ba                	add	a5,a5,a4
    80001e3a:	f4bc                	sd	a5,104(s1)
}
    80001e3c:	8526                	mv	a0,s1
    80001e3e:	60e2                	ld	ra,24(sp)
    80001e40:	6442                	ld	s0,16(sp)
    80001e42:	64a2                	ld	s1,8(sp)
    80001e44:	6902                	ld	s2,0(sp)
    80001e46:	6105                	addi	sp,sp,32
    80001e48:	8082                	ret
        freeproc(p);
    80001e4a:	8526                	mv	a0,s1
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	ea4080e7          	jalr	-348(ra) # 80001cf0 <freeproc>
        release(&p->lock);
    80001e54:	8526                	mv	a0,s1
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e42080e7          	jalr	-446(ra) # 80000c98 <release>
        return 0;
    80001e5e:	84ca                	mv	s1,s2
    80001e60:	bff1                	j	80001e3c <allocproc+0xf4>
        freeproc(p);
    80001e62:	8526                	mv	a0,s1
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	e8c080e7          	jalr	-372(ra) # 80001cf0 <freeproc>
        release(&p->lock);
    80001e6c:	8526                	mv	a0,s1
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	e2a080e7          	jalr	-470(ra) # 80000c98 <release>
        return 0;
    80001e76:	84ca                	mv	s1,s2
    80001e78:	b7d1                	j	80001e3c <allocproc+0xf4>

0000000080001e7a <userinit>:
{
    80001e7a:	1101                	addi	sp,sp,-32
    80001e7c:	ec06                	sd	ra,24(sp)
    80001e7e:	e822                	sd	s0,16(sp)
    80001e80:	e426                	sd	s1,8(sp)
    80001e82:	1000                	addi	s0,sp,32
    p = allocproc();
    80001e84:	00000097          	auipc	ra,0x0
    80001e88:	ec4080e7          	jalr	-316(ra) # 80001d48 <allocproc>
    80001e8c:	84aa                	mv	s1,a0
    initproc = p;
    80001e8e:	00007797          	auipc	a5,0x7
    80001e92:	18a7bd23          	sd	a0,410(a5) # 80009028 <initproc>
    uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e96:	03400613          	li	a2,52
    80001e9a:	00007597          	auipc	a1,0x7
    80001e9e:	b8658593          	addi	a1,a1,-1146 # 80008a20 <initcode>
    80001ea2:	6928                	ld	a0,80(a0)
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	4c4080e7          	jalr	1220(ra) # 80001368 <uvminit>
    p->sz = PGSIZE;
    80001eac:	6785                	lui	a5,0x1
    80001eae:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001eb0:	6cb8                	ld	a4,88(s1)
    80001eb2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001eb6:	6cb8                	ld	a4,88(s1)
    80001eb8:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001eba:	4641                	li	a2,16
    80001ebc:	00006597          	auipc	a1,0x6
    80001ec0:	3bc58593          	addi	a1,a1,956 # 80008278 <digits+0x238>
    80001ec4:	15848513          	addi	a0,s1,344
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	f6a080e7          	jalr	-150(ra) # 80000e32 <safestrcpy>
    p->cwd = namei("/");
    80001ed0:	00006517          	auipc	a0,0x6
    80001ed4:	3b850513          	addi	a0,a0,952 # 80008288 <digits+0x248>
    80001ed8:	00002097          	auipc	ra,0x2
    80001edc:	6ae080e7          	jalr	1710(ra) # 80004586 <namei>
    80001ee0:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001ee4:	478d                	li	a5,3
    80001ee6:	cc9c                	sw	a5,24(s1)
    p->cqueue_enter_time = ticks;
    80001ee8:	00007797          	auipc	a5,0x7
    80001eec:	1487a783          	lw	a5,328(a5) # 80009030 <ticks>
    80001ef0:	1af4a023          	sw	a5,416(s1)
    release(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	da2080e7          	jalr	-606(ra) # 80000c98 <release>
}
    80001efe:	60e2                	ld	ra,24(sp)
    80001f00:	6442                	ld	s0,16(sp)
    80001f02:	64a2                	ld	s1,8(sp)
    80001f04:	6105                	addi	sp,sp,32
    80001f06:	8082                	ret

0000000080001f08 <growproc>:
{
    80001f08:	1101                	addi	sp,sp,-32
    80001f0a:	ec06                	sd	ra,24(sp)
    80001f0c:	e822                	sd	s0,16(sp)
    80001f0e:	e426                	sd	s1,8(sp)
    80001f10:	e04a                	sd	s2,0(sp)
    80001f12:	1000                	addi	s0,sp,32
    80001f14:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80001f16:	00000097          	auipc	ra,0x0
    80001f1a:	c28080e7          	jalr	-984(ra) # 80001b3e <myproc>
    80001f1e:	892a                	mv	s2,a0
    sz = p->sz;
    80001f20:	652c                	ld	a1,72(a0)
    80001f22:	0005861b          	sext.w	a2,a1
    if (n > 0)
    80001f26:	00904f63          	bgtz	s1,80001f44 <growproc+0x3c>
    else if (n < 0)
    80001f2a:	0204cc63          	bltz	s1,80001f62 <growproc+0x5a>
    p->sz = sz;
    80001f2e:	1602                	slli	a2,a2,0x20
    80001f30:	9201                	srli	a2,a2,0x20
    80001f32:	04c93423          	sd	a2,72(s2)
    return 0;
    80001f36:	4501                	li	a0,0
}
    80001f38:	60e2                	ld	ra,24(sp)
    80001f3a:	6442                	ld	s0,16(sp)
    80001f3c:	64a2                	ld	s1,8(sp)
    80001f3e:	6902                	ld	s2,0(sp)
    80001f40:	6105                	addi	sp,sp,32
    80001f42:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001f44:	9e25                	addw	a2,a2,s1
    80001f46:	1602                	slli	a2,a2,0x20
    80001f48:	9201                	srli	a2,a2,0x20
    80001f4a:	1582                	slli	a1,a1,0x20
    80001f4c:	9181                	srli	a1,a1,0x20
    80001f4e:	6928                	ld	a0,80(a0)
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	4d2080e7          	jalr	1234(ra) # 80001422 <uvmalloc>
    80001f58:	0005061b          	sext.w	a2,a0
    80001f5c:	fa69                	bnez	a2,80001f2e <growproc+0x26>
            return -1;
    80001f5e:	557d                	li	a0,-1
    80001f60:	bfe1                	j	80001f38 <growproc+0x30>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f62:	9e25                	addw	a2,a2,s1
    80001f64:	1602                	slli	a2,a2,0x20
    80001f66:	9201                	srli	a2,a2,0x20
    80001f68:	1582                	slli	a1,a1,0x20
    80001f6a:	9181                	srli	a1,a1,0x20
    80001f6c:	6928                	ld	a0,80(a0)
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	46c080e7          	jalr	1132(ra) # 800013da <uvmdealloc>
    80001f76:	0005061b          	sext.w	a2,a0
    80001f7a:	bf55                	j	80001f2e <growproc+0x26>

0000000080001f7c <fork>:
{
    80001f7c:	7179                	addi	sp,sp,-48
    80001f7e:	f406                	sd	ra,40(sp)
    80001f80:	f022                	sd	s0,32(sp)
    80001f82:	ec26                	sd	s1,24(sp)
    80001f84:	e84a                	sd	s2,16(sp)
    80001f86:	e44e                	sd	s3,8(sp)
    80001f88:	e052                	sd	s4,0(sp)
    80001f8a:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	bb2080e7          	jalr	-1102(ra) # 80001b3e <myproc>
    80001f94:	892a                	mv	s2,a0
    if ((np = allocproc()) == 0)
    80001f96:	00000097          	auipc	ra,0x0
    80001f9a:	db2080e7          	jalr	-590(ra) # 80001d48 <allocproc>
    80001f9e:	12050563          	beqz	a0,800020c8 <fork+0x14c>
    80001fa2:	89aa                	mv	s3,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fa4:	04893603          	ld	a2,72(s2)
    80001fa8:	692c                	ld	a1,80(a0)
    80001faa:	05093503          	ld	a0,80(s2)
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	5c0080e7          	jalr	1472(ra) # 8000156e <uvmcopy>
    80001fb6:	04054a63          	bltz	a0,8000200a <fork+0x8e>
    np->sz = p->sz;
    80001fba:	04893783          	ld	a5,72(s2)
    80001fbe:	04f9b423          	sd	a5,72(s3)
    *(np->trapframe) = *(p->trapframe);
    80001fc2:	05893683          	ld	a3,88(s2)
    80001fc6:	87b6                	mv	a5,a3
    80001fc8:	0589b703          	ld	a4,88(s3)
    80001fcc:	12068693          	addi	a3,a3,288
    80001fd0:	0007b803          	ld	a6,0(a5)
    80001fd4:	6788                	ld	a0,8(a5)
    80001fd6:	6b8c                	ld	a1,16(a5)
    80001fd8:	6f90                	ld	a2,24(a5)
    80001fda:	01073023          	sd	a6,0(a4)
    80001fde:	e708                	sd	a0,8(a4)
    80001fe0:	eb0c                	sd	a1,16(a4)
    80001fe2:	ef10                	sd	a2,24(a4)
    80001fe4:	02078793          	addi	a5,a5,32
    80001fe8:	02070713          	addi	a4,a4,32
    80001fec:	fed792e3          	bne	a5,a3,80001fd0 <fork+0x54>
    np->mask = p->mask;
    80001ff0:	16c92783          	lw	a5,364(s2)
    80001ff4:	16f9a623          	sw	a5,364(s3)
    np->trapframe->a0 = 0;
    80001ff8:	0589b783          	ld	a5,88(s3)
    80001ffc:	0607b823          	sd	zero,112(a5)
    80002000:	0d000493          	li	s1,208
    for (i = 0; i < NOFILE; i++)
    80002004:	15000a13          	li	s4,336
    80002008:	a03d                	j	80002036 <fork+0xba>
        freeproc(np);
    8000200a:	854e                	mv	a0,s3
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	ce4080e7          	jalr	-796(ra) # 80001cf0 <freeproc>
        release(&np->lock);
    80002014:	854e                	mv	a0,s3
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	c82080e7          	jalr	-894(ra) # 80000c98 <release>
        return -1;
    8000201e:	5a7d                	li	s4,-1
    80002020:	a859                	j	800020b6 <fork+0x13a>
            np->ofile[i] = filedup(p->ofile[i]);
    80002022:	00003097          	auipc	ra,0x3
    80002026:	bfa080e7          	jalr	-1030(ra) # 80004c1c <filedup>
    8000202a:	009987b3          	add	a5,s3,s1
    8000202e:	e388                	sd	a0,0(a5)
    for (i = 0; i < NOFILE; i++)
    80002030:	04a1                	addi	s1,s1,8
    80002032:	01448763          	beq	s1,s4,80002040 <fork+0xc4>
        if (p->ofile[i])
    80002036:	009907b3          	add	a5,s2,s1
    8000203a:	6388                	ld	a0,0(a5)
    8000203c:	f17d                	bnez	a0,80002022 <fork+0xa6>
    8000203e:	bfcd                	j	80002030 <fork+0xb4>
    np->cwd = idup(p->cwd);
    80002040:	15093503          	ld	a0,336(s2)
    80002044:	00002097          	auipc	ra,0x2
    80002048:	d4e080e7          	jalr	-690(ra) # 80003d92 <idup>
    8000204c:	14a9b823          	sd	a0,336(s3)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002050:	4641                	li	a2,16
    80002052:	15890593          	addi	a1,s2,344
    80002056:	15898513          	addi	a0,s3,344
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	dd8080e7          	jalr	-552(ra) # 80000e32 <safestrcpy>
    pid = np->pid;
    80002062:	0309aa03          	lw	s4,48(s3)
    release(&np->lock);
    80002066:	854e                	mv	a0,s3
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	c30080e7          	jalr	-976(ra) # 80000c98 <release>
    acquire(&wait_lock);
    80002070:	0000f497          	auipc	s1,0xf
    80002074:	26048493          	addi	s1,s1,608 # 800112d0 <wait_lock>
    80002078:	8526                	mv	a0,s1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	b6a080e7          	jalr	-1174(ra) # 80000be4 <acquire>
    np->parent = p;
    80002082:	0329bc23          	sd	s2,56(s3)
    release(&wait_lock);
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	c10080e7          	jalr	-1008(ra) # 80000c98 <release>
    acquire(&np->lock);
    80002090:	854e                	mv	a0,s3
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	b52080e7          	jalr	-1198(ra) # 80000be4 <acquire>
    np->state = RUNNABLE;
    8000209a:	478d                	li	a5,3
    8000209c:	00f9ac23          	sw	a5,24(s3)
    np->cqueue_enter_time = ticks;
    800020a0:	00007797          	auipc	a5,0x7
    800020a4:	f907a783          	lw	a5,-112(a5) # 80009030 <ticks>
    800020a8:	1af9a023          	sw	a5,416(s3)
    release(&np->lock);
    800020ac:	854e                	mv	a0,s3
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bea080e7          	jalr	-1046(ra) # 80000c98 <release>
}
    800020b6:	8552                	mv	a0,s4
    800020b8:	70a2                	ld	ra,40(sp)
    800020ba:	7402                	ld	s0,32(sp)
    800020bc:	64e2                	ld	s1,24(sp)
    800020be:	6942                	ld	s2,16(sp)
    800020c0:	69a2                	ld	s3,8(sp)
    800020c2:	6a02                	ld	s4,0(sp)
    800020c4:	6145                	addi	sp,sp,48
    800020c6:	8082                	ret
        return -1;
    800020c8:	5a7d                	li	s4,-1
    800020ca:	b7f5                	j	800020b6 <fork+0x13a>

00000000800020cc <scheduler>:
{
    800020cc:	7139                	addi	sp,sp,-64
    800020ce:	fc06                	sd	ra,56(sp)
    800020d0:	f822                	sd	s0,48(sp)
    800020d2:	f426                	sd	s1,40(sp)
    800020d4:	f04a                	sd	s2,32(sp)
    800020d6:	ec4e                	sd	s3,24(sp)
    800020d8:	e852                	sd	s4,16(sp)
    800020da:	e456                	sd	s5,8(sp)
    800020dc:	e05a                	sd	s6,0(sp)
    800020de:	0080                	addi	s0,sp,64
    800020e0:	8792                	mv	a5,tp
    int id = r_tp();
    800020e2:	2781                	sext.w	a5,a5
    c->proc = 0;
    800020e4:	00779a93          	slli	s5,a5,0x7
    800020e8:	0000f717          	auipc	a4,0xf
    800020ec:	1b870713          	addi	a4,a4,440 # 800112a0 <queue_size>
    800020f0:	9756                	add	a4,a4,s5
    800020f2:	04073423          	sd	zero,72(a4)
                swtch(&c->context, &p->context);
    800020f6:	0000f717          	auipc	a4,0xf
    800020fa:	1fa70713          	addi	a4,a4,506 # 800112f0 <cpus+0x8>
    800020fe:	9aba                	add	s5,s5,a4
            if (p->state == RUNNABLE)
    80002100:	498d                	li	s3,3
                p->state = RUNNING;
    80002102:	4b11                	li	s6,4
                c->proc = p;
    80002104:	079e                	slli	a5,a5,0x7
    80002106:	0000fa17          	auipc	s4,0xf
    8000210a:	19aa0a13          	addi	s4,s4,410 # 800112a0 <queue_size>
    8000210e:	9a3e                	add	s4,s4,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80002110:	00016917          	auipc	s2,0x16
    80002114:	7d890913          	addi	s2,s2,2008 # 800188e8 <MLFQ_queue>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002118:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000211c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002120:	10079073          	csrw	sstatus,a5
    80002124:	0000f497          	auipc	s1,0xf
    80002128:	5c448493          	addi	s1,s1,1476 # 800116e8 <proc>
    8000212c:	a03d                	j	8000215a <scheduler+0x8e>
                p->state = RUNNING;
    8000212e:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80002132:	049a3423          	sd	s1,72(s4)
                swtch(&c->context, &p->context);
    80002136:	06048593          	addi	a1,s1,96
    8000213a:	8556                	mv	a0,s5
    8000213c:	00001097          	auipc	ra,0x1
    80002140:	9ba080e7          	jalr	-1606(ra) # 80002af6 <swtch>
                c->proc = 0;
    80002144:	040a3423          	sd	zero,72(s4)
            release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	b4e080e7          	jalr	-1202(ra) # 80000c98 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80002152:	1c848493          	addi	s1,s1,456
    80002156:	fd2481e3          	beq	s1,s2,80002118 <scheduler+0x4c>
            acquire(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	a88080e7          	jalr	-1400(ra) # 80000be4 <acquire>
            if (p->state == RUNNABLE)
    80002164:	4c9c                	lw	a5,24(s1)
    80002166:	ff3791e3          	bne	a5,s3,80002148 <scheduler+0x7c>
    8000216a:	b7d1                	j	8000212e <scheduler+0x62>

000000008000216c <sched>:
{
    8000216c:	7179                	addi	sp,sp,-48
    8000216e:	f406                	sd	ra,40(sp)
    80002170:	f022                	sd	s0,32(sp)
    80002172:	ec26                	sd	s1,24(sp)
    80002174:	e84a                	sd	s2,16(sp)
    80002176:	e44e                	sd	s3,8(sp)
    80002178:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	9c4080e7          	jalr	-1596(ra) # 80001b3e <myproc>
    80002182:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002184:	fffff097          	auipc	ra,0xfffff
    80002188:	9e6080e7          	jalr	-1562(ra) # 80000b6a <holding>
    8000218c:	c93d                	beqz	a0,80002202 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218e:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002190:	2781                	sext.w	a5,a5
    80002192:	079e                	slli	a5,a5,0x7
    80002194:	0000f717          	auipc	a4,0xf
    80002198:	10c70713          	addi	a4,a4,268 # 800112a0 <queue_size>
    8000219c:	97ba                	add	a5,a5,a4
    8000219e:	0c07a703          	lw	a4,192(a5)
    800021a2:	4785                	li	a5,1
    800021a4:	06f71763          	bne	a4,a5,80002212 <sched+0xa6>
    if (p->state == RUNNING)
    800021a8:	4c98                	lw	a4,24(s1)
    800021aa:	4791                	li	a5,4
    800021ac:	06f70b63          	beq	a4,a5,80002222 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021b0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021b4:	8b89                	andi	a5,a5,2
    if (intr_get())
    800021b6:	efb5                	bnez	a5,80002232 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b8:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800021ba:	0000f917          	auipc	s2,0xf
    800021be:	0e690913          	addi	s2,s2,230 # 800112a0 <queue_size>
    800021c2:	2781                	sext.w	a5,a5
    800021c4:	079e                	slli	a5,a5,0x7
    800021c6:	97ca                	add	a5,a5,s2
    800021c8:	0c47a983          	lw	s3,196(a5)
    800021cc:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    800021ce:	2781                	sext.w	a5,a5
    800021d0:	079e                	slli	a5,a5,0x7
    800021d2:	0000f597          	auipc	a1,0xf
    800021d6:	11e58593          	addi	a1,a1,286 # 800112f0 <cpus+0x8>
    800021da:	95be                	add	a1,a1,a5
    800021dc:	06048513          	addi	a0,s1,96
    800021e0:	00001097          	auipc	ra,0x1
    800021e4:	916080e7          	jalr	-1770(ra) # 80002af6 <swtch>
    800021e8:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800021ea:	2781                	sext.w	a5,a5
    800021ec:	079e                	slli	a5,a5,0x7
    800021ee:	97ca                	add	a5,a5,s2
    800021f0:	0d37a223          	sw	s3,196(a5)
}
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret
        panic("sched p->lock");
    80002202:	00006517          	auipc	a0,0x6
    80002206:	08e50513          	addi	a0,a0,142 # 80008290 <digits+0x250>
    8000220a:	ffffe097          	auipc	ra,0xffffe
    8000220e:	334080e7          	jalr	820(ra) # 8000053e <panic>
        panic("sched locks");
    80002212:	00006517          	auipc	a0,0x6
    80002216:	08e50513          	addi	a0,a0,142 # 800082a0 <digits+0x260>
    8000221a:	ffffe097          	auipc	ra,0xffffe
    8000221e:	324080e7          	jalr	804(ra) # 8000053e <panic>
        panic("sched running");
    80002222:	00006517          	auipc	a0,0x6
    80002226:	08e50513          	addi	a0,a0,142 # 800082b0 <digits+0x270>
    8000222a:	ffffe097          	auipc	ra,0xffffe
    8000222e:	314080e7          	jalr	788(ra) # 8000053e <panic>
        panic("sched interruptible");
    80002232:	00006517          	auipc	a0,0x6
    80002236:	08e50513          	addi	a0,a0,142 # 800082c0 <digits+0x280>
    8000223a:	ffffe097          	auipc	ra,0xffffe
    8000223e:	304080e7          	jalr	772(ra) # 8000053e <panic>

0000000080002242 <yield>:
{
    80002242:	1101                	addi	sp,sp,-32
    80002244:	ec06                	sd	ra,24(sp)
    80002246:	e822                	sd	s0,16(sp)
    80002248:	e426                	sd	s1,8(sp)
    8000224a:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000224c:	00000097          	auipc	ra,0x0
    80002250:	8f2080e7          	jalr	-1806(ra) # 80001b3e <myproc>
    80002254:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	98e080e7          	jalr	-1650(ra) # 80000be4 <acquire>
    p->state = RUNNABLE;
    8000225e:	478d                	li	a5,3
    80002260:	cc9c                	sw	a5,24(s1)
    sched();
    80002262:	00000097          	auipc	ra,0x0
    80002266:	f0a080e7          	jalr	-246(ra) # 8000216c <sched>
    release(&p->lock);
    8000226a:	8526                	mv	a0,s1
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a2c080e7          	jalr	-1492(ra) # 80000c98 <release>
}
    80002274:	60e2                	ld	ra,24(sp)
    80002276:	6442                	ld	s0,16(sp)
    80002278:	64a2                	ld	s1,8(sp)
    8000227a:	6105                	addi	sp,sp,32
    8000227c:	8082                	ret

000000008000227e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000227e:	7179                	addi	sp,sp,-48
    80002280:	f406                	sd	ra,40(sp)
    80002282:	f022                	sd	s0,32(sp)
    80002284:	ec26                	sd	s1,24(sp)
    80002286:	e84a                	sd	s2,16(sp)
    80002288:	e44e                	sd	s3,8(sp)
    8000228a:	1800                	addi	s0,sp,48
    8000228c:	89aa                	mv	s3,a0
    8000228e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002290:	00000097          	auipc	ra,0x0
    80002294:	8ae080e7          	jalr	-1874(ra) # 80001b3e <myproc>
    80002298:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); //DOC: sleeplock1
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	94a080e7          	jalr	-1718(ra) # 80000be4 <acquire>
    release(lk);
    800022a2:	854a                	mv	a0,s2
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	9f4080e7          	jalr	-1548(ra) # 80000c98 <release>

    // Go to sleep.
    p->chan = chan;
    800022ac:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800022b0:	4789                	li	a5,2
    800022b2:	cc9c                	sw	a5,24(s1)

    sched();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	eb8080e7          	jalr	-328(ra) # 8000216c <sched>

    // Tidy up.
    p->chan = 0;
    800022bc:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	9d6080e7          	jalr	-1578(ra) # 80000c98 <release>
    acquire(lk);
    800022ca:	854a                	mv	a0,s2
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	918080e7          	jalr	-1768(ra) # 80000be4 <acquire>
}
    800022d4:	70a2                	ld	ra,40(sp)
    800022d6:	7402                	ld	s0,32(sp)
    800022d8:	64e2                	ld	s1,24(sp)
    800022da:	6942                	ld	s2,16(sp)
    800022dc:	69a2                	ld	s3,8(sp)
    800022de:	6145                	addi	sp,sp,48
    800022e0:	8082                	ret

00000000800022e2 <wait>:
{
    800022e2:	715d                	addi	sp,sp,-80
    800022e4:	e486                	sd	ra,72(sp)
    800022e6:	e0a2                	sd	s0,64(sp)
    800022e8:	fc26                	sd	s1,56(sp)
    800022ea:	f84a                	sd	s2,48(sp)
    800022ec:	f44e                	sd	s3,40(sp)
    800022ee:	f052                	sd	s4,32(sp)
    800022f0:	ec56                	sd	s5,24(sp)
    800022f2:	e85a                	sd	s6,16(sp)
    800022f4:	e45e                	sd	s7,8(sp)
    800022f6:	e062                	sd	s8,0(sp)
    800022f8:	0880                	addi	s0,sp,80
    800022fa:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	842080e7          	jalr	-1982(ra) # 80001b3e <myproc>
    80002304:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002306:	0000f517          	auipc	a0,0xf
    8000230a:	fca50513          	addi	a0,a0,-54 # 800112d0 <wait_lock>
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	8d6080e7          	jalr	-1834(ra) # 80000be4 <acquire>
        havekids = 0;
    80002316:	4b81                	li	s7,0
                if (np->state == ZOMBIE)
    80002318:	4a15                	li	s4,5
        for (np = proc; np < &proc[NPROC]; np++)
    8000231a:	00016997          	auipc	s3,0x16
    8000231e:	5ce98993          	addi	s3,s3,1486 # 800188e8 <MLFQ_queue>
                havekids = 1;
    80002322:	4a85                	li	s5,1
        sleep(p, &wait_lock); //DOC: wait-sleep
    80002324:	0000fc17          	auipc	s8,0xf
    80002328:	facc0c13          	addi	s8,s8,-84 # 800112d0 <wait_lock>
        havekids = 0;
    8000232c:	875e                	mv	a4,s7
        for (np = proc; np < &proc[NPROC]; np++)
    8000232e:	0000f497          	auipc	s1,0xf
    80002332:	3ba48493          	addi	s1,s1,954 # 800116e8 <proc>
    80002336:	a0bd                	j	800023a4 <wait+0xc2>
                    pid = np->pid;
    80002338:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000233c:	000b0e63          	beqz	s6,80002358 <wait+0x76>
    80002340:	4691                	li	a3,4
    80002342:	02c48613          	addi	a2,s1,44
    80002346:	85da                	mv	a1,s6
    80002348:	05093503          	ld	a0,80(s2)
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	326080e7          	jalr	806(ra) # 80001672 <copyout>
    80002354:	02054563          	bltz	a0,8000237e <wait+0x9c>
                    freeproc(np);
    80002358:	8526                	mv	a0,s1
    8000235a:	00000097          	auipc	ra,0x0
    8000235e:	996080e7          	jalr	-1642(ra) # 80001cf0 <freeproc>
                    release(&np->lock);
    80002362:	8526                	mv	a0,s1
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	934080e7          	jalr	-1740(ra) # 80000c98 <release>
                    release(&wait_lock);
    8000236c:	0000f517          	auipc	a0,0xf
    80002370:	f6450513          	addi	a0,a0,-156 # 800112d0 <wait_lock>
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	924080e7          	jalr	-1756(ra) # 80000c98 <release>
                    return pid;
    8000237c:	a09d                	j	800023e2 <wait+0x100>
                        release(&np->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	918080e7          	jalr	-1768(ra) # 80000c98 <release>
                        release(&wait_lock);
    80002388:	0000f517          	auipc	a0,0xf
    8000238c:	f4850513          	addi	a0,a0,-184 # 800112d0 <wait_lock>
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	908080e7          	jalr	-1784(ra) # 80000c98 <release>
                        return -1;
    80002398:	59fd                	li	s3,-1
    8000239a:	a0a1                	j	800023e2 <wait+0x100>
        for (np = proc; np < &proc[NPROC]; np++)
    8000239c:	1c848493          	addi	s1,s1,456
    800023a0:	03348463          	beq	s1,s3,800023c8 <wait+0xe6>
            if (np->parent == p)
    800023a4:	7c9c                	ld	a5,56(s1)
    800023a6:	ff279be3          	bne	a5,s2,8000239c <wait+0xba>
                acquire(&np->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	838080e7          	jalr	-1992(ra) # 80000be4 <acquire>
                if (np->state == ZOMBIE)
    800023b4:	4c9c                	lw	a5,24(s1)
    800023b6:	f94781e3          	beq	a5,s4,80002338 <wait+0x56>
                release(&np->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8dc080e7          	jalr	-1828(ra) # 80000c98 <release>
                havekids = 1;
    800023c4:	8756                	mv	a4,s5
    800023c6:	bfd9                	j	8000239c <wait+0xba>
        if (!havekids || p->killed)
    800023c8:	c701                	beqz	a4,800023d0 <wait+0xee>
    800023ca:	02892783          	lw	a5,40(s2)
    800023ce:	c79d                	beqz	a5,800023fc <wait+0x11a>
            release(&wait_lock);
    800023d0:	0000f517          	auipc	a0,0xf
    800023d4:	f0050513          	addi	a0,a0,-256 # 800112d0 <wait_lock>
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	8c0080e7          	jalr	-1856(ra) # 80000c98 <release>
            return -1;
    800023e0:	59fd                	li	s3,-1
}
    800023e2:	854e                	mv	a0,s3
    800023e4:	60a6                	ld	ra,72(sp)
    800023e6:	6406                	ld	s0,64(sp)
    800023e8:	74e2                	ld	s1,56(sp)
    800023ea:	7942                	ld	s2,48(sp)
    800023ec:	79a2                	ld	s3,40(sp)
    800023ee:	7a02                	ld	s4,32(sp)
    800023f0:	6ae2                	ld	s5,24(sp)
    800023f2:	6b42                	ld	s6,16(sp)
    800023f4:	6ba2                	ld	s7,8(sp)
    800023f6:	6c02                	ld	s8,0(sp)
    800023f8:	6161                	addi	sp,sp,80
    800023fa:	8082                	ret
        sleep(p, &wait_lock); //DOC: wait-sleep
    800023fc:	85e2                	mv	a1,s8
    800023fe:	854a                	mv	a0,s2
    80002400:	00000097          	auipc	ra,0x0
    80002404:	e7e080e7          	jalr	-386(ra) # 8000227e <sleep>
        havekids = 0;
    80002408:	b715                	j	8000232c <wait+0x4a>

000000008000240a <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000240a:	7139                	addi	sp,sp,-64
    8000240c:	fc06                	sd	ra,56(sp)
    8000240e:	f822                	sd	s0,48(sp)
    80002410:	f426                	sd	s1,40(sp)
    80002412:	f04a                	sd	s2,32(sp)
    80002414:	ec4e                	sd	s3,24(sp)
    80002416:	e852                	sd	s4,16(sp)
    80002418:	e456                	sd	s5,8(sp)
    8000241a:	0080                	addi	s0,sp,64
    8000241c:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000241e:	0000f497          	auipc	s1,0xf
    80002422:	2ca48493          	addi	s1,s1,714 # 800116e8 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002426:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002428:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    8000242a:	00016917          	auipc	s2,0x16
    8000242e:	4be90913          	addi	s2,s2,1214 # 800188e8 <MLFQ_queue>
    80002432:	a821                	j	8000244a <wakeup+0x40>
                p->state = RUNNABLE;
    80002434:	0154ac23          	sw	s5,24(s1)
                p->cqueue = 0;
                p->mlfq_wtime = 0;
                push_to_queue(p, p->cqueue);
#endif
            }
            release(&p->lock);
    80002438:	8526                	mv	a0,s1
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	85e080e7          	jalr	-1954(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002442:	1c848493          	addi	s1,s1,456
    80002446:	03248463          	beq	s1,s2,8000246e <wakeup+0x64>
        if (p != myproc())
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	6f4080e7          	jalr	1780(ra) # 80001b3e <myproc>
    80002452:	fea488e3          	beq	s1,a0,80002442 <wakeup+0x38>
            acquire(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	ffffe097          	auipc	ra,0xffffe
    8000245c:	78c080e7          	jalr	1932(ra) # 80000be4 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002460:	4c9c                	lw	a5,24(s1)
    80002462:	fd379be3          	bne	a5,s3,80002438 <wakeup+0x2e>
    80002466:	709c                	ld	a5,32(s1)
    80002468:	fd4798e3          	bne	a5,s4,80002438 <wakeup+0x2e>
    8000246c:	b7e1                	j	80002434 <wakeup+0x2a>
        }
    }
}
    8000246e:	70e2                	ld	ra,56(sp)
    80002470:	7442                	ld	s0,48(sp)
    80002472:	74a2                	ld	s1,40(sp)
    80002474:	7902                	ld	s2,32(sp)
    80002476:	69e2                	ld	s3,24(sp)
    80002478:	6a42                	ld	s4,16(sp)
    8000247a:	6aa2                	ld	s5,8(sp)
    8000247c:	6121                	addi	sp,sp,64
    8000247e:	8082                	ret

0000000080002480 <reparent>:
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	e052                	sd	s4,0(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	25648493          	addi	s1,s1,598 # 800116e8 <proc>
            pp->parent = initproc;
    8000249a:	00007a17          	auipc	s4,0x7
    8000249e:	b8ea0a13          	addi	s4,s4,-1138 # 80009028 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024a2:	00016997          	auipc	s3,0x16
    800024a6:	44698993          	addi	s3,s3,1094 # 800188e8 <MLFQ_queue>
    800024aa:	a029                	j	800024b4 <reparent+0x34>
    800024ac:	1c848493          	addi	s1,s1,456
    800024b0:	01348d63          	beq	s1,s3,800024ca <reparent+0x4a>
        if (pp->parent == p)
    800024b4:	7c9c                	ld	a5,56(s1)
    800024b6:	ff279be3          	bne	a5,s2,800024ac <reparent+0x2c>
            pp->parent = initproc;
    800024ba:	000a3503          	ld	a0,0(s4)
    800024be:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	f4a080e7          	jalr	-182(ra) # 8000240a <wakeup>
    800024c8:	b7d5                	j	800024ac <reparent+0x2c>
}
    800024ca:	70a2                	ld	ra,40(sp)
    800024cc:	7402                	ld	s0,32(sp)
    800024ce:	64e2                	ld	s1,24(sp)
    800024d0:	6942                	ld	s2,16(sp)
    800024d2:	69a2                	ld	s3,8(sp)
    800024d4:	6a02                	ld	s4,0(sp)
    800024d6:	6145                	addi	sp,sp,48
    800024d8:	8082                	ret

00000000800024da <exit>:
{
    800024da:	7179                	addi	sp,sp,-48
    800024dc:	f406                	sd	ra,40(sp)
    800024de:	f022                	sd	s0,32(sp)
    800024e0:	ec26                	sd	s1,24(sp)
    800024e2:	e84a                	sd	s2,16(sp)
    800024e4:	e44e                	sd	s3,8(sp)
    800024e6:	e052                	sd	s4,0(sp)
    800024e8:	1800                	addi	s0,sp,48
    800024ea:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	652080e7          	jalr	1618(ra) # 80001b3e <myproc>
    800024f4:	89aa                	mv	s3,a0
    if (p == initproc)
    800024f6:	00007797          	auipc	a5,0x7
    800024fa:	b327b783          	ld	a5,-1230(a5) # 80009028 <initproc>
    800024fe:	0d050493          	addi	s1,a0,208
    80002502:	15050913          	addi	s2,a0,336
    80002506:	02a79363          	bne	a5,a0,8000252c <exit+0x52>
        panic("init exiting");
    8000250a:	00006517          	auipc	a0,0x6
    8000250e:	dce50513          	addi	a0,a0,-562 # 800082d8 <digits+0x298>
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	02c080e7          	jalr	44(ra) # 8000053e <panic>
            fileclose(f);
    8000251a:	00002097          	auipc	ra,0x2
    8000251e:	754080e7          	jalr	1876(ra) # 80004c6e <fileclose>
            p->ofile[fd] = 0;
    80002522:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002526:	04a1                	addi	s1,s1,8
    80002528:	01248563          	beq	s1,s2,80002532 <exit+0x58>
        if (p->ofile[fd])
    8000252c:	6088                	ld	a0,0(s1)
    8000252e:	f575                	bnez	a0,8000251a <exit+0x40>
    80002530:	bfdd                	j	80002526 <exit+0x4c>
    begin_op();
    80002532:	00002097          	auipc	ra,0x2
    80002536:	270080e7          	jalr	624(ra) # 800047a2 <begin_op>
    iput(p->cwd);
    8000253a:	1509b503          	ld	a0,336(s3)
    8000253e:	00002097          	auipc	ra,0x2
    80002542:	a4c080e7          	jalr	-1460(ra) # 80003f8a <iput>
    end_op();
    80002546:	00002097          	auipc	ra,0x2
    8000254a:	2dc080e7          	jalr	732(ra) # 80004822 <end_op>
    p->cwd = 0;
    8000254e:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002552:	0000f497          	auipc	s1,0xf
    80002556:	d7e48493          	addi	s1,s1,-642 # 800112d0 <wait_lock>
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	688080e7          	jalr	1672(ra) # 80000be4 <acquire>
    reparent(p);
    80002564:	854e                	mv	a0,s3
    80002566:	00000097          	auipc	ra,0x0
    8000256a:	f1a080e7          	jalr	-230(ra) # 80002480 <reparent>
    wakeup(p->parent);
    8000256e:	0389b503          	ld	a0,56(s3)
    80002572:	00000097          	auipc	ra,0x0
    80002576:	e98080e7          	jalr	-360(ra) # 8000240a <wakeup>
    acquire(&p->lock);
    8000257a:	854e                	mv	a0,s3
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	668080e7          	jalr	1640(ra) # 80000be4 <acquire>
    p->xstate = status;
    80002584:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002588:	4795                	li	a5,5
    8000258a:	00f9ac23          	sw	a5,24(s3)
    p->etime = ticks;
    8000258e:	00007797          	auipc	a5,0x7
    80002592:	aa27a783          	lw	a5,-1374(a5) # 80009030 <ticks>
    80002596:	18f9a823          	sw	a5,400(s3)
    release(&wait_lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	6fc080e7          	jalr	1788(ra) # 80000c98 <release>
    sched();
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	bc8080e7          	jalr	-1080(ra) # 8000216c <sched>
    panic("zombie exit");
    800025ac:	00006517          	auipc	a0,0x6
    800025b0:	d3c50513          	addi	a0,a0,-708 # 800082e8 <digits+0x2a8>
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	f8a080e7          	jalr	-118(ra) # 8000053e <panic>

00000000800025bc <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025bc:	7179                	addi	sp,sp,-48
    800025be:	f406                	sd	ra,40(sp)
    800025c0:	f022                	sd	s0,32(sp)
    800025c2:	ec26                	sd	s1,24(sp)
    800025c4:	e84a                	sd	s2,16(sp)
    800025c6:	e44e                	sd	s3,8(sp)
    800025c8:	1800                	addi	s0,sp,48
    800025ca:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800025cc:	0000f497          	auipc	s1,0xf
    800025d0:	11c48493          	addi	s1,s1,284 # 800116e8 <proc>
    800025d4:	00016997          	auipc	s3,0x16
    800025d8:	31498993          	addi	s3,s3,788 # 800188e8 <MLFQ_queue>
    {
        acquire(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	606080e7          	jalr	1542(ra) # 80000be4 <acquire>
        if (p->pid == pid)
    800025e6:	589c                	lw	a5,48(s1)
    800025e8:	01278d63          	beq	a5,s2,80002602 <kill+0x46>
#endif
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	6aa080e7          	jalr	1706(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800025f6:	1c848493          	addi	s1,s1,456
    800025fa:	ff3491e3          	bne	s1,s3,800025dc <kill+0x20>
    }
    return -1;
    800025fe:	557d                	li	a0,-1
    80002600:	a829                	j	8000261a <kill+0x5e>
            p->killed = 1;
    80002602:	4785                	li	a5,1
    80002604:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002606:	4c98                	lw	a4,24(s1)
    80002608:	4789                	li	a5,2
    8000260a:	00f70f63          	beq	a4,a5,80002628 <kill+0x6c>
            release(&p->lock);
    8000260e:	8526                	mv	a0,s1
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	688080e7          	jalr	1672(ra) # 80000c98 <release>
            return 0;
    80002618:	4501                	li	a0,0
}
    8000261a:	70a2                	ld	ra,40(sp)
    8000261c:	7402                	ld	s0,32(sp)
    8000261e:	64e2                	ld	s1,24(sp)
    80002620:	6942                	ld	s2,16(sp)
    80002622:	69a2                	ld	s3,8(sp)
    80002624:	6145                	addi	sp,sp,48
    80002626:	8082                	ret
                p->state = RUNNABLE;
    80002628:	478d                	li	a5,3
    8000262a:	cc9c                	sw	a5,24(s1)
    8000262c:	b7cd                	j	8000260e <kill+0x52>

000000008000262e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000262e:	7179                	addi	sp,sp,-48
    80002630:	f406                	sd	ra,40(sp)
    80002632:	f022                	sd	s0,32(sp)
    80002634:	ec26                	sd	s1,24(sp)
    80002636:	e84a                	sd	s2,16(sp)
    80002638:	e44e                	sd	s3,8(sp)
    8000263a:	e052                	sd	s4,0(sp)
    8000263c:	1800                	addi	s0,sp,48
    8000263e:	84aa                	mv	s1,a0
    80002640:	892e                	mv	s2,a1
    80002642:	89b2                	mv	s3,a2
    80002644:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	4f8080e7          	jalr	1272(ra) # 80001b3e <myproc>
    if (user_dst)
    8000264e:	c08d                	beqz	s1,80002670 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002650:	86d2                	mv	a3,s4
    80002652:	864e                	mv	a2,s3
    80002654:	85ca                	mv	a1,s2
    80002656:	6928                	ld	a0,80(a0)
    80002658:	fffff097          	auipc	ra,0xfffff
    8000265c:	01a080e7          	jalr	26(ra) # 80001672 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002660:	70a2                	ld	ra,40(sp)
    80002662:	7402                	ld	s0,32(sp)
    80002664:	64e2                	ld	s1,24(sp)
    80002666:	6942                	ld	s2,16(sp)
    80002668:	69a2                	ld	s3,8(sp)
    8000266a:	6a02                	ld	s4,0(sp)
    8000266c:	6145                	addi	sp,sp,48
    8000266e:	8082                	ret
        memmove((char *)dst, src, len);
    80002670:	000a061b          	sext.w	a2,s4
    80002674:	85ce                	mv	a1,s3
    80002676:	854a                	mv	a0,s2
    80002678:	ffffe097          	auipc	ra,0xffffe
    8000267c:	6c8080e7          	jalr	1736(ra) # 80000d40 <memmove>
        return 0;
    80002680:	8526                	mv	a0,s1
    80002682:	bff9                	j	80002660 <either_copyout+0x32>

0000000080002684 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002684:	7179                	addi	sp,sp,-48
    80002686:	f406                	sd	ra,40(sp)
    80002688:	f022                	sd	s0,32(sp)
    8000268a:	ec26                	sd	s1,24(sp)
    8000268c:	e84a                	sd	s2,16(sp)
    8000268e:	e44e                	sd	s3,8(sp)
    80002690:	e052                	sd	s4,0(sp)
    80002692:	1800                	addi	s0,sp,48
    80002694:	892a                	mv	s2,a0
    80002696:	84ae                	mv	s1,a1
    80002698:	89b2                	mv	s3,a2
    8000269a:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000269c:	fffff097          	auipc	ra,0xfffff
    800026a0:	4a2080e7          	jalr	1186(ra) # 80001b3e <myproc>
    if (user_src)
    800026a4:	c08d                	beqz	s1,800026c6 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800026a6:	86d2                	mv	a3,s4
    800026a8:	864e                	mv	a2,s3
    800026aa:	85ca                	mv	a1,s2
    800026ac:	6928                	ld	a0,80(a0)
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	050080e7          	jalr	80(ra) # 800016fe <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800026b6:	70a2                	ld	ra,40(sp)
    800026b8:	7402                	ld	s0,32(sp)
    800026ba:	64e2                	ld	s1,24(sp)
    800026bc:	6942                	ld	s2,16(sp)
    800026be:	69a2                	ld	s3,8(sp)
    800026c0:	6a02                	ld	s4,0(sp)
    800026c2:	6145                	addi	sp,sp,48
    800026c4:	8082                	ret
        memmove(dst, (char *)src, len);
    800026c6:	000a061b          	sext.w	a2,s4
    800026ca:	85ce                	mv	a1,s3
    800026cc:	854a                	mv	a0,s2
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	672080e7          	jalr	1650(ra) # 80000d40 <memmove>
        return 0;
    800026d6:	8526                	mv	a0,s1
    800026d8:	bff9                	j	800026b6 <either_copyin+0x32>

00000000800026da <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800026da:	715d                	addi	sp,sp,-80
    800026dc:	e486                	sd	ra,72(sp)
    800026de:	e0a2                	sd	s0,64(sp)
    800026e0:	fc26                	sd	s1,56(sp)
    800026e2:	f84a                	sd	s2,48(sp)
    800026e4:	f44e                	sd	s3,40(sp)
    800026e6:	f052                	sd	s4,32(sp)
    800026e8:	ec56                	sd	s5,24(sp)
    800026ea:	e85a                	sd	s6,16(sp)
    800026ec:	e45e                	sd	s7,8(sp)
    800026ee:	0880                	addi	s0,sp,80
        [RUNNABLE] "runble",
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    char *state;

    printf("\n");
    800026f0:	00006517          	auipc	a0,0x6
    800026f4:	9d850513          	addi	a0,a0,-1576 # 800080c8 <digits+0x88>
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	e90080e7          	jalr	-368(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002700:	0000f497          	auipc	s1,0xf
    80002704:	14048493          	addi	s1,s1,320 # 80011840 <proc+0x158>
    80002708:	00016917          	auipc	s2,0x16
    8000270c:	33890913          	addi	s2,s2,824 # 80018a40 <MLFQ_queue+0x158>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002710:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002712:	00006997          	auipc	s3,0x6
    80002716:	be698993          	addi	s3,s3,-1050 # 800082f8 <digits+0x2b8>
        printf("%d %s %s", p->pid, state, p->name);
    8000271a:	00006a97          	auipc	s5,0x6
    8000271e:	be6a8a93          	addi	s5,s5,-1050 # 80008300 <digits+0x2c0>

#ifdef PBS
        printf("%d\t\t%d\t\t%s\t\t%d\t\t%d\t\t%d\n", p->pid, p->static_priority, state, p->rtime_total, p->wtime_total, p->times_scheduled);
#endif
        printf("\n");
    80002722:	00006a17          	auipc	s4,0x6
    80002726:	9a6a0a13          	addi	s4,s4,-1626 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000272a:	00006b97          	auipc	s7,0x6
    8000272e:	c96b8b93          	addi	s7,s7,-874 # 800083c0 <states.1784>
    80002732:	a00d                	j	80002754 <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    80002734:	ed86a583          	lw	a1,-296(a3)
    80002738:	8556                	mv	a0,s5
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	e4e080e7          	jalr	-434(ra) # 80000588 <printf>
        printf("\n");
    80002742:	8552                	mv	a0,s4
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	e44080e7          	jalr	-444(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000274c:	1c848493          	addi	s1,s1,456
    80002750:	03248163          	beq	s1,s2,80002772 <procdump+0x98>
        if (p->state == UNUSED)
    80002754:	86a6                	mv	a3,s1
    80002756:	ec04a783          	lw	a5,-320(s1)
    8000275a:	dbed                	beqz	a5,8000274c <procdump+0x72>
            state = "???";
    8000275c:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275e:	fcfb6be3          	bltu	s6,a5,80002734 <procdump+0x5a>
    80002762:	1782                	slli	a5,a5,0x20
    80002764:	9381                	srli	a5,a5,0x20
    80002766:	078e                	slli	a5,a5,0x3
    80002768:	97de                	add	a5,a5,s7
    8000276a:	6390                	ld	a2,0(a5)
    8000276c:	f661                	bnez	a2,80002734 <procdump+0x5a>
            state = "???";
    8000276e:	864e                	mv	a2,s3
    80002770:	b7d1                	j	80002734 <procdump+0x5a>
    }
}
    80002772:	60a6                	ld	ra,72(sp)
    80002774:	6406                	ld	s0,64(sp)
    80002776:	74e2                	ld	s1,56(sp)
    80002778:	7942                	ld	s2,48(sp)
    8000277a:	79a2                	ld	s3,40(sp)
    8000277c:	7a02                	ld	s4,32(sp)
    8000277e:	6ae2                	ld	s5,24(sp)
    80002780:	6b42                	ld	s6,16(sp)
    80002782:	6ba2                	ld	s7,8(sp)
    80002784:	6161                	addi	sp,sp,80
    80002786:	8082                	ret

0000000080002788 <waitx>:
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002788:	711d                	addi	sp,sp,-96
    8000278a:	ec86                	sd	ra,88(sp)
    8000278c:	e8a2                	sd	s0,80(sp)
    8000278e:	e4a6                	sd	s1,72(sp)
    80002790:	e0ca                	sd	s2,64(sp)
    80002792:	fc4e                	sd	s3,56(sp)
    80002794:	f852                	sd	s4,48(sp)
    80002796:	f456                	sd	s5,40(sp)
    80002798:	f05a                	sd	s6,32(sp)
    8000279a:	ec5e                	sd	s7,24(sp)
    8000279c:	e862                	sd	s8,16(sp)
    8000279e:	e466                	sd	s9,8(sp)
    800027a0:	e06a                	sd	s10,0(sp)
    800027a2:	1080                	addi	s0,sp,96
    800027a4:	8b2a                	mv	s6,a0
    800027a6:	8bae                	mv	s7,a1
    800027a8:	8c32                	mv	s8,a2
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();
    800027aa:	fffff097          	auipc	ra,0xfffff
    800027ae:	394080e7          	jalr	916(ra) # 80001b3e <myproc>
    800027b2:	892a                	mv	s2,a0

    acquire(&wait_lock);
    800027b4:	0000f517          	auipc	a0,0xf
    800027b8:	b1c50513          	addi	a0,a0,-1252 # 800112d0 <wait_lock>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	428080e7          	jalr	1064(ra) # 80000be4 <acquire>

    for (;;)
    {
        // Scan through table looking for exited children.
        havekids = 0;
    800027c4:	4c81                	li	s9,0
            {
                // make sure the child isn't still in exit() or swtch().
                acquire(&np->lock);

                havekids = 1;
                if (np->state == ZOMBIE)
    800027c6:	4a15                	li	s4,5
        for (np = proc; np < &proc[NPROC]; np++)
    800027c8:	00016997          	auipc	s3,0x16
    800027cc:	12098993          	addi	s3,s3,288 # 800188e8 <MLFQ_queue>
                havekids = 1;
    800027d0:	4a85                	li	s5,1
            release(&wait_lock);
            return -1;
        }

        // Wait for a child to exit.
        sleep(p, &wait_lock); //DOC: wait-sleep
    800027d2:	0000fd17          	auipc	s10,0xf
    800027d6:	afed0d13          	addi	s10,s10,-1282 # 800112d0 <wait_lock>
        havekids = 0;
    800027da:	8766                	mv	a4,s9
        for (np = proc; np < &proc[NPROC]; np++)
    800027dc:	0000f497          	auipc	s1,0xf
    800027e0:	f0c48493          	addi	s1,s1,-244 # 800116e8 <proc>
    800027e4:	a059                	j	8000286a <waitx+0xe2>
                    pid = np->pid;
    800027e6:	0304a983          	lw	s3,48(s1)
                    *rtime = np->rtime_total;
    800027ea:	1884a703          	lw	a4,392(s1)
    800027ee:	00ec2023          	sw	a4,0(s8)
                    *wtime = np->etime - np->rtime_total - np->ctime;
    800027f2:	1684a783          	lw	a5,360(s1)
    800027f6:	9f3d                	addw	a4,a4,a5
    800027f8:	1904a783          	lw	a5,400(s1)
    800027fc:	9f99                	subw	a5,a5,a4
    800027fe:	00fba023          	sw	a5,0(s7)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002802:	000b0e63          	beqz	s6,8000281e <waitx+0x96>
    80002806:	4691                	li	a3,4
    80002808:	02c48613          	addi	a2,s1,44
    8000280c:	85da                	mv	a1,s6
    8000280e:	05093503          	ld	a0,80(s2)
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	e60080e7          	jalr	-416(ra) # 80001672 <copyout>
    8000281a:	02054563          	bltz	a0,80002844 <waitx+0xbc>
                    freeproc(np);
    8000281e:	8526                	mv	a0,s1
    80002820:	fffff097          	auipc	ra,0xfffff
    80002824:	4d0080e7          	jalr	1232(ra) # 80001cf0 <freeproc>
                    release(&np->lock);
    80002828:	8526                	mv	a0,s1
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	46e080e7          	jalr	1134(ra) # 80000c98 <release>
                    release(&wait_lock);
    80002832:	0000f517          	auipc	a0,0xf
    80002836:	a9e50513          	addi	a0,a0,-1378 # 800112d0 <wait_lock>
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	45e080e7          	jalr	1118(ra) # 80000c98 <release>
                    return pid;
    80002842:	a09d                	j	800028a8 <waitx+0x120>
                        release(&np->lock);
    80002844:	8526                	mv	a0,s1
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	452080e7          	jalr	1106(ra) # 80000c98 <release>
                        release(&wait_lock);
    8000284e:	0000f517          	auipc	a0,0xf
    80002852:	a8250513          	addi	a0,a0,-1406 # 800112d0 <wait_lock>
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	442080e7          	jalr	1090(ra) # 80000c98 <release>
                        return -1;
    8000285e:	59fd                	li	s3,-1
    80002860:	a0a1                	j	800028a8 <waitx+0x120>
        for (np = proc; np < &proc[NPROC]; np++)
    80002862:	1c848493          	addi	s1,s1,456
    80002866:	03348463          	beq	s1,s3,8000288e <waitx+0x106>
            if (np->parent == p)
    8000286a:	7c9c                	ld	a5,56(s1)
    8000286c:	ff279be3          	bne	a5,s2,80002862 <waitx+0xda>
                acquire(&np->lock);
    80002870:	8526                	mv	a0,s1
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	372080e7          	jalr	882(ra) # 80000be4 <acquire>
                if (np->state == ZOMBIE)
    8000287a:	4c9c                	lw	a5,24(s1)
    8000287c:	f74785e3          	beq	a5,s4,800027e6 <waitx+0x5e>
                release(&np->lock);
    80002880:	8526                	mv	a0,s1
    80002882:	ffffe097          	auipc	ra,0xffffe
    80002886:	416080e7          	jalr	1046(ra) # 80000c98 <release>
                havekids = 1;
    8000288a:	8756                	mv	a4,s5
    8000288c:	bfd9                	j	80002862 <waitx+0xda>
        if (!havekids || p->killed)
    8000288e:	c701                	beqz	a4,80002896 <waitx+0x10e>
    80002890:	02892783          	lw	a5,40(s2)
    80002894:	cb8d                	beqz	a5,800028c6 <waitx+0x13e>
            release(&wait_lock);
    80002896:	0000f517          	auipc	a0,0xf
    8000289a:	a3a50513          	addi	a0,a0,-1478 # 800112d0 <wait_lock>
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	3fa080e7          	jalr	1018(ra) # 80000c98 <release>
            return -1;
    800028a6:	59fd                	li	s3,-1
    }
}
    800028a8:	854e                	mv	a0,s3
    800028aa:	60e6                	ld	ra,88(sp)
    800028ac:	6446                	ld	s0,80(sp)
    800028ae:	64a6                	ld	s1,72(sp)
    800028b0:	6906                	ld	s2,64(sp)
    800028b2:	79e2                	ld	s3,56(sp)
    800028b4:	7a42                	ld	s4,48(sp)
    800028b6:	7aa2                	ld	s5,40(sp)
    800028b8:	7b02                	ld	s6,32(sp)
    800028ba:	6be2                	ld	s7,24(sp)
    800028bc:	6c42                	ld	s8,16(sp)
    800028be:	6ca2                	ld	s9,8(sp)
    800028c0:	6d02                	ld	s10,0(sp)
    800028c2:	6125                	addi	sp,sp,96
    800028c4:	8082                	ret
        sleep(p, &wait_lock); //DOC: wait-sleep
    800028c6:	85ea                	mv	a1,s10
    800028c8:	854a                	mv	a0,s2
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	9b4080e7          	jalr	-1612(ra) # 8000227e <sleep>
        havekids = 0;
    800028d2:	b721                	j	800027da <waitx+0x52>

00000000800028d4 <update_time>:

void update_time()
{
    800028d4:	711d                	addi	sp,sp,-96
    800028d6:	ec86                	sd	ra,88(sp)
    800028d8:	e8a2                	sd	s0,80(sp)
    800028da:	e4a6                	sd	s1,72(sp)
    800028dc:	e0ca                	sd	s2,64(sp)
    800028de:	fc4e                	sd	s3,56(sp)
    800028e0:	f852                	sd	s4,48(sp)
    800028e2:	f456                	sd	s5,40(sp)
    800028e4:	f05a                	sd	s6,32(sp)
    800028e6:	ec5e                	sd	s7,24(sp)
    800028e8:	e862                	sd	s8,16(sp)
    800028ea:	e466                	sd	s9,8(sp)
    800028ec:	1080                	addi	s0,sp,96
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    800028ee:	0000f497          	auipc	s1,0xf
    800028f2:	dfa48493          	addi	s1,s1,-518 # 800116e8 <proc>
    {
        acquire(&p->lock);

        if (p->state == RUNNING)
    800028f6:	4991                	li	s3,4
        {
            p->rtime_total++;
        }
        else if (p->state == SLEEPING)
    800028f8:	4a09                	li	s4,2
            p->stime_total++;
        else if (p->state == RUNNABLE)
    800028fa:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800028fc:	00016917          	auipc	s2,0x16
    80002900:	fec90913          	addi	s2,s2,-20 # 800188e8 <MLFQ_queue>
    80002904:	a839                	j	80002922 <update_time+0x4e>
            p->rtime_total++;
    80002906:	1884a783          	lw	a5,392(s1)
    8000290a:	2785                	addiw	a5,a5,1
    8000290c:	18f4a423          	sw	a5,392(s1)
            p->wtime_total++;

        release(&p->lock);
    80002910:	8526                	mv	a0,s1
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	386080e7          	jalr	902(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000291a:	1c848493          	addi	s1,s1,456
    8000291e:	03248a63          	beq	s1,s2,80002952 <update_time+0x7e>
        acquire(&p->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	2c0080e7          	jalr	704(ra) # 80000be4 <acquire>
        if (p->state == RUNNING)
    8000292c:	4c9c                	lw	a5,24(s1)
    8000292e:	fd378ce3          	beq	a5,s3,80002906 <update_time+0x32>
        else if (p->state == SLEEPING)
    80002932:	01478a63          	beq	a5,s4,80002946 <update_time+0x72>
        else if (p->state == RUNNABLE)
    80002936:	fd579de3          	bne	a5,s5,80002910 <update_time+0x3c>
            p->wtime_total++;
    8000293a:	1c44a783          	lw	a5,452(s1)
    8000293e:	2785                	addiw	a5,a5,1
    80002940:	1cf4a223          	sw	a5,452(s1)
    80002944:	b7f1                	j	80002910 <update_time+0x3c>
            p->stime_total++;
    80002946:	18c4a783          	lw	a5,396(s1)
    8000294a:	2785                	addiw	a5,a5,1
    8000294c:	18f4a623          	sw	a5,396(s1)
    80002950:	b7c1                	j	80002910 <update_time+0x3c>
    80002952:	0000fa97          	auipc	s5,0xf
    80002956:	94ea8a93          	addi	s5,s5,-1714 # 800112a0 <queue_size>
    8000295a:	00016b17          	auipc	s6,0x16
    8000295e:	f8eb0b13          	addi	s6,s6,-114 # 800188e8 <MLFQ_queue>
    80002962:	0000fc17          	auipc	s8,0xf
    80002966:	952c0c13          	addi	s8,s8,-1710 # 800112b4 <queue_size+0x14>
    }

    for (int q = 0; q < 5; q++)
    {
        for (int i = 0; i < queue_size[q]; i++)
    8000296a:	4b81                	li	s7,0
        {
            acquire(&MLFQ_queue[q][i]->lock);
            if (MLFQ_queue[q][i]->state == RUNNABLE)
    8000296c:	4a0d                	li	s4,3
    8000296e:	a0a9                	j	800029b8 <update_time+0xe4>
                MLFQ_queue[q][i]->mlfq_wtime++;
            release(&MLFQ_queue[q][i]->lock);
    80002970:	000cb503          	ld	a0,0(s9)
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	324080e7          	jalr	804(ra) # 80000c98 <release>
        for (int i = 0; i < queue_size[q]; i++)
    8000297c:	0019079b          	addiw	a5,s2,1
    80002980:	0007891b          	sext.w	s2,a5
    80002984:	04a1                	addi	s1,s1,8
    80002986:	0009a703          	lw	a4,0(s3)
    8000298a:	02e97263          	bgeu	s2,a4,800029ae <update_time+0xda>
            acquire(&MLFQ_queue[q][i]->lock);
    8000298e:	8ca6                	mv	s9,s1
    80002990:	6088                	ld	a0,0(s1)
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	252080e7          	jalr	594(ra) # 80000be4 <acquire>
            if (MLFQ_queue[q][i]->state == RUNNABLE)
    8000299a:	609c                	ld	a5,0(s1)
    8000299c:	4f98                	lw	a4,24(a5)
    8000299e:	fd4719e3          	bne	a4,s4,80002970 <update_time+0x9c>
                MLFQ_queue[q][i]->mlfq_wtime++;
    800029a2:	1bc7a703          	lw	a4,444(a5)
    800029a6:	2705                	addiw	a4,a4,1
    800029a8:	1ae7ae23          	sw	a4,444(a5)
    800029ac:	b7d1                	j	80002970 <update_time+0x9c>
    for (int q = 0; q < 5; q++)
    800029ae:	0a91                	addi	s5,s5,4
    800029b0:	200b0b13          	addi	s6,s6,512
    800029b4:	018a8963          	beq	s5,s8,800029c6 <update_time+0xf2>
        for (int i = 0; i < queue_size[q]; i++)
    800029b8:	89d6                	mv	s3,s5
    800029ba:	000aa783          	lw	a5,0(s5)
    800029be:	84da                	mv	s1,s6
    800029c0:	895e                	mv	s2,s7
    800029c2:	f7f1                	bnez	a5,8000298e <update_time+0xba>
    800029c4:	b7ed                	j	800029ae <update_time+0xda>
        }
    }
}
    800029c6:	60e6                	ld	ra,88(sp)
    800029c8:	6446                	ld	s0,80(sp)
    800029ca:	64a6                	ld	s1,72(sp)
    800029cc:	6906                	ld	s2,64(sp)
    800029ce:	79e2                	ld	s3,56(sp)
    800029d0:	7a42                	ld	s4,48(sp)
    800029d2:	7aa2                	ld	s5,40(sp)
    800029d4:	7b02                	ld	s6,32(sp)
    800029d6:	6be2                	ld	s7,24(sp)
    800029d8:	6c42                	ld	s8,16(sp)
    800029da:	6ca2                	ld	s9,8(sp)
    800029dc:	6125                	addi	sp,sp,96
    800029de:	8082                	ret

00000000800029e0 <updatetime>:
void updatetime()
{
    800029e0:	1101                	addi	sp,sp,-32
    800029e2:	ec06                	sd	ra,24(sp)
    800029e4:	e822                	sd	s0,16(sp)
    800029e6:	e426                	sd	s1,8(sp)
    800029e8:	e04a                	sd	s2,0(sp)
    800029ea:	1000                	addi	s0,sp,32
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    800029ec:	0000f497          	auipc	s1,0xf
    800029f0:	cfc48493          	addi	s1,s1,-772 # 800116e8 <proc>
    800029f4:	00016917          	auipc	s2,0x16
    800029f8:	ef490913          	addi	s2,s2,-268 # 800188e8 <MLFQ_queue>
    {
        acquire(&p->lock);
    800029fc:	8526                	mv	a0,s1
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	1e6080e7          	jalr	486(ra) # 80000be4 <acquire>
#ifdef MLFQ
            p->cqueue_time++;
            myproc()->ticks_in_queues[myproc()->cqueue]++;
#endif
        }
        release(&p->lock);
    80002a06:	8526                	mv	a0,s1
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	290080e7          	jalr	656(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002a10:	1c848493          	addi	s1,s1,456
    80002a14:	ff2494e3          	bne	s1,s2,800029fc <updatetime+0x1c>
    }
}
    80002a18:	60e2                	ld	ra,24(sp)
    80002a1a:	6442                	ld	s0,16(sp)
    80002a1c:	64a2                	ld	s1,8(sp)
    80002a1e:	6902                	ld	s2,0(sp)
    80002a20:	6105                	addi	sp,sp,32
    80002a22:	8082                	ret

0000000080002a24 <is_valid_priority>:

int is_valid_priority(int p)
{
    if (p >= 0 && p <= 100)
    80002a24:	06400793          	li	a5,100
    80002a28:	00a7e463          	bltu	a5,a0,80002a30 <is_valid_priority+0xc>
        return 1;
    80002a2c:	4505                	li	a0,1

    printf("Invalid Static Priority\n");
    return 0;
}
    80002a2e:	8082                	ret
{
    80002a30:	1141                	addi	sp,sp,-16
    80002a32:	e406                	sd	ra,8(sp)
    80002a34:	e022                	sd	s0,0(sp)
    80002a36:	0800                	addi	s0,sp,16
    printf("Invalid Static Priority\n");
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	8d850513          	addi	a0,a0,-1832 # 80008310 <digits+0x2d0>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b48080e7          	jalr	-1208(ra) # 80000588 <printf>
    return 0;
    80002a48:	4501                	li	a0,0
}
    80002a4a:	60a2                	ld	ra,8(sp)
    80002a4c:	6402                	ld	s0,0(sp)
    80002a4e:	0141                	addi	sp,sp,16
    80002a50:	8082                	ret

0000000080002a52 <set_priority>:

int set_priority(int new, int pid)
{
    80002a52:	7179                	addi	sp,sp,-48
    80002a54:	f406                	sd	ra,40(sp)
    80002a56:	f022                	sd	s0,32(sp)
    80002a58:	ec26                	sd	s1,24(sp)
    80002a5a:	e84a                	sd	s2,16(sp)
    80002a5c:	e44e                	sd	s3,8(sp)
    80002a5e:	e052                	sd	s4,0(sp)
    80002a60:	1800                	addi	s0,sp,48
    80002a62:	8a2a                	mv	s4,a0
    80002a64:	892e                	mv	s2,a1
    if (is_valid_priority(new) == 0)
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	fbe080e7          	jalr	-66(ra) # 80002a24 <is_valid_priority>
    80002a6e:	c151                	beqz	a0,80002af2 <set_priority+0xa0>

    int old = -1;
    int flag = 0;
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002a70:	0000f497          	auipc	s1,0xf
    80002a74:	c7848493          	addi	s1,s1,-904 # 800116e8 <proc>
    80002a78:	00016997          	auipc	s3,0x16
    80002a7c:	e7098993          	addi	s3,s3,-400 # 800188e8 <MLFQ_queue>
    {
        acquire(&p->lock);
    80002a80:	8526                	mv	a0,s1
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	162080e7          	jalr	354(ra) # 80000be4 <acquire>
        if (p->pid == pid)
    80002a8a:	589c                	lw	a5,48(s1)
    80002a8c:	03278663          	beq	a5,s2,80002ab8 <set_priority+0x66>
            flag = 1;
            old = p->static_priority;
            p->static_priority = new;
            break;
        }
        release(&p->lock);
    80002a90:	8526                	mv	a0,s1
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	206080e7          	jalr	518(ra) # 80000c98 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002a9a:	1c848493          	addi	s1,s1,456
    80002a9e:	ff3491e3          	bne	s1,s3,80002a80 <set_priority+0x2e>
    }

    if (flag == 0)
    {
        printf("No process with pid %d exists\n", pid);
    80002aa2:	85ca                	mv	a1,s2
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	8d450513          	addi	a0,a0,-1836 # 80008378 <digits+0x338>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	adc080e7          	jalr	-1316(ra) # 80000588 <printf>
        return -1;
    80002ab4:	59fd                	li	s3,-1
    80002ab6:	a02d                	j	80002ae0 <set_priority+0x8e>
            old = p->static_priority;
    80002ab8:	1704a983          	lw	s3,368(s1)
            p->static_priority = new;
    80002abc:	1744a823          	sw	s4,368(s1)
    }

    printf("Process PID = %d\n, Old Static Priority = %d \nNew Static Priority = %d\n", p->pid, old, new);
    80002ac0:	86d2                	mv	a3,s4
    80002ac2:	864e                	mv	a2,s3
    80002ac4:	85ca                	mv	a1,s2
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	86a50513          	addi	a0,a0,-1942 # 80008330 <digits+0x2f0>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	aba080e7          	jalr	-1350(ra) # 80000588 <printf>
    release(&p->lock);
    80002ad6:	8526                	mv	a0,s1
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	1c0080e7          	jalr	448(ra) # 80000c98 <release>
        yield(); //rescheduling
#endif
    }

    return old;
    80002ae0:	854e                	mv	a0,s3
    80002ae2:	70a2                	ld	ra,40(sp)
    80002ae4:	7402                	ld	s0,32(sp)
    80002ae6:	64e2                	ld	s1,24(sp)
    80002ae8:	6942                	ld	s2,16(sp)
    80002aea:	69a2                	ld	s3,8(sp)
    80002aec:	6a02                	ld	s4,0(sp)
    80002aee:	6145                	addi	sp,sp,48
    80002af0:	8082                	ret
        return -1;
    80002af2:	59fd                	li	s3,-1
    80002af4:	b7f5                	j	80002ae0 <set_priority+0x8e>

0000000080002af6 <swtch>:
    80002af6:	00153023          	sd	ra,0(a0)
    80002afa:	00253423          	sd	sp,8(a0)
    80002afe:	e900                	sd	s0,16(a0)
    80002b00:	ed04                	sd	s1,24(a0)
    80002b02:	03253023          	sd	s2,32(a0)
    80002b06:	03353423          	sd	s3,40(a0)
    80002b0a:	03453823          	sd	s4,48(a0)
    80002b0e:	03553c23          	sd	s5,56(a0)
    80002b12:	05653023          	sd	s6,64(a0)
    80002b16:	05753423          	sd	s7,72(a0)
    80002b1a:	05853823          	sd	s8,80(a0)
    80002b1e:	05953c23          	sd	s9,88(a0)
    80002b22:	07a53023          	sd	s10,96(a0)
    80002b26:	07b53423          	sd	s11,104(a0)
    80002b2a:	0005b083          	ld	ra,0(a1)
    80002b2e:	0085b103          	ld	sp,8(a1)
    80002b32:	6980                	ld	s0,16(a1)
    80002b34:	6d84                	ld	s1,24(a1)
    80002b36:	0205b903          	ld	s2,32(a1)
    80002b3a:	0285b983          	ld	s3,40(a1)
    80002b3e:	0305ba03          	ld	s4,48(a1)
    80002b42:	0385ba83          	ld	s5,56(a1)
    80002b46:	0405bb03          	ld	s6,64(a1)
    80002b4a:	0485bb83          	ld	s7,72(a1)
    80002b4e:	0505bc03          	ld	s8,80(a1)
    80002b52:	0585bc83          	ld	s9,88(a1)
    80002b56:	0605bd03          	ld	s10,96(a1)
    80002b5a:	0685bd83          	ld	s11,104(a1)
    80002b5e:	8082                	ret

0000000080002b60 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b60:	1141                	addi	sp,sp,-16
    80002b62:	e406                	sd	ra,8(sp)
    80002b64:	e022                	sd	s0,0(sp)
    80002b66:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b68:	00006597          	auipc	a1,0x6
    80002b6c:	88858593          	addi	a1,a1,-1912 # 800083f0 <states.1784+0x30>
    80002b70:	00016517          	auipc	a0,0x16
    80002b74:	77850513          	addi	a0,a0,1912 # 800192e8 <tickslock>
    80002b78:	ffffe097          	auipc	ra,0xffffe
    80002b7c:	fdc080e7          	jalr	-36(ra) # 80000b54 <initlock>
}
    80002b80:	60a2                	ld	ra,8(sp)
    80002b82:	6402                	ld	s0,0(sp)
    80002b84:	0141                	addi	sp,sp,16
    80002b86:	8082                	ret

0000000080002b88 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b88:	1141                	addi	sp,sp,-16
    80002b8a:	e422                	sd	s0,8(sp)
    80002b8c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b8e:	00003797          	auipc	a5,0x3
    80002b92:	70278793          	addi	a5,a5,1794 # 80006290 <kernelvec>
    80002b96:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b9a:	6422                	ld	s0,8(sp)
    80002b9c:	0141                	addi	sp,sp,16
    80002b9e:	8082                	ret

0000000080002ba0 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002ba0:	1141                	addi	sp,sp,-16
    80002ba2:	e406                	sd	ra,8(sp)
    80002ba4:	e022                	sd	s0,0(sp)
    80002ba6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	f96080e7          	jalr	-106(ra) # 80001b3e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bb4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bb6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002bba:	00004617          	auipc	a2,0x4
    80002bbe:	44660613          	addi	a2,a2,1094 # 80007000 <_trampoline>
    80002bc2:	00004697          	auipc	a3,0x4
    80002bc6:	43e68693          	addi	a3,a3,1086 # 80007000 <_trampoline>
    80002bca:	8e91                	sub	a3,a3,a2
    80002bcc:	040007b7          	lui	a5,0x4000
    80002bd0:	17fd                	addi	a5,a5,-1
    80002bd2:	07b2                	slli	a5,a5,0xc
    80002bd4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bd6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bda:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bdc:	180026f3          	csrr	a3,satp
    80002be0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002be2:	6d38                	ld	a4,88(a0)
    80002be4:	6134                	ld	a3,64(a0)
    80002be6:	6585                	lui	a1,0x1
    80002be8:	96ae                	add	a3,a3,a1
    80002bea:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bec:	6d38                	ld	a4,88(a0)
    80002bee:	00000697          	auipc	a3,0x0
    80002bf2:	14e68693          	addi	a3,a3,334 # 80002d3c <usertrap>
    80002bf6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002bf8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bfa:	8692                	mv	a3,tp
    80002bfc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfe:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c02:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c06:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c0e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c10:	6f18                	ld	a4,24(a4)
    80002c12:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c16:	692c                	ld	a1,80(a0)
    80002c18:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c1a:	00004717          	auipc	a4,0x4
    80002c1e:	47670713          	addi	a4,a4,1142 # 80007090 <userret>
    80002c22:	8f11                	sub	a4,a4,a2
    80002c24:	97ba                	add	a5,a5,a4
  ((void (*)(uint64, uint64))fn)(TRAPFRAME, satp);
    80002c26:	577d                	li	a4,-1
    80002c28:	177e                	slli	a4,a4,0x3f
    80002c2a:	8dd9                	or	a1,a1,a4
    80002c2c:	02000537          	lui	a0,0x2000
    80002c30:	157d                	addi	a0,a0,-1
    80002c32:	0536                	slli	a0,a0,0xd
    80002c34:	9782                	jalr	a5
}
    80002c36:	60a2                	ld	ra,8(sp)
    80002c38:	6402                	ld	s0,0(sp)
    80002c3a:	0141                	addi	sp,sp,16
    80002c3c:	8082                	ret

0000000080002c3e <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c3e:	1101                	addi	sp,sp,-32
    80002c40:	ec06                	sd	ra,24(sp)
    80002c42:	e822                	sd	s0,16(sp)
    80002c44:	e426                	sd	s1,8(sp)
    80002c46:	e04a                	sd	s2,0(sp)
    80002c48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c4a:	00016917          	auipc	s2,0x16
    80002c4e:	69e90913          	addi	s2,s2,1694 # 800192e8 <tickslock>
    80002c52:	854a                	mv	a0,s2
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	f90080e7          	jalr	-112(ra) # 80000be4 <acquire>
  ticks++;
    80002c5c:	00006497          	auipc	s1,0x6
    80002c60:	3d448493          	addi	s1,s1,980 # 80009030 <ticks>
    80002c64:	409c                	lw	a5,0(s1)
    80002c66:	2785                	addiw	a5,a5,1
    80002c68:	c09c                	sw	a5,0(s1)
  //traverse the process table
  // #ifdef MLFQ
  //   myproc()->cqueue_time++;
  //   myproc()->ticks_in_queues[myproc()->cqueue]++;
  // #endif
  update_time();
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	c6a080e7          	jalr	-918(ra) # 800028d4 <update_time>
  updatetime();
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	d6e080e7          	jalr	-658(ra) # 800029e0 <updatetime>
  wakeup(&ticks);
    80002c7a:	8526                	mv	a0,s1
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	78e080e7          	jalr	1934(ra) # 8000240a <wakeup>
  release(&tickslock);
    80002c84:	854a                	mv	a0,s2
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	012080e7          	jalr	18(ra) # 80000c98 <release>
}
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	64a2                	ld	s1,8(sp)
    80002c94:	6902                	ld	s2,0(sp)
    80002c96:	6105                	addi	sp,sp,32
    80002c98:	8082                	ret

0000000080002c9a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002c9a:	1101                	addi	sp,sp,-32
    80002c9c:	ec06                	sd	ra,24(sp)
    80002c9e:	e822                	sd	s0,16(sp)
    80002ca0:	e426                	sd	s1,8(sp)
    80002ca2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002ca8:	00074d63          	bltz	a4,80002cc2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002cac:	57fd                	li	a5,-1
    80002cae:	17fe                	slli	a5,a5,0x3f
    80002cb0:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002cb2:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002cb4:	06f70363          	beq	a4,a5,80002d1a <devintr+0x80>
  }
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6105                	addi	sp,sp,32
    80002cc0:	8082                	ret
      (scause & 0xff) == 9)
    80002cc2:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002cc6:	46a5                	li	a3,9
    80002cc8:	fed792e3          	bne	a5,a3,80002cac <devintr+0x12>
    int irq = plic_claim();
    80002ccc:	00003097          	auipc	ra,0x3
    80002cd0:	6cc080e7          	jalr	1740(ra) # 80006398 <plic_claim>
    80002cd4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002cd6:	47a9                	li	a5,10
    80002cd8:	02f50763          	beq	a0,a5,80002d06 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002cdc:	4785                	li	a5,1
    80002cde:	02f50963          	beq	a0,a5,80002d10 <devintr+0x76>
    return 1;
    80002ce2:	4505                	li	a0,1
    else if (irq)
    80002ce4:	d8f1                	beqz	s1,80002cb8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ce6:	85a6                	mv	a1,s1
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	71050513          	addi	a0,a0,1808 # 800083f8 <states.1784+0x38>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	898080e7          	jalr	-1896(ra) # 80000588 <printf>
      plic_complete(irq);
    80002cf8:	8526                	mv	a0,s1
    80002cfa:	00003097          	auipc	ra,0x3
    80002cfe:	6c2080e7          	jalr	1730(ra) # 800063bc <plic_complete>
    return 1;
    80002d02:	4505                	li	a0,1
    80002d04:	bf55                	j	80002cb8 <devintr+0x1e>
      uartintr();
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	ca2080e7          	jalr	-862(ra) # 800009a8 <uartintr>
    80002d0e:	b7ed                	j	80002cf8 <devintr+0x5e>
      virtio_disk_intr();
    80002d10:	00004097          	auipc	ra,0x4
    80002d14:	b8c080e7          	jalr	-1140(ra) # 8000689c <virtio_disk_intr>
    80002d18:	b7c5                	j	80002cf8 <devintr+0x5e>
    if (cpuid() == 0)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	df8080e7          	jalr	-520(ra) # 80001b12 <cpuid>
    80002d22:	c901                	beqz	a0,80002d32 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d24:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d2a:	14479073          	csrw	sip,a5
    return 2;
    80002d2e:	4509                	li	a0,2
    80002d30:	b761                	j	80002cb8 <devintr+0x1e>
      clockintr();
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	f0c080e7          	jalr	-244(ra) # 80002c3e <clockintr>
    80002d3a:	b7ed                	j	80002d24 <devintr+0x8a>

0000000080002d3c <usertrap>:
{
    80002d3c:	1101                	addi	sp,sp,-32
    80002d3e:	ec06                	sd	ra,24(sp)
    80002d40:	e822                	sd	s0,16(sp)
    80002d42:	e426                	sd	s1,8(sp)
    80002d44:	e04a                	sd	s2,0(sp)
    80002d46:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d48:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d4c:	1007f793          	andi	a5,a5,256
    80002d50:	e3ad                	bnez	a5,80002db2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d52:	00003797          	auipc	a5,0x3
    80002d56:	53e78793          	addi	a5,a5,1342 # 80006290 <kernelvec>
    80002d5a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	de0080e7          	jalr	-544(ra) # 80001b3e <myproc>
    80002d66:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d68:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6a:	14102773          	csrr	a4,sepc
    80002d6e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d70:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d74:	47a1                	li	a5,8
    80002d76:	04f71c63          	bne	a4,a5,80002dce <usertrap+0x92>
    if (p->killed)
    80002d7a:	551c                	lw	a5,40(a0)
    80002d7c:	e3b9                	bnez	a5,80002dc2 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002d7e:	6cb8                	ld	a4,88(s1)
    80002d80:	6f1c                	ld	a5,24(a4)
    80002d82:	0791                	addi	a5,a5,4
    80002d84:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d8e:	10079073          	csrw	sstatus,a5
    syscall();
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	2e0080e7          	jalr	736(ra) # 80003072 <syscall>
  if (p->killed)
    80002d9a:	549c                	lw	a5,40(s1)
    80002d9c:	ebc1                	bnez	a5,80002e2c <usertrap+0xf0>
  usertrapret();
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	e02080e7          	jalr	-510(ra) # 80002ba0 <usertrapret>
}
    80002da6:	60e2                	ld	ra,24(sp)
    80002da8:	6442                	ld	s0,16(sp)
    80002daa:	64a2                	ld	s1,8(sp)
    80002dac:	6902                	ld	s2,0(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret
    panic("usertrap: not from user mode");
    80002db2:	00005517          	auipc	a0,0x5
    80002db6:	66650513          	addi	a0,a0,1638 # 80008418 <states.1784+0x58>
    80002dba:	ffffd097          	auipc	ra,0xffffd
    80002dbe:	784080e7          	jalr	1924(ra) # 8000053e <panic>
      exit(-1);
    80002dc2:	557d                	li	a0,-1
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	716080e7          	jalr	1814(ra) # 800024da <exit>
    80002dcc:	bf4d                	j	80002d7e <usertrap+0x42>
  else if ((which_dev = devintr()) != 0)
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	ecc080e7          	jalr	-308(ra) # 80002c9a <devintr>
    80002dd6:	892a                	mv	s2,a0
    80002dd8:	c501                	beqz	a0,80002de0 <usertrap+0xa4>
  if (p->killed)
    80002dda:	549c                	lw	a5,40(s1)
    80002ddc:	c3a1                	beqz	a5,80002e1c <usertrap+0xe0>
    80002dde:	a815                	j	80002e12 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002de4:	5890                	lw	a2,48(s1)
    80002de6:	00005517          	auipc	a0,0x5
    80002dea:	65250513          	addi	a0,a0,1618 # 80008438 <states.1784+0x78>
    80002dee:	ffffd097          	auipc	ra,0xffffd
    80002df2:	79a080e7          	jalr	1946(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002df6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dfa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dfe:	00005517          	auipc	a0,0x5
    80002e02:	66a50513          	addi	a0,a0,1642 # 80008468 <states.1784+0xa8>
    80002e06:	ffffd097          	auipc	ra,0xffffd
    80002e0a:	782080e7          	jalr	1922(ra) # 80000588 <printf>
    p->killed = 1;
    80002e0e:	4785                	li	a5,1
    80002e10:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e12:	557d                	li	a0,-1
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	6c6080e7          	jalr	1734(ra) # 800024da <exit>
  if (which_dev == 2)
    80002e1c:	4789                	li	a5,2
    80002e1e:	f8f910e3          	bne	s2,a5,80002d9e <usertrap+0x62>
    yield();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	420080e7          	jalr	1056(ra) # 80002242 <yield>
    80002e2a:	bf95                	j	80002d9e <usertrap+0x62>
  int which_dev = 0;
    80002e2c:	4901                	li	s2,0
    80002e2e:	b7d5                	j	80002e12 <usertrap+0xd6>

0000000080002e30 <kerneltrap>:
{
    80002e30:	7179                	addi	sp,sp,-48
    80002e32:	f406                	sd	ra,40(sp)
    80002e34:	f022                	sd	s0,32(sp)
    80002e36:	ec26                	sd	s1,24(sp)
    80002e38:	e84a                	sd	s2,16(sp)
    80002e3a:	e44e                	sd	s3,8(sp)
    80002e3c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e3e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e42:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e46:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002e4a:	1004f793          	andi	a5,s1,256
    80002e4e:	cb85                	beqz	a5,80002e7e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e50:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e54:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002e56:	ef85                	bnez	a5,80002e8e <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	e42080e7          	jalr	-446(ra) # 80002c9a <devintr>
    80002e60:	cd1d                	beqz	a0,80002e9e <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e62:	4789                	li	a5,2
    80002e64:	06f50a63          	beq	a0,a5,80002ed8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e68:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e6c:	10049073          	csrw	sstatus,s1
}
    80002e70:	70a2                	ld	ra,40(sp)
    80002e72:	7402                	ld	s0,32(sp)
    80002e74:	64e2                	ld	s1,24(sp)
    80002e76:	6942                	ld	s2,16(sp)
    80002e78:	69a2                	ld	s3,8(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	60a50513          	addi	a0,a0,1546 # 80008488 <states.1784+0xc8>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	6b8080e7          	jalr	1720(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002e8e:	00005517          	auipc	a0,0x5
    80002e92:	62250513          	addi	a0,a0,1570 # 800084b0 <states.1784+0xf0>
    80002e96:	ffffd097          	auipc	ra,0xffffd
    80002e9a:	6a8080e7          	jalr	1704(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002e9e:	85ce                	mv	a1,s3
    80002ea0:	00005517          	auipc	a0,0x5
    80002ea4:	63050513          	addi	a0,a0,1584 # 800084d0 <states.1784+0x110>
    80002ea8:	ffffd097          	auipc	ra,0xffffd
    80002eac:	6e0080e7          	jalr	1760(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002eb4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002eb8:	00005517          	auipc	a0,0x5
    80002ebc:	62850513          	addi	a0,a0,1576 # 800084e0 <states.1784+0x120>
    80002ec0:	ffffd097          	auipc	ra,0xffffd
    80002ec4:	6c8080e7          	jalr	1736(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002ec8:	00005517          	auipc	a0,0x5
    80002ecc:	63050513          	addi	a0,a0,1584 # 800084f8 <states.1784+0x138>
    80002ed0:	ffffd097          	auipc	ra,0xffffd
    80002ed4:	66e080e7          	jalr	1646(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	c66080e7          	jalr	-922(ra) # 80001b3e <myproc>
    80002ee0:	d541                	beqz	a0,80002e68 <kerneltrap+0x38>
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	c5c080e7          	jalr	-932(ra) # 80001b3e <myproc>
    80002eea:	4d18                	lw	a4,24(a0)
    80002eec:	4791                	li	a5,4
    80002eee:	f6f71de3          	bne	a4,a5,80002e68 <kerneltrap+0x38>
    yield();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	350080e7          	jalr	848(ra) # 80002242 <yield>
    80002efa:	b7bd                	j	80002e68 <kerneltrap+0x38>

0000000080002efc <argraw>:
        return err;
    return strlen(buf);
}

static uint64
argraw(int n) {
    80002efc:	1101                	addi	sp,sp,-32
    80002efe:	ec06                	sd	ra,24(sp)
    80002f00:	e822                	sd	s0,16(sp)
    80002f02:	e426                	sd	s1,8(sp)
    80002f04:	1000                	addi	s0,sp,32
    80002f06:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	c36080e7          	jalr	-970(ra) # 80001b3e <myproc>
    switch (n) {
    80002f10:	4795                	li	a5,5
    80002f12:	0497e163          	bltu	a5,s1,80002f54 <argraw+0x58>
    80002f16:	048a                	slli	s1,s1,0x2
    80002f18:	00005717          	auipc	a4,0x5
    80002f1c:	70870713          	addi	a4,a4,1800 # 80008620 <states.1784+0x260>
    80002f20:	94ba                	add	s1,s1,a4
    80002f22:	409c                	lw	a5,0(s1)
    80002f24:	97ba                	add	a5,a5,a4
    80002f26:	8782                	jr	a5
        case 0:
            return p->trapframe->a0;
    80002f28:	6d3c                	ld	a5,88(a0)
    80002f2a:	7ba8                	ld	a0,112(a5)
        case 5:
            return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	64a2                	ld	s1,8(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret
            return p->trapframe->a1;
    80002f36:	6d3c                	ld	a5,88(a0)
    80002f38:	7fa8                	ld	a0,120(a5)
    80002f3a:	bfcd                	j	80002f2c <argraw+0x30>
            return p->trapframe->a2;
    80002f3c:	6d3c                	ld	a5,88(a0)
    80002f3e:	63c8                	ld	a0,128(a5)
    80002f40:	b7f5                	j	80002f2c <argraw+0x30>
            return p->trapframe->a3;
    80002f42:	6d3c                	ld	a5,88(a0)
    80002f44:	67c8                	ld	a0,136(a5)
    80002f46:	b7dd                	j	80002f2c <argraw+0x30>
            return p->trapframe->a4;
    80002f48:	6d3c                	ld	a5,88(a0)
    80002f4a:	6bc8                	ld	a0,144(a5)
    80002f4c:	b7c5                	j	80002f2c <argraw+0x30>
            return p->trapframe->a5;
    80002f4e:	6d3c                	ld	a5,88(a0)
    80002f50:	6fc8                	ld	a0,152(a5)
    80002f52:	bfe9                	j	80002f2c <argraw+0x30>
    panic("argraw");
    80002f54:	00005517          	auipc	a0,0x5
    80002f58:	5b450513          	addi	a0,a0,1460 # 80008508 <states.1784+0x148>
    80002f5c:	ffffd097          	auipc	ra,0xffffd
    80002f60:	5e2080e7          	jalr	1506(ra) # 8000053e <panic>

0000000080002f64 <fetchaddr>:
int fetchaddr(uint64 addr, uint64 *ip) {
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	e426                	sd	s1,8(sp)
    80002f6c:	e04a                	sd	s2,0(sp)
    80002f6e:	1000                	addi	s0,sp,32
    80002f70:	84aa                	mv	s1,a0
    80002f72:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f74:	fffff097          	auipc	ra,0xfffff
    80002f78:	bca080e7          	jalr	-1078(ra) # 80001b3e <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002f7c:	653c                	ld	a5,72(a0)
    80002f7e:	02f4f863          	bgeu	s1,a5,80002fae <fetchaddr+0x4a>
    80002f82:	00848713          	addi	a4,s1,8
    80002f86:	02e7e663          	bltu	a5,a4,80002fb2 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *) ip, addr, sizeof(*ip)) != 0)
    80002f8a:	46a1                	li	a3,8
    80002f8c:	8626                	mv	a2,s1
    80002f8e:	85ca                	mv	a1,s2
    80002f90:	6928                	ld	a0,80(a0)
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	76c080e7          	jalr	1900(ra) # 800016fe <copyin>
    80002f9a:	00a03533          	snez	a0,a0
    80002f9e:	40a00533          	neg	a0,a0
}
    80002fa2:	60e2                	ld	ra,24(sp)
    80002fa4:	6442                	ld	s0,16(sp)
    80002fa6:	64a2                	ld	s1,8(sp)
    80002fa8:	6902                	ld	s2,0(sp)
    80002faa:	6105                	addi	sp,sp,32
    80002fac:	8082                	ret
        return -1;
    80002fae:	557d                	li	a0,-1
    80002fb0:	bfcd                	j	80002fa2 <fetchaddr+0x3e>
    80002fb2:	557d                	li	a0,-1
    80002fb4:	b7fd                	j	80002fa2 <fetchaddr+0x3e>

0000000080002fb6 <fetchstr>:
int fetchstr(uint64 addr, char *buf, int max) {
    80002fb6:	7179                	addi	sp,sp,-48
    80002fb8:	f406                	sd	ra,40(sp)
    80002fba:	f022                	sd	s0,32(sp)
    80002fbc:	ec26                	sd	s1,24(sp)
    80002fbe:	e84a                	sd	s2,16(sp)
    80002fc0:	e44e                	sd	s3,8(sp)
    80002fc2:	1800                	addi	s0,sp,48
    80002fc4:	892a                	mv	s2,a0
    80002fc6:	84ae                	mv	s1,a1
    80002fc8:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	b74080e7          	jalr	-1164(ra) # 80001b3e <myproc>
    int err = copyinstr(p->pagetable, buf, addr, max);
    80002fd2:	86ce                	mv	a3,s3
    80002fd4:	864a                	mv	a2,s2
    80002fd6:	85a6                	mv	a1,s1
    80002fd8:	6928                	ld	a0,80(a0)
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	7b0080e7          	jalr	1968(ra) # 8000178a <copyinstr>
    if (err < 0)
    80002fe2:	00054763          	bltz	a0,80002ff0 <fetchstr+0x3a>
    return strlen(buf);
    80002fe6:	8526                	mv	a0,s1
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	e7c080e7          	jalr	-388(ra) # 80000e64 <strlen>
}
    80002ff0:	70a2                	ld	ra,40(sp)
    80002ff2:	7402                	ld	s0,32(sp)
    80002ff4:	64e2                	ld	s1,24(sp)
    80002ff6:	6942                	ld	s2,16(sp)
    80002ff8:	69a2                	ld	s3,8(sp)
    80002ffa:	6145                	addi	sp,sp,48
    80002ffc:	8082                	ret

0000000080002ffe <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip) {
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	1000                	addi	s0,sp,32
    80003008:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	ef2080e7          	jalr	-270(ra) # 80002efc <argraw>
    80003012:	c088                	sw	a0,0(s1)
    return 0;
}
    80003014:	4501                	li	a0,0
    80003016:	60e2                	ld	ra,24(sp)
    80003018:	6442                	ld	s0,16(sp)
    8000301a:	64a2                	ld	s1,8(sp)
    8000301c:	6105                	addi	sp,sp,32
    8000301e:	8082                	ret

0000000080003020 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip) {
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
    8000302a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	ed0080e7          	jalr	-304(ra) # 80002efc <argraw>
    80003034:	e088                	sd	a0,0(s1)
    return 0;
}
    80003036:	4501                	li	a0,0
    80003038:	60e2                	ld	ra,24(sp)
    8000303a:	6442                	ld	s0,16(sp)
    8000303c:	64a2                	ld	s1,8(sp)
    8000303e:	6105                	addi	sp,sp,32
    80003040:	8082                	ret

0000000080003042 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max) {
    80003042:	1101                	addi	sp,sp,-32
    80003044:	ec06                	sd	ra,24(sp)
    80003046:	e822                	sd	s0,16(sp)
    80003048:	e426                	sd	s1,8(sp)
    8000304a:	e04a                	sd	s2,0(sp)
    8000304c:	1000                	addi	s0,sp,32
    8000304e:	84ae                	mv	s1,a1
    80003050:	8932                	mv	s2,a2
    *ip = argraw(n);
    80003052:	00000097          	auipc	ra,0x0
    80003056:	eaa080e7          	jalr	-342(ra) # 80002efc <argraw>
    uint64 addr;
    if (argaddr(n, &addr) < 0)
        return -1;
    return fetchstr(addr, buf, max);
    8000305a:	864a                	mv	a2,s2
    8000305c:	85a6                	mv	a1,s1
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	f58080e7          	jalr	-168(ra) # 80002fb6 <fetchstr>
}
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	64a2                	ld	s1,8(sp)
    8000306c:	6902                	ld	s2,0(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <syscall>:
        [SYS_trace] 1,
        [SYS_waitx] 3,
        [SYS_set_priority] 2,
};

void syscall(void) {
    80003072:	7119                	addi	sp,sp,-128
    80003074:	fc86                	sd	ra,120(sp)
    80003076:	f8a2                	sd	s0,112(sp)
    80003078:	f4a6                	sd	s1,104(sp)
    8000307a:	f0ca                	sd	s2,96(sp)
    8000307c:	ecce                	sd	s3,88(sp)
    8000307e:	e8d2                	sd	s4,80(sp)
    80003080:	e4d6                	sd	s5,72(sp)
    80003082:	e0da                	sd	s6,64(sp)
    80003084:	fc5e                	sd	s7,56(sp)
    80003086:	f862                	sd	s8,48(sp)
    80003088:	f466                	sd	s9,40(sp)
    8000308a:	f06a                	sd	s10,32(sp)
    8000308c:	ec6e                	sd	s11,24(sp)
    8000308e:	0100                	addi	s0,sp,128
    int num;
    struct proc *p = myproc();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	aae080e7          	jalr	-1362(ra) # 80001b3e <myproc>
    80003098:	892a                	mv	s2,a0

    num = p->trapframe->a7;
    8000309a:	6d24                	ld	s1,88(a0)
    8000309c:	74dc                	ld	a5,168(s1)
    8000309e:	0007899b          	sext.w	s3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030a2:	37fd                	addiw	a5,a5,-1
    800030a4:	475d                	li	a4,23
    800030a6:	12f76163          	bltu	a4,a5,800031c8 <syscall+0x156>
    800030aa:	00399713          	slli	a4,s3,0x3
    800030ae:	00005797          	auipc	a5,0x5
    800030b2:	58a78793          	addi	a5,a5,1418 # 80008638 <syscalls>
    800030b6:	97ba                	add	a5,a5,a4
    800030b8:	639c                	ld	a5,0(a5)
    800030ba:	10078763          	beqz	a5,800031c8 <syscall+0x156>
        // get the return value from the syscall
        int register0 = p->trapframe->a0;
    800030be:	0704ba03          	ld	s4,112(s1)
        int register1 = p->trapframe->a1;
    800030c2:	0784bb83          	ld	s7,120(s1)
        int register2 = p->trapframe->a2;
    800030c6:	0804bc03          	ld	s8,128(s1)
        int register3 = p->trapframe->a3;
    800030ca:	0884bb03          	ld	s6,136(s1)
        int register4 = p->trapframe->a4;
    800030ce:	0904ba83          	ld	s5,144(s1)
        p->trapframe->a0 = syscalls[num]();
    800030d2:	9782                	jalr	a5
    800030d4:	f8a8                	sd	a0,112(s1)

        if (p->mask >> num & 0x1) {
    800030d6:	16c92783          	lw	a5,364(s2)
    800030da:	4137d7bb          	sraw	a5,a5,s3
    800030de:	8b85                	andi	a5,a5,1
    800030e0:	10078563          	beqz	a5,800031ea <syscall+0x178>
            printf("%d: syscall %s ( ", p->pid, syscall_list[num]);
    800030e4:	00006497          	auipc	s1,0x6
    800030e8:	97448493          	addi	s1,s1,-1676 # 80008a58 <syscall_list>
    800030ec:	00399793          	slli	a5,s3,0x3
    800030f0:	97a6                	add	a5,a5,s1
    800030f2:	6390                	ld	a2,0(a5)
    800030f4:	03092583          	lw	a1,48(s2)
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	41850513          	addi	a0,a0,1048 # 80008510 <states.1784+0x150>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	488080e7          	jalr	1160(ra) # 80000588 <printf>
            for (int i = 0; i < syscall_arg_count[num]; i++) {
    80003108:	00299793          	slli	a5,s3,0x2
    8000310c:	94be                	add	s1,s1,a5
    8000310e:	0c84a783          	lw	a5,200(s1)
    80003112:	08f05f63          	blez	a5,800031b0 <syscall+0x13e>
        int register0 = p->trapframe->a0;
    80003116:	2a01                	sext.w	s4,s4
        int register1 = p->trapframe->a1;
    80003118:	2b81                	sext.w	s7,s7
        int register2 = p->trapframe->a2;
    8000311a:	2c01                	sext.w	s8,s8
        int register3 = p->trapframe->a3;
    8000311c:	000b079b          	sext.w	a5,s6
    80003120:	f8f43423          	sd	a5,-120(s0)
        int register4 = p->trapframe->a4;
    80003124:	000a879b          	sext.w	a5,s5
    80003128:	f8f43023          	sd	a5,-128(s0)
            for (int i = 0; i < syscall_arg_count[num]; i++) {
    8000312c:	4481                	li	s1,0
                if (i == 0)
                    printf("%d ", register0);
                else if (i == 1)
    8000312e:	4b05                	li	s6,1
                    printf("%d ", register1);
                else if (i == 2)
    80003130:	4c89                	li	s9,2
                    printf("%d ", register2);
                else if (i == 3)
    80003132:	4d0d                	li	s10,3
                    printf("%d ", register3);
                else if (i == 4)
    80003134:	4d91                	li	s11,4
                    printf("%d ", register4);
    80003136:	00005a97          	auipc	s5,0x5
    8000313a:	3f2a8a93          	addi	s5,s5,1010 # 80008528 <states.1784+0x168>
            for (int i = 0; i < syscall_arg_count[num]; i++) {
    8000313e:	098a                	slli	s3,s3,0x2
    80003140:	00006797          	auipc	a5,0x6
    80003144:	91878793          	addi	a5,a5,-1768 # 80008a58 <syscall_list>
    80003148:	99be                	add	s3,s3,a5
    8000314a:	a821                	j	80003162 <syscall+0xf0>
                    printf("%d ", register0);
    8000314c:	85d2                	mv	a1,s4
    8000314e:	8556                	mv	a0,s5
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	438080e7          	jalr	1080(ra) # 80000588 <printf>
            for (int i = 0; i < syscall_arg_count[num]; i++) {
    80003158:	2485                	addiw	s1,s1,1
    8000315a:	0c89a783          	lw	a5,200(s3)
    8000315e:	04f4d963          	bge	s1,a5,800031b0 <syscall+0x13e>
                if (i == 0)
    80003162:	d4ed                	beqz	s1,8000314c <syscall+0xda>
                else if (i == 1)
    80003164:	03648063          	beq	s1,s6,80003184 <syscall+0x112>
                else if (i == 2)
    80003168:	03948563          	beq	s1,s9,80003192 <syscall+0x120>
                else if (i == 3)
    8000316c:	03a48a63          	beq	s1,s10,800031a0 <syscall+0x12e>
                else if (i == 4)
    80003170:	ffb494e3          	bne	s1,s11,80003158 <syscall+0xe6>
                    printf("%d ", register4);
    80003174:	f8043583          	ld	a1,-128(s0)
    80003178:	8556                	mv	a0,s5
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	40e080e7          	jalr	1038(ra) # 80000588 <printf>
    80003182:	bfd9                	j	80003158 <syscall+0xe6>
                    printf("%d ", register1);
    80003184:	85de                	mv	a1,s7
    80003186:	8556                	mv	a0,s5
    80003188:	ffffd097          	auipc	ra,0xffffd
    8000318c:	400080e7          	jalr	1024(ra) # 80000588 <printf>
    80003190:	b7e1                	j	80003158 <syscall+0xe6>
                    printf("%d ", register2);
    80003192:	85e2                	mv	a1,s8
    80003194:	8556                	mv	a0,s5
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	3f2080e7          	jalr	1010(ra) # 80000588 <printf>
    8000319e:	bf6d                	j	80003158 <syscall+0xe6>
                    printf("%d ", register3);
    800031a0:	f8843583          	ld	a1,-120(s0)
    800031a4:	8556                	mv	a0,s5
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	3e2080e7          	jalr	994(ra) # 80000588 <printf>
    800031ae:	b76d                	j	80003158 <syscall+0xe6>
            }
            printf(") -> %d\n", p->trapframe->a0);
    800031b0:	05893783          	ld	a5,88(s2)
    800031b4:	7bac                	ld	a1,112(a5)
    800031b6:	00005517          	auipc	a0,0x5
    800031ba:	37a50513          	addi	a0,a0,890 # 80008530 <states.1784+0x170>
    800031be:	ffffd097          	auipc	ra,0xffffd
    800031c2:	3ca080e7          	jalr	970(ra) # 80000588 <printf>
    800031c6:	a015                	j	800031ea <syscall+0x178>
        }
    } else {
        printf("%d %s: unknown sys call %d\n",
    800031c8:	86ce                	mv	a3,s3
    800031ca:	15890613          	addi	a2,s2,344
    800031ce:	03092583          	lw	a1,48(s2)
    800031d2:	00005517          	auipc	a0,0x5
    800031d6:	36e50513          	addi	a0,a0,878 # 80008540 <states.1784+0x180>
    800031da:	ffffd097          	auipc	ra,0xffffd
    800031de:	3ae080e7          	jalr	942(ra) # 80000588 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800031e2:	05893783          	ld	a5,88(s2)
    800031e6:	577d                	li	a4,-1
    800031e8:	fbb8                	sd	a4,112(a5)
    }
}
    800031ea:	70e6                	ld	ra,120(sp)
    800031ec:	7446                	ld	s0,112(sp)
    800031ee:	74a6                	ld	s1,104(sp)
    800031f0:	7906                	ld	s2,96(sp)
    800031f2:	69e6                	ld	s3,88(sp)
    800031f4:	6a46                	ld	s4,80(sp)
    800031f6:	6aa6                	ld	s5,72(sp)
    800031f8:	6b06                	ld	s6,64(sp)
    800031fa:	7be2                	ld	s7,56(sp)
    800031fc:	7c42                	ld	s8,48(sp)
    800031fe:	7ca2                	ld	s9,40(sp)
    80003200:	7d02                	ld	s10,32(sp)
    80003202:	6de2                	ld	s11,24(sp)
    80003204:	6109                	addi	sp,sp,128
    80003206:	8082                	ret

0000000080003208 <sys_exit>:
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void) {
    80003208:	1101                	addi	sp,sp,-32
    8000320a:	ec06                	sd	ra,24(sp)
    8000320c:	e822                	sd	s0,16(sp)
    8000320e:	1000                	addi	s0,sp,32
    int n;
    if (argint(0, &n) < 0)
    80003210:	fec40593          	addi	a1,s0,-20
    80003214:	4501                	li	a0,0
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	de8080e7          	jalr	-536(ra) # 80002ffe <argint>
        return -1;
    8000321e:	57fd                	li	a5,-1
    if (argint(0, &n) < 0)
    80003220:	00054963          	bltz	a0,80003232 <sys_exit+0x2a>
    exit(n);
    80003224:	fec42503          	lw	a0,-20(s0)
    80003228:	fffff097          	auipc	ra,0xfffff
    8000322c:	2b2080e7          	jalr	690(ra) # 800024da <exit>
    return 0; // not reached
    80003230:	4781                	li	a5,0
}
    80003232:	853e                	mv	a0,a5
    80003234:	60e2                	ld	ra,24(sp)
    80003236:	6442                	ld	s0,16(sp)
    80003238:	6105                	addi	sp,sp,32
    8000323a:	8082                	ret

000000008000323c <sys_getpid>:

uint64
sys_getpid(void) {
    8000323c:	1141                	addi	sp,sp,-16
    8000323e:	e406                	sd	ra,8(sp)
    80003240:	e022                	sd	s0,0(sp)
    80003242:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003244:	fffff097          	auipc	ra,0xfffff
    80003248:	8fa080e7          	jalr	-1798(ra) # 80001b3e <myproc>
}
    8000324c:	5908                	lw	a0,48(a0)
    8000324e:	60a2                	ld	ra,8(sp)
    80003250:	6402                	ld	s0,0(sp)
    80003252:	0141                	addi	sp,sp,16
    80003254:	8082                	ret

0000000080003256 <sys_fork>:

uint64
sys_fork(void) {
    80003256:	1141                	addi	sp,sp,-16
    80003258:	e406                	sd	ra,8(sp)
    8000325a:	e022                	sd	s0,0(sp)
    8000325c:	0800                	addi	s0,sp,16
    return fork();
    8000325e:	fffff097          	auipc	ra,0xfffff
    80003262:	d1e080e7          	jalr	-738(ra) # 80001f7c <fork>
}
    80003266:	60a2                	ld	ra,8(sp)
    80003268:	6402                	ld	s0,0(sp)
    8000326a:	0141                	addi	sp,sp,16
    8000326c:	8082                	ret

000000008000326e <sys_wait>:

uint64
sys_wait(void) {
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	1000                	addi	s0,sp,32
    uint64 p;
    if (argaddr(0, &p) < 0)
    80003276:	fe840593          	addi	a1,s0,-24
    8000327a:	4501                	li	a0,0
    8000327c:	00000097          	auipc	ra,0x0
    80003280:	da4080e7          	jalr	-604(ra) # 80003020 <argaddr>
    80003284:	87aa                	mv	a5,a0
        return -1;
    80003286:	557d                	li	a0,-1
    if (argaddr(0, &p) < 0)
    80003288:	0007c863          	bltz	a5,80003298 <sys_wait+0x2a>
    return wait(p);
    8000328c:	fe843503          	ld	a0,-24(s0)
    80003290:	fffff097          	auipc	ra,0xfffff
    80003294:	052080e7          	jalr	82(ra) # 800022e2 <wait>
}
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret

00000000800032a0 <sys_sbrk>:

uint64
sys_sbrk(void) {
    800032a0:	7179                	addi	sp,sp,-48
    800032a2:	f406                	sd	ra,40(sp)
    800032a4:	f022                	sd	s0,32(sp)
    800032a6:	ec26                	sd	s1,24(sp)
    800032a8:	1800                	addi	s0,sp,48
    int addr;
    int n;

    if (argint(0, &n) < 0)
    800032aa:	fdc40593          	addi	a1,s0,-36
    800032ae:	4501                	li	a0,0
    800032b0:	00000097          	auipc	ra,0x0
    800032b4:	d4e080e7          	jalr	-690(ra) # 80002ffe <argint>
    800032b8:	87aa                	mv	a5,a0
        return -1;
    800032ba:	557d                	li	a0,-1
    if (argint(0, &n) < 0)
    800032bc:	0207c063          	bltz	a5,800032dc <sys_sbrk+0x3c>
    addr = myproc()->sz;
    800032c0:	fffff097          	auipc	ra,0xfffff
    800032c4:	87e080e7          	jalr	-1922(ra) # 80001b3e <myproc>
    800032c8:	4524                	lw	s1,72(a0)
    if (growproc(n) < 0)
    800032ca:	fdc42503          	lw	a0,-36(s0)
    800032ce:	fffff097          	auipc	ra,0xfffff
    800032d2:	c3a080e7          	jalr	-966(ra) # 80001f08 <growproc>
    800032d6:	00054863          	bltz	a0,800032e6 <sys_sbrk+0x46>
        return -1;
    return addr;
    800032da:	8526                	mv	a0,s1
}
    800032dc:	70a2                	ld	ra,40(sp)
    800032de:	7402                	ld	s0,32(sp)
    800032e0:	64e2                	ld	s1,24(sp)
    800032e2:	6145                	addi	sp,sp,48
    800032e4:	8082                	ret
        return -1;
    800032e6:	557d                	li	a0,-1
    800032e8:	bfd5                	j	800032dc <sys_sbrk+0x3c>

00000000800032ea <sys_sleep>:

uint64
sys_sleep(void) {
    800032ea:	7139                	addi	sp,sp,-64
    800032ec:	fc06                	sd	ra,56(sp)
    800032ee:	f822                	sd	s0,48(sp)
    800032f0:	f426                	sd	s1,40(sp)
    800032f2:	f04a                	sd	s2,32(sp)
    800032f4:	ec4e                	sd	s3,24(sp)
    800032f6:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    if (argint(0, &n) < 0)
    800032f8:	fcc40593          	addi	a1,s0,-52
    800032fc:	4501                	li	a0,0
    800032fe:	00000097          	auipc	ra,0x0
    80003302:	d00080e7          	jalr	-768(ra) # 80002ffe <argint>
        return -1;
    80003306:	57fd                	li	a5,-1
    if (argint(0, &n) < 0)
    80003308:	06054563          	bltz	a0,80003372 <sys_sleep+0x88>
    acquire(&tickslock);
    8000330c:	00016517          	auipc	a0,0x16
    80003310:	fdc50513          	addi	a0,a0,-36 # 800192e8 <tickslock>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	8d0080e7          	jalr	-1840(ra) # 80000be4 <acquire>
    ticks0 = ticks;
    8000331c:	00006917          	auipc	s2,0x6
    80003320:	d1492903          	lw	s2,-748(s2) # 80009030 <ticks>
    while (ticks - ticks0 < n) {
    80003324:	fcc42783          	lw	a5,-52(s0)
    80003328:	cf85                	beqz	a5,80003360 <sys_sleep+0x76>
        if (myproc()->killed) {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    8000332a:	00016997          	auipc	s3,0x16
    8000332e:	fbe98993          	addi	s3,s3,-66 # 800192e8 <tickslock>
    80003332:	00006497          	auipc	s1,0x6
    80003336:	cfe48493          	addi	s1,s1,-770 # 80009030 <ticks>
        if (myproc()->killed) {
    8000333a:	fffff097          	auipc	ra,0xfffff
    8000333e:	804080e7          	jalr	-2044(ra) # 80001b3e <myproc>
    80003342:	551c                	lw	a5,40(a0)
    80003344:	ef9d                	bnez	a5,80003382 <sys_sleep+0x98>
        sleep(&ticks, &tickslock);
    80003346:	85ce                	mv	a1,s3
    80003348:	8526                	mv	a0,s1
    8000334a:	fffff097          	auipc	ra,0xfffff
    8000334e:	f34080e7          	jalr	-204(ra) # 8000227e <sleep>
    while (ticks - ticks0 < n) {
    80003352:	409c                	lw	a5,0(s1)
    80003354:	412787bb          	subw	a5,a5,s2
    80003358:	fcc42703          	lw	a4,-52(s0)
    8000335c:	fce7efe3          	bltu	a5,a4,8000333a <sys_sleep+0x50>
    }
    release(&tickslock);
    80003360:	00016517          	auipc	a0,0x16
    80003364:	f8850513          	addi	a0,a0,-120 # 800192e8 <tickslock>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	930080e7          	jalr	-1744(ra) # 80000c98 <release>
    return 0;
    80003370:	4781                	li	a5,0
}
    80003372:	853e                	mv	a0,a5
    80003374:	70e2                	ld	ra,56(sp)
    80003376:	7442                	ld	s0,48(sp)
    80003378:	74a2                	ld	s1,40(sp)
    8000337a:	7902                	ld	s2,32(sp)
    8000337c:	69e2                	ld	s3,24(sp)
    8000337e:	6121                	addi	sp,sp,64
    80003380:	8082                	ret
            release(&tickslock);
    80003382:	00016517          	auipc	a0,0x16
    80003386:	f6650513          	addi	a0,a0,-154 # 800192e8 <tickslock>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	90e080e7          	jalr	-1778(ra) # 80000c98 <release>
            return -1;
    80003392:	57fd                	li	a5,-1
    80003394:	bff9                	j	80003372 <sys_sleep+0x88>

0000000080003396 <sys_kill>:

uint64
sys_kill(void) {
    80003396:	1101                	addi	sp,sp,-32
    80003398:	ec06                	sd	ra,24(sp)
    8000339a:	e822                	sd	s0,16(sp)
    8000339c:	1000                	addi	s0,sp,32
    int pid;

    if (argint(0, &pid) < 0)
    8000339e:	fec40593          	addi	a1,s0,-20
    800033a2:	4501                	li	a0,0
    800033a4:	00000097          	auipc	ra,0x0
    800033a8:	c5a080e7          	jalr	-934(ra) # 80002ffe <argint>
    800033ac:	87aa                	mv	a5,a0
        return -1;
    800033ae:	557d                	li	a0,-1
    if (argint(0, &pid) < 0)
    800033b0:	0007c863          	bltz	a5,800033c0 <sys_kill+0x2a>
    return kill(pid);
    800033b4:	fec42503          	lw	a0,-20(s0)
    800033b8:	fffff097          	auipc	ra,0xfffff
    800033bc:	204080e7          	jalr	516(ra) # 800025bc <kill>
}
    800033c0:	60e2                	ld	ra,24(sp)
    800033c2:	6442                	ld	s0,16(sp)
    800033c4:	6105                	addi	sp,sp,32
    800033c6:	8082                	ret

00000000800033c8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void) {
    800033c8:	1101                	addi	sp,sp,-32
    800033ca:	ec06                	sd	ra,24(sp)
    800033cc:	e822                	sd	s0,16(sp)
    800033ce:	e426                	sd	s1,8(sp)
    800033d0:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800033d2:	00016517          	auipc	a0,0x16
    800033d6:	f1650513          	addi	a0,a0,-234 # 800192e8 <tickslock>
    800033da:	ffffe097          	auipc	ra,0xffffe
    800033de:	80a080e7          	jalr	-2038(ra) # 80000be4 <acquire>
    xticks = ticks;
    800033e2:	00006497          	auipc	s1,0x6
    800033e6:	c4e4a483          	lw	s1,-946(s1) # 80009030 <ticks>
    release(&tickslock);
    800033ea:	00016517          	auipc	a0,0x16
    800033ee:	efe50513          	addi	a0,a0,-258 # 800192e8 <tickslock>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	8a6080e7          	jalr	-1882(ra) # 80000c98 <release>
    return xticks;
}
    800033fa:	02049513          	slli	a0,s1,0x20
    800033fe:	9101                	srli	a0,a0,0x20
    80003400:	60e2                	ld	ra,24(sp)
    80003402:	6442                	ld	s0,16(sp)
    80003404:	64a2                	ld	s1,8(sp)
    80003406:	6105                	addi	sp,sp,32
    80003408:	8082                	ret

000000008000340a <sys_trace>:

uint64 sys_trace(void) {
    8000340a:	1101                	addi	sp,sp,-32
    8000340c:	ec06                	sd	ra,24(sp)
    8000340e:	e822                	sd	s0,16(sp)
    80003410:	1000                	addi	s0,sp,32
    //handler
    int mask = 0;
    80003412:	fe042623          	sw	zero,-20(s0)
    if (argint(0, &mask) < 0)
    80003416:	fec40593          	addi	a1,s0,-20
    8000341a:	4501                	li	a0,0
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	be2080e7          	jalr	-1054(ra) # 80002ffe <argint>
        return -1;
    80003424:	57fd                	li	a5,-1
    if (argint(0, &mask) < 0)
    80003426:	00054b63          	bltz	a0,8000343c <sys_trace+0x32>
    myproc()->mask = mask;
    8000342a:	ffffe097          	auipc	ra,0xffffe
    8000342e:	714080e7          	jalr	1812(ra) # 80001b3e <myproc>
    80003432:	fec42783          	lw	a5,-20(s0)
    80003436:	16f52623          	sw	a5,364(a0)
    return 0;
    8000343a:	4781                	li	a5,0
}
    8000343c:	853e                	mv	a0,a5
    8000343e:	60e2                	ld	ra,24(sp)
    80003440:	6442                	ld	s0,16(sp)
    80003442:	6105                	addi	sp,sp,32
    80003444:	8082                	ret

0000000080003446 <sys_waitx>:

uint64
sys_waitx(void) {
    80003446:	7139                	addi	sp,sp,-64
    80003448:	fc06                	sd	ra,56(sp)
    8000344a:	f822                	sd	s0,48(sp)
    8000344c:	f426                	sd	s1,40(sp)
    8000344e:	f04a                	sd	s2,32(sp)
    80003450:	0080                	addi	s0,sp,64
    uint64 addr, addr1, addr2;
    uint wtime, rtime;
    if (argaddr(0, &addr) < 0)
    80003452:	fd840593          	addi	a1,s0,-40
    80003456:	4501                	li	a0,0
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	bc8080e7          	jalr	-1080(ra) # 80003020 <argaddr>
        return -1;
    80003460:	57fd                	li	a5,-1
    if (argaddr(0, &addr) < 0)
    80003462:	08054063          	bltz	a0,800034e2 <sys_waitx+0x9c>
    if (argaddr(1, &addr1) < 0) // user virtual memory
    80003466:	fd040593          	addi	a1,s0,-48
    8000346a:	4505                	li	a0,1
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	bb4080e7          	jalr	-1100(ra) # 80003020 <argaddr>
        return -1;
    80003474:	57fd                	li	a5,-1
    if (argaddr(1, &addr1) < 0) // user virtual memory
    80003476:	06054663          	bltz	a0,800034e2 <sys_waitx+0x9c>
    if (argaddr(2, &addr2) < 0)
    8000347a:	fc840593          	addi	a1,s0,-56
    8000347e:	4509                	li	a0,2
    80003480:	00000097          	auipc	ra,0x0
    80003484:	ba0080e7          	jalr	-1120(ra) # 80003020 <argaddr>
        return -1;
    80003488:	57fd                	li	a5,-1
    if (argaddr(2, &addr2) < 0)
    8000348a:	04054c63          	bltz	a0,800034e2 <sys_waitx+0x9c>
    int ret = waitx(addr, &wtime, &rtime);
    8000348e:	fc040613          	addi	a2,s0,-64
    80003492:	fc440593          	addi	a1,s0,-60
    80003496:	fd843503          	ld	a0,-40(s0)
    8000349a:	fffff097          	auipc	ra,0xfffff
    8000349e:	2ee080e7          	jalr	750(ra) # 80002788 <waitx>
    800034a2:	892a                	mv	s2,a0
    struct proc *p = myproc();
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	69a080e7          	jalr	1690(ra) # 80001b3e <myproc>
    800034ac:	84aa                	mv	s1,a0
    if (copyout(p->pagetable, addr1, (char *) &wtime, sizeof(int)) < 0)
    800034ae:	4691                	li	a3,4
    800034b0:	fc440613          	addi	a2,s0,-60
    800034b4:	fd043583          	ld	a1,-48(s0)
    800034b8:	6928                	ld	a0,80(a0)
    800034ba:	ffffe097          	auipc	ra,0xffffe
    800034be:	1b8080e7          	jalr	440(ra) # 80001672 <copyout>
        return -1;
    800034c2:	57fd                	li	a5,-1
    if (copyout(p->pagetable, addr1, (char *) &wtime, sizeof(int)) < 0)
    800034c4:	00054f63          	bltz	a0,800034e2 <sys_waitx+0x9c>
    if (copyout(p->pagetable, addr2, (char *) &rtime, sizeof(int)) < 0)
    800034c8:	4691                	li	a3,4
    800034ca:	fc040613          	addi	a2,s0,-64
    800034ce:	fc843583          	ld	a1,-56(s0)
    800034d2:	68a8                	ld	a0,80(s1)
    800034d4:	ffffe097          	auipc	ra,0xffffe
    800034d8:	19e080e7          	jalr	414(ra) # 80001672 <copyout>
    800034dc:	00054a63          	bltz	a0,800034f0 <sys_waitx+0xaa>
        return -1;
    return ret;
    800034e0:	87ca                	mv	a5,s2
}
    800034e2:	853e                	mv	a0,a5
    800034e4:	70e2                	ld	ra,56(sp)
    800034e6:	7442                	ld	s0,48(sp)
    800034e8:	74a2                	ld	s1,40(sp)
    800034ea:	7902                	ld	s2,32(sp)
    800034ec:	6121                	addi	sp,sp,64
    800034ee:	8082                	ret
        return -1;
    800034f0:	57fd                	li	a5,-1
    800034f2:	bfc5                	j	800034e2 <sys_waitx+0x9c>

00000000800034f4 <sys_set_priority>:

uint64
sys_set_priority(void) {
    800034f4:	1101                	addi	sp,sp,-32
    800034f6:	ec06                	sd	ra,24(sp)
    800034f8:	e822                	sd	s0,16(sp)
    800034fa:	1000                	addi	s0,sp,32
    int new;
    int pid;

    int flag1 = argint(0, &new);
    800034fc:	fec40593          	addi	a1,s0,-20
    80003500:	4501                	li	a0,0
    80003502:	00000097          	auipc	ra,0x0
    80003506:	afc080e7          	jalr	-1284(ra) # 80002ffe <argint>

    if (flag1 < 0)
        return -1;
    8000350a:	57fd                	li	a5,-1
    if (flag1 < 0)
    8000350c:	02054563          	bltz	a0,80003536 <sys_set_priority+0x42>

    int flag2 = argint(1, &pid);
    80003510:	fe840593          	addi	a1,s0,-24
    80003514:	4505                	li	a0,1
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	ae8080e7          	jalr	-1304(ra) # 80002ffe <argint>

    if (flag2 < 0)
        return -1;
    8000351e:	57fd                	li	a5,-1
    if (flag2 < 0)
    80003520:	00054b63          	bltz	a0,80003536 <sys_set_priority+0x42>

    return set_priority(new, pid);
    80003524:	fe842583          	lw	a1,-24(s0)
    80003528:	fec42503          	lw	a0,-20(s0)
    8000352c:	fffff097          	auipc	ra,0xfffff
    80003530:	526080e7          	jalr	1318(ra) # 80002a52 <set_priority>
    80003534:	87aa                	mv	a5,a0
    80003536:	853e                	mv	a0,a5
    80003538:	60e2                	ld	ra,24(sp)
    8000353a:	6442                	ld	s0,16(sp)
    8000353c:	6105                	addi	sp,sp,32
    8000353e:	8082                	ret

0000000080003540 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	e052                	sd	s4,0(sp)
    8000354e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003550:	00005597          	auipc	a1,0x5
    80003554:	1b058593          	addi	a1,a1,432 # 80008700 <syscalls+0xc8>
    80003558:	00016517          	auipc	a0,0x16
    8000355c:	da850513          	addi	a0,a0,-600 # 80019300 <bcache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	5f4080e7          	jalr	1524(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003568:	0001e797          	auipc	a5,0x1e
    8000356c:	d9878793          	addi	a5,a5,-616 # 80021300 <bcache+0x8000>
    80003570:	0001e717          	auipc	a4,0x1e
    80003574:	ff870713          	addi	a4,a4,-8 # 80021568 <bcache+0x8268>
    80003578:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000357c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003580:	00016497          	auipc	s1,0x16
    80003584:	d9848493          	addi	s1,s1,-616 # 80019318 <bcache+0x18>
    b->next = bcache.head.next;
    80003588:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000358a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000358c:	00005a17          	auipc	s4,0x5
    80003590:	17ca0a13          	addi	s4,s4,380 # 80008708 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003594:	2b893783          	ld	a5,696(s2)
    80003598:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000359a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000359e:	85d2                	mv	a1,s4
    800035a0:	01048513          	addi	a0,s1,16
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	4bc080e7          	jalr	1212(ra) # 80004a60 <initsleeplock>
    bcache.head.next->prev = b;
    800035ac:	2b893783          	ld	a5,696(s2)
    800035b0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035b2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035b6:	45848493          	addi	s1,s1,1112
    800035ba:	fd349de3          	bne	s1,s3,80003594 <binit+0x54>
  }
}
    800035be:	70a2                	ld	ra,40(sp)
    800035c0:	7402                	ld	s0,32(sp)
    800035c2:	64e2                	ld	s1,24(sp)
    800035c4:	6942                	ld	s2,16(sp)
    800035c6:	69a2                	ld	s3,8(sp)
    800035c8:	6a02                	ld	s4,0(sp)
    800035ca:	6145                	addi	sp,sp,48
    800035cc:	8082                	ret

00000000800035ce <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035ce:	7179                	addi	sp,sp,-48
    800035d0:	f406                	sd	ra,40(sp)
    800035d2:	f022                	sd	s0,32(sp)
    800035d4:	ec26                	sd	s1,24(sp)
    800035d6:	e84a                	sd	s2,16(sp)
    800035d8:	e44e                	sd	s3,8(sp)
    800035da:	1800                	addi	s0,sp,48
    800035dc:	89aa                	mv	s3,a0
    800035de:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800035e0:	00016517          	auipc	a0,0x16
    800035e4:	d2050513          	addi	a0,a0,-736 # 80019300 <bcache>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	5fc080e7          	jalr	1532(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035f0:	0001e497          	auipc	s1,0x1e
    800035f4:	fc84b483          	ld	s1,-56(s1) # 800215b8 <bcache+0x82b8>
    800035f8:	0001e797          	auipc	a5,0x1e
    800035fc:	f7078793          	addi	a5,a5,-144 # 80021568 <bcache+0x8268>
    80003600:	02f48f63          	beq	s1,a5,8000363e <bread+0x70>
    80003604:	873e                	mv	a4,a5
    80003606:	a021                	j	8000360e <bread+0x40>
    80003608:	68a4                	ld	s1,80(s1)
    8000360a:	02e48a63          	beq	s1,a4,8000363e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000360e:	449c                	lw	a5,8(s1)
    80003610:	ff379ce3          	bne	a5,s3,80003608 <bread+0x3a>
    80003614:	44dc                	lw	a5,12(s1)
    80003616:	ff2799e3          	bne	a5,s2,80003608 <bread+0x3a>
      b->refcnt++;
    8000361a:	40bc                	lw	a5,64(s1)
    8000361c:	2785                	addiw	a5,a5,1
    8000361e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003620:	00016517          	auipc	a0,0x16
    80003624:	ce050513          	addi	a0,a0,-800 # 80019300 <bcache>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	670080e7          	jalr	1648(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003630:	01048513          	addi	a0,s1,16
    80003634:	00001097          	auipc	ra,0x1
    80003638:	466080e7          	jalr	1126(ra) # 80004a9a <acquiresleep>
      return b;
    8000363c:	a8b9                	j	8000369a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000363e:	0001e497          	auipc	s1,0x1e
    80003642:	f724b483          	ld	s1,-142(s1) # 800215b0 <bcache+0x82b0>
    80003646:	0001e797          	auipc	a5,0x1e
    8000364a:	f2278793          	addi	a5,a5,-222 # 80021568 <bcache+0x8268>
    8000364e:	00f48863          	beq	s1,a5,8000365e <bread+0x90>
    80003652:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003654:	40bc                	lw	a5,64(s1)
    80003656:	cf81                	beqz	a5,8000366e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003658:	64a4                	ld	s1,72(s1)
    8000365a:	fee49de3          	bne	s1,a4,80003654 <bread+0x86>
  panic("bget: no buffers");
    8000365e:	00005517          	auipc	a0,0x5
    80003662:	0b250513          	addi	a0,a0,178 # 80008710 <syscalls+0xd8>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	ed8080e7          	jalr	-296(ra) # 8000053e <panic>
      b->dev = dev;
    8000366e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003672:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003676:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000367a:	4785                	li	a5,1
    8000367c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000367e:	00016517          	auipc	a0,0x16
    80003682:	c8250513          	addi	a0,a0,-894 # 80019300 <bcache>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	612080e7          	jalr	1554(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000368e:	01048513          	addi	a0,s1,16
    80003692:	00001097          	auipc	ra,0x1
    80003696:	408080e7          	jalr	1032(ra) # 80004a9a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000369a:	409c                	lw	a5,0(s1)
    8000369c:	cb89                	beqz	a5,800036ae <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000369e:	8526                	mv	a0,s1
    800036a0:	70a2                	ld	ra,40(sp)
    800036a2:	7402                	ld	s0,32(sp)
    800036a4:	64e2                	ld	s1,24(sp)
    800036a6:	6942                	ld	s2,16(sp)
    800036a8:	69a2                	ld	s3,8(sp)
    800036aa:	6145                	addi	sp,sp,48
    800036ac:	8082                	ret
    virtio_disk_rw(b, 0);
    800036ae:	4581                	li	a1,0
    800036b0:	8526                	mv	a0,s1
    800036b2:	00003097          	auipc	ra,0x3
    800036b6:	f14080e7          	jalr	-236(ra) # 800065c6 <virtio_disk_rw>
    b->valid = 1;
    800036ba:	4785                	li	a5,1
    800036bc:	c09c                	sw	a5,0(s1)
  return b;
    800036be:	b7c5                	j	8000369e <bread+0xd0>

00000000800036c0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036c0:	1101                	addi	sp,sp,-32
    800036c2:	ec06                	sd	ra,24(sp)
    800036c4:	e822                	sd	s0,16(sp)
    800036c6:	e426                	sd	s1,8(sp)
    800036c8:	1000                	addi	s0,sp,32
    800036ca:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036cc:	0541                	addi	a0,a0,16
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	466080e7          	jalr	1126(ra) # 80004b34 <holdingsleep>
    800036d6:	cd01                	beqz	a0,800036ee <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036d8:	4585                	li	a1,1
    800036da:	8526                	mv	a0,s1
    800036dc:	00003097          	auipc	ra,0x3
    800036e0:	eea080e7          	jalr	-278(ra) # 800065c6 <virtio_disk_rw>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret
    panic("bwrite");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	03a50513          	addi	a0,a0,58 # 80008728 <syscalls+0xf0>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e48080e7          	jalr	-440(ra) # 8000053e <panic>

00000000800036fe <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036fe:	1101                	addi	sp,sp,-32
    80003700:	ec06                	sd	ra,24(sp)
    80003702:	e822                	sd	s0,16(sp)
    80003704:	e426                	sd	s1,8(sp)
    80003706:	e04a                	sd	s2,0(sp)
    80003708:	1000                	addi	s0,sp,32
    8000370a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000370c:	01050913          	addi	s2,a0,16
    80003710:	854a                	mv	a0,s2
    80003712:	00001097          	auipc	ra,0x1
    80003716:	422080e7          	jalr	1058(ra) # 80004b34 <holdingsleep>
    8000371a:	c92d                	beqz	a0,8000378c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000371c:	854a                	mv	a0,s2
    8000371e:	00001097          	auipc	ra,0x1
    80003722:	3d2080e7          	jalr	978(ra) # 80004af0 <releasesleep>

  acquire(&bcache.lock);
    80003726:	00016517          	auipc	a0,0x16
    8000372a:	bda50513          	addi	a0,a0,-1062 # 80019300 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	4b6080e7          	jalr	1206(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003736:	40bc                	lw	a5,64(s1)
    80003738:	37fd                	addiw	a5,a5,-1
    8000373a:	0007871b          	sext.w	a4,a5
    8000373e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003740:	eb05                	bnez	a4,80003770 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003742:	68bc                	ld	a5,80(s1)
    80003744:	64b8                	ld	a4,72(s1)
    80003746:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003748:	64bc                	ld	a5,72(s1)
    8000374a:	68b8                	ld	a4,80(s1)
    8000374c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000374e:	0001e797          	auipc	a5,0x1e
    80003752:	bb278793          	addi	a5,a5,-1102 # 80021300 <bcache+0x8000>
    80003756:	2b87b703          	ld	a4,696(a5)
    8000375a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000375c:	0001e717          	auipc	a4,0x1e
    80003760:	e0c70713          	addi	a4,a4,-500 # 80021568 <bcache+0x8268>
    80003764:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003766:	2b87b703          	ld	a4,696(a5)
    8000376a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000376c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003770:	00016517          	auipc	a0,0x16
    80003774:	b9050513          	addi	a0,a0,-1136 # 80019300 <bcache>
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	520080e7          	jalr	1312(ra) # 80000c98 <release>
}
    80003780:	60e2                	ld	ra,24(sp)
    80003782:	6442                	ld	s0,16(sp)
    80003784:	64a2                	ld	s1,8(sp)
    80003786:	6902                	ld	s2,0(sp)
    80003788:	6105                	addi	sp,sp,32
    8000378a:	8082                	ret
    panic("brelse");
    8000378c:	00005517          	auipc	a0,0x5
    80003790:	fa450513          	addi	a0,a0,-92 # 80008730 <syscalls+0xf8>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	daa080e7          	jalr	-598(ra) # 8000053e <panic>

000000008000379c <bpin>:

void
bpin(struct buf *b) {
    8000379c:	1101                	addi	sp,sp,-32
    8000379e:	ec06                	sd	ra,24(sp)
    800037a0:	e822                	sd	s0,16(sp)
    800037a2:	e426                	sd	s1,8(sp)
    800037a4:	1000                	addi	s0,sp,32
    800037a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037a8:	00016517          	auipc	a0,0x16
    800037ac:	b5850513          	addi	a0,a0,-1192 # 80019300 <bcache>
    800037b0:	ffffd097          	auipc	ra,0xffffd
    800037b4:	434080e7          	jalr	1076(ra) # 80000be4 <acquire>
  b->refcnt++;
    800037b8:	40bc                	lw	a5,64(s1)
    800037ba:	2785                	addiw	a5,a5,1
    800037bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037be:	00016517          	auipc	a0,0x16
    800037c2:	b4250513          	addi	a0,a0,-1214 # 80019300 <bcache>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	4d2080e7          	jalr	1234(ra) # 80000c98 <release>
}
    800037ce:	60e2                	ld	ra,24(sp)
    800037d0:	6442                	ld	s0,16(sp)
    800037d2:	64a2                	ld	s1,8(sp)
    800037d4:	6105                	addi	sp,sp,32
    800037d6:	8082                	ret

00000000800037d8 <bunpin>:

void
bunpin(struct buf *b) {
    800037d8:	1101                	addi	sp,sp,-32
    800037da:	ec06                	sd	ra,24(sp)
    800037dc:	e822                	sd	s0,16(sp)
    800037de:	e426                	sd	s1,8(sp)
    800037e0:	1000                	addi	s0,sp,32
    800037e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037e4:	00016517          	auipc	a0,0x16
    800037e8:	b1c50513          	addi	a0,a0,-1252 # 80019300 <bcache>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	3f8080e7          	jalr	1016(ra) # 80000be4 <acquire>
  b->refcnt--;
    800037f4:	40bc                	lw	a5,64(s1)
    800037f6:	37fd                	addiw	a5,a5,-1
    800037f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037fa:	00016517          	auipc	a0,0x16
    800037fe:	b0650513          	addi	a0,a0,-1274 # 80019300 <bcache>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	496080e7          	jalr	1174(ra) # 80000c98 <release>
}
    8000380a:	60e2                	ld	ra,24(sp)
    8000380c:	6442                	ld	s0,16(sp)
    8000380e:	64a2                	ld	s1,8(sp)
    80003810:	6105                	addi	sp,sp,32
    80003812:	8082                	ret

0000000080003814 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003814:	1101                	addi	sp,sp,-32
    80003816:	ec06                	sd	ra,24(sp)
    80003818:	e822                	sd	s0,16(sp)
    8000381a:	e426                	sd	s1,8(sp)
    8000381c:	e04a                	sd	s2,0(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003822:	00d5d59b          	srliw	a1,a1,0xd
    80003826:	0001e797          	auipc	a5,0x1e
    8000382a:	1b67a783          	lw	a5,438(a5) # 800219dc <sb+0x1c>
    8000382e:	9dbd                	addw	a1,a1,a5
    80003830:	00000097          	auipc	ra,0x0
    80003834:	d9e080e7          	jalr	-610(ra) # 800035ce <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003838:	0074f713          	andi	a4,s1,7
    8000383c:	4785                	li	a5,1
    8000383e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003842:	14ce                	slli	s1,s1,0x33
    80003844:	90d9                	srli	s1,s1,0x36
    80003846:	00950733          	add	a4,a0,s1
    8000384a:	05874703          	lbu	a4,88(a4)
    8000384e:	00e7f6b3          	and	a3,a5,a4
    80003852:	c69d                	beqz	a3,80003880 <bfree+0x6c>
    80003854:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003856:	94aa                	add	s1,s1,a0
    80003858:	fff7c793          	not	a5,a5
    8000385c:	8ff9                	and	a5,a5,a4
    8000385e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003862:	00001097          	auipc	ra,0x1
    80003866:	118080e7          	jalr	280(ra) # 8000497a <log_write>
  brelse(bp);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	e92080e7          	jalr	-366(ra) # 800036fe <brelse>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6902                	ld	s2,0(sp)
    8000387c:	6105                	addi	sp,sp,32
    8000387e:	8082                	ret
    panic("freeing free block");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	eb850513          	addi	a0,a0,-328 # 80008738 <syscalls+0x100>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cb6080e7          	jalr	-842(ra) # 8000053e <panic>

0000000080003890 <balloc>:
{
    80003890:	711d                	addi	sp,sp,-96
    80003892:	ec86                	sd	ra,88(sp)
    80003894:	e8a2                	sd	s0,80(sp)
    80003896:	e4a6                	sd	s1,72(sp)
    80003898:	e0ca                	sd	s2,64(sp)
    8000389a:	fc4e                	sd	s3,56(sp)
    8000389c:	f852                	sd	s4,48(sp)
    8000389e:	f456                	sd	s5,40(sp)
    800038a0:	f05a                	sd	s6,32(sp)
    800038a2:	ec5e                	sd	s7,24(sp)
    800038a4:	e862                	sd	s8,16(sp)
    800038a6:	e466                	sd	s9,8(sp)
    800038a8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038aa:	0001e797          	auipc	a5,0x1e
    800038ae:	11a7a783          	lw	a5,282(a5) # 800219c4 <sb+0x4>
    800038b2:	cbd1                	beqz	a5,80003946 <balloc+0xb6>
    800038b4:	8baa                	mv	s7,a0
    800038b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038b8:	0001eb17          	auipc	s6,0x1e
    800038bc:	108b0b13          	addi	s6,s6,264 # 800219c0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038c6:	6c89                	lui	s9,0x2
    800038c8:	a831                	j	800038e4 <balloc+0x54>
    brelse(bp);
    800038ca:	854a                	mv	a0,s2
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	e32080e7          	jalr	-462(ra) # 800036fe <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800038d4:	015c87bb          	addw	a5,s9,s5
    800038d8:	00078a9b          	sext.w	s5,a5
    800038dc:	004b2703          	lw	a4,4(s6)
    800038e0:	06eaf363          	bgeu	s5,a4,80003946 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800038e4:	41fad79b          	sraiw	a5,s5,0x1f
    800038e8:	0137d79b          	srliw	a5,a5,0x13
    800038ec:	015787bb          	addw	a5,a5,s5
    800038f0:	40d7d79b          	sraiw	a5,a5,0xd
    800038f4:	01cb2583          	lw	a1,28(s6)
    800038f8:	9dbd                	addw	a1,a1,a5
    800038fa:	855e                	mv	a0,s7
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	cd2080e7          	jalr	-814(ra) # 800035ce <bread>
    80003904:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003906:	004b2503          	lw	a0,4(s6)
    8000390a:	000a849b          	sext.w	s1,s5
    8000390e:	8662                	mv	a2,s8
    80003910:	faa4fde3          	bgeu	s1,a0,800038ca <balloc+0x3a>
      m = 1 << (bi % 8);
    80003914:	41f6579b          	sraiw	a5,a2,0x1f
    80003918:	01d7d69b          	srliw	a3,a5,0x1d
    8000391c:	00c6873b          	addw	a4,a3,a2
    80003920:	00777793          	andi	a5,a4,7
    80003924:	9f95                	subw	a5,a5,a3
    80003926:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000392a:	4037571b          	sraiw	a4,a4,0x3
    8000392e:	00e906b3          	add	a3,s2,a4
    80003932:	0586c683          	lbu	a3,88(a3)
    80003936:	00d7f5b3          	and	a1,a5,a3
    8000393a:	cd91                	beqz	a1,80003956 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000393c:	2605                	addiw	a2,a2,1
    8000393e:	2485                	addiw	s1,s1,1
    80003940:	fd4618e3          	bne	a2,s4,80003910 <balloc+0x80>
    80003944:	b759                	j	800038ca <balloc+0x3a>
  panic("balloc: out of blocks");
    80003946:	00005517          	auipc	a0,0x5
    8000394a:	e0a50513          	addi	a0,a0,-502 # 80008750 <syscalls+0x118>
    8000394e:	ffffd097          	auipc	ra,0xffffd
    80003952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003956:	974a                	add	a4,a4,s2
    80003958:	8fd5                	or	a5,a5,a3
    8000395a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000395e:	854a                	mv	a0,s2
    80003960:	00001097          	auipc	ra,0x1
    80003964:	01a080e7          	jalr	26(ra) # 8000497a <log_write>
        brelse(bp);
    80003968:	854a                	mv	a0,s2
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	d94080e7          	jalr	-620(ra) # 800036fe <brelse>
  bp = bread(dev, bno);
    80003972:	85a6                	mv	a1,s1
    80003974:	855e                	mv	a0,s7
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	c58080e7          	jalr	-936(ra) # 800035ce <bread>
    8000397e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003980:	40000613          	li	a2,1024
    80003984:	4581                	li	a1,0
    80003986:	05850513          	addi	a0,a0,88
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	356080e7          	jalr	854(ra) # 80000ce0 <memset>
  log_write(bp);
    80003992:	854a                	mv	a0,s2
    80003994:	00001097          	auipc	ra,0x1
    80003998:	fe6080e7          	jalr	-26(ra) # 8000497a <log_write>
  brelse(bp);
    8000399c:	854a                	mv	a0,s2
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	d60080e7          	jalr	-672(ra) # 800036fe <brelse>
}
    800039a6:	8526                	mv	a0,s1
    800039a8:	60e6                	ld	ra,88(sp)
    800039aa:	6446                	ld	s0,80(sp)
    800039ac:	64a6                	ld	s1,72(sp)
    800039ae:	6906                	ld	s2,64(sp)
    800039b0:	79e2                	ld	s3,56(sp)
    800039b2:	7a42                	ld	s4,48(sp)
    800039b4:	7aa2                	ld	s5,40(sp)
    800039b6:	7b02                	ld	s6,32(sp)
    800039b8:	6be2                	ld	s7,24(sp)
    800039ba:	6c42                	ld	s8,16(sp)
    800039bc:	6ca2                	ld	s9,8(sp)
    800039be:	6125                	addi	sp,sp,96
    800039c0:	8082                	ret

00000000800039c2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800039c2:	7179                	addi	sp,sp,-48
    800039c4:	f406                	sd	ra,40(sp)
    800039c6:	f022                	sd	s0,32(sp)
    800039c8:	ec26                	sd	s1,24(sp)
    800039ca:	e84a                	sd	s2,16(sp)
    800039cc:	e44e                	sd	s3,8(sp)
    800039ce:	e052                	sd	s4,0(sp)
    800039d0:	1800                	addi	s0,sp,48
    800039d2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039d4:	47ad                	li	a5,11
    800039d6:	04b7fe63          	bgeu	a5,a1,80003a32 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800039da:	ff45849b          	addiw	s1,a1,-12
    800039de:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039e2:	0ff00793          	li	a5,255
    800039e6:	0ae7e363          	bltu	a5,a4,80003a8c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800039ea:	08052583          	lw	a1,128(a0)
    800039ee:	c5ad                	beqz	a1,80003a58 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800039f0:	00092503          	lw	a0,0(s2)
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	bda080e7          	jalr	-1062(ra) # 800035ce <bread>
    800039fc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800039fe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a02:	02049593          	slli	a1,s1,0x20
    80003a06:	9181                	srli	a1,a1,0x20
    80003a08:	058a                	slli	a1,a1,0x2
    80003a0a:	00b784b3          	add	s1,a5,a1
    80003a0e:	0004a983          	lw	s3,0(s1)
    80003a12:	04098d63          	beqz	s3,80003a6c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a16:	8552                	mv	a0,s4
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	ce6080e7          	jalr	-794(ra) # 800036fe <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a20:	854e                	mv	a0,s3
    80003a22:	70a2                	ld	ra,40(sp)
    80003a24:	7402                	ld	s0,32(sp)
    80003a26:	64e2                	ld	s1,24(sp)
    80003a28:	6942                	ld	s2,16(sp)
    80003a2a:	69a2                	ld	s3,8(sp)
    80003a2c:	6a02                	ld	s4,0(sp)
    80003a2e:	6145                	addi	sp,sp,48
    80003a30:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003a32:	02059493          	slli	s1,a1,0x20
    80003a36:	9081                	srli	s1,s1,0x20
    80003a38:	048a                	slli	s1,s1,0x2
    80003a3a:	94aa                	add	s1,s1,a0
    80003a3c:	0504a983          	lw	s3,80(s1)
    80003a40:	fe0990e3          	bnez	s3,80003a20 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003a44:	4108                	lw	a0,0(a0)
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	e4a080e7          	jalr	-438(ra) # 80003890 <balloc>
    80003a4e:	0005099b          	sext.w	s3,a0
    80003a52:	0534a823          	sw	s3,80(s1)
    80003a56:	b7e9                	j	80003a20 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003a58:	4108                	lw	a0,0(a0)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	e36080e7          	jalr	-458(ra) # 80003890 <balloc>
    80003a62:	0005059b          	sext.w	a1,a0
    80003a66:	08b92023          	sw	a1,128(s2)
    80003a6a:	b759                	j	800039f0 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003a6c:	00092503          	lw	a0,0(s2)
    80003a70:	00000097          	auipc	ra,0x0
    80003a74:	e20080e7          	jalr	-480(ra) # 80003890 <balloc>
    80003a78:	0005099b          	sext.w	s3,a0
    80003a7c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003a80:	8552                	mv	a0,s4
    80003a82:	00001097          	auipc	ra,0x1
    80003a86:	ef8080e7          	jalr	-264(ra) # 8000497a <log_write>
    80003a8a:	b771                	j	80003a16 <bmap+0x54>
  panic("bmap: out of range");
    80003a8c:	00005517          	auipc	a0,0x5
    80003a90:	cdc50513          	addi	a0,a0,-804 # 80008768 <syscalls+0x130>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	aaa080e7          	jalr	-1366(ra) # 8000053e <panic>

0000000080003a9c <iget>:
{
    80003a9c:	7179                	addi	sp,sp,-48
    80003a9e:	f406                	sd	ra,40(sp)
    80003aa0:	f022                	sd	s0,32(sp)
    80003aa2:	ec26                	sd	s1,24(sp)
    80003aa4:	e84a                	sd	s2,16(sp)
    80003aa6:	e44e                	sd	s3,8(sp)
    80003aa8:	e052                	sd	s4,0(sp)
    80003aaa:	1800                	addi	s0,sp,48
    80003aac:	89aa                	mv	s3,a0
    80003aae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003ab0:	0001e517          	auipc	a0,0x1e
    80003ab4:	f3050513          	addi	a0,a0,-208 # 800219e0 <itable>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	12c080e7          	jalr	300(ra) # 80000be4 <acquire>
  empty = 0;
    80003ac0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ac2:	0001e497          	auipc	s1,0x1e
    80003ac6:	f3648493          	addi	s1,s1,-202 # 800219f8 <itable+0x18>
    80003aca:	00020697          	auipc	a3,0x20
    80003ace:	9be68693          	addi	a3,a3,-1602 # 80023488 <log>
    80003ad2:	a039                	j	80003ae0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ad4:	02090b63          	beqz	s2,80003b0a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ad8:	08848493          	addi	s1,s1,136
    80003adc:	02d48a63          	beq	s1,a3,80003b10 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ae0:	449c                	lw	a5,8(s1)
    80003ae2:	fef059e3          	blez	a5,80003ad4 <iget+0x38>
    80003ae6:	4098                	lw	a4,0(s1)
    80003ae8:	ff3716e3          	bne	a4,s3,80003ad4 <iget+0x38>
    80003aec:	40d8                	lw	a4,4(s1)
    80003aee:	ff4713e3          	bne	a4,s4,80003ad4 <iget+0x38>
      ip->ref++;
    80003af2:	2785                	addiw	a5,a5,1
    80003af4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003af6:	0001e517          	auipc	a0,0x1e
    80003afa:	eea50513          	addi	a0,a0,-278 # 800219e0 <itable>
    80003afe:	ffffd097          	auipc	ra,0xffffd
    80003b02:	19a080e7          	jalr	410(ra) # 80000c98 <release>
      return ip;
    80003b06:	8926                	mv	s2,s1
    80003b08:	a03d                	j	80003b36 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b0a:	f7f9                	bnez	a5,80003ad8 <iget+0x3c>
    80003b0c:	8926                	mv	s2,s1
    80003b0e:	b7e9                	j	80003ad8 <iget+0x3c>
  if(empty == 0)
    80003b10:	02090c63          	beqz	s2,80003b48 <iget+0xac>
  ip->dev = dev;
    80003b14:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b18:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b1c:	4785                	li	a5,1
    80003b1e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b22:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b26:	0001e517          	auipc	a0,0x1e
    80003b2a:	eba50513          	addi	a0,a0,-326 # 800219e0 <itable>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	16a080e7          	jalr	362(ra) # 80000c98 <release>
}
    80003b36:	854a                	mv	a0,s2
    80003b38:	70a2                	ld	ra,40(sp)
    80003b3a:	7402                	ld	s0,32(sp)
    80003b3c:	64e2                	ld	s1,24(sp)
    80003b3e:	6942                	ld	s2,16(sp)
    80003b40:	69a2                	ld	s3,8(sp)
    80003b42:	6a02                	ld	s4,0(sp)
    80003b44:	6145                	addi	sp,sp,48
    80003b46:	8082                	ret
    panic("iget: no inodes");
    80003b48:	00005517          	auipc	a0,0x5
    80003b4c:	c3850513          	addi	a0,a0,-968 # 80008780 <syscalls+0x148>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	9ee080e7          	jalr	-1554(ra) # 8000053e <panic>

0000000080003b58 <fsinit>:
fsinit(int dev) {
    80003b58:	7179                	addi	sp,sp,-48
    80003b5a:	f406                	sd	ra,40(sp)
    80003b5c:	f022                	sd	s0,32(sp)
    80003b5e:	ec26                	sd	s1,24(sp)
    80003b60:	e84a                	sd	s2,16(sp)
    80003b62:	e44e                	sd	s3,8(sp)
    80003b64:	1800                	addi	s0,sp,48
    80003b66:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b68:	4585                	li	a1,1
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	a64080e7          	jalr	-1436(ra) # 800035ce <bread>
    80003b72:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b74:	0001e997          	auipc	s3,0x1e
    80003b78:	e4c98993          	addi	s3,s3,-436 # 800219c0 <sb>
    80003b7c:	02000613          	li	a2,32
    80003b80:	05850593          	addi	a1,a0,88
    80003b84:	854e                	mv	a0,s3
    80003b86:	ffffd097          	auipc	ra,0xffffd
    80003b8a:	1ba080e7          	jalr	442(ra) # 80000d40 <memmove>
  brelse(bp);
    80003b8e:	8526                	mv	a0,s1
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	b6e080e7          	jalr	-1170(ra) # 800036fe <brelse>
  if(sb.magic != FSMAGIC)
    80003b98:	0009a703          	lw	a4,0(s3)
    80003b9c:	102037b7          	lui	a5,0x10203
    80003ba0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ba4:	02f71263          	bne	a4,a5,80003bc8 <fsinit+0x70>
  initlog(dev, &sb);
    80003ba8:	0001e597          	auipc	a1,0x1e
    80003bac:	e1858593          	addi	a1,a1,-488 # 800219c0 <sb>
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	b4c080e7          	jalr	-1204(ra) # 800046fe <initlog>
}
    80003bba:	70a2                	ld	ra,40(sp)
    80003bbc:	7402                	ld	s0,32(sp)
    80003bbe:	64e2                	ld	s1,24(sp)
    80003bc0:	6942                	ld	s2,16(sp)
    80003bc2:	69a2                	ld	s3,8(sp)
    80003bc4:	6145                	addi	sp,sp,48
    80003bc6:	8082                	ret
    panic("invalid file system");
    80003bc8:	00005517          	auipc	a0,0x5
    80003bcc:	bc850513          	addi	a0,a0,-1080 # 80008790 <syscalls+0x158>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	96e080e7          	jalr	-1682(ra) # 8000053e <panic>

0000000080003bd8 <iinit>:
{
    80003bd8:	7179                	addi	sp,sp,-48
    80003bda:	f406                	sd	ra,40(sp)
    80003bdc:	f022                	sd	s0,32(sp)
    80003bde:	ec26                	sd	s1,24(sp)
    80003be0:	e84a                	sd	s2,16(sp)
    80003be2:	e44e                	sd	s3,8(sp)
    80003be4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003be6:	00005597          	auipc	a1,0x5
    80003bea:	bc258593          	addi	a1,a1,-1086 # 800087a8 <syscalls+0x170>
    80003bee:	0001e517          	auipc	a0,0x1e
    80003bf2:	df250513          	addi	a0,a0,-526 # 800219e0 <itable>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	f5e080e7          	jalr	-162(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bfe:	0001e497          	auipc	s1,0x1e
    80003c02:	e0a48493          	addi	s1,s1,-502 # 80021a08 <itable+0x28>
    80003c06:	00020997          	auipc	s3,0x20
    80003c0a:	89298993          	addi	s3,s3,-1902 # 80023498 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c0e:	00005917          	auipc	s2,0x5
    80003c12:	ba290913          	addi	s2,s2,-1118 # 800087b0 <syscalls+0x178>
    80003c16:	85ca                	mv	a1,s2
    80003c18:	8526                	mv	a0,s1
    80003c1a:	00001097          	auipc	ra,0x1
    80003c1e:	e46080e7          	jalr	-442(ra) # 80004a60 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c22:	08848493          	addi	s1,s1,136
    80003c26:	ff3498e3          	bne	s1,s3,80003c16 <iinit+0x3e>
}
    80003c2a:	70a2                	ld	ra,40(sp)
    80003c2c:	7402                	ld	s0,32(sp)
    80003c2e:	64e2                	ld	s1,24(sp)
    80003c30:	6942                	ld	s2,16(sp)
    80003c32:	69a2                	ld	s3,8(sp)
    80003c34:	6145                	addi	sp,sp,48
    80003c36:	8082                	ret

0000000080003c38 <ialloc>:
{
    80003c38:	715d                	addi	sp,sp,-80
    80003c3a:	e486                	sd	ra,72(sp)
    80003c3c:	e0a2                	sd	s0,64(sp)
    80003c3e:	fc26                	sd	s1,56(sp)
    80003c40:	f84a                	sd	s2,48(sp)
    80003c42:	f44e                	sd	s3,40(sp)
    80003c44:	f052                	sd	s4,32(sp)
    80003c46:	ec56                	sd	s5,24(sp)
    80003c48:	e85a                	sd	s6,16(sp)
    80003c4a:	e45e                	sd	s7,8(sp)
    80003c4c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c4e:	0001e717          	auipc	a4,0x1e
    80003c52:	d7e72703          	lw	a4,-642(a4) # 800219cc <sb+0xc>
    80003c56:	4785                	li	a5,1
    80003c58:	04e7fa63          	bgeu	a5,a4,80003cac <ialloc+0x74>
    80003c5c:	8aaa                	mv	s5,a0
    80003c5e:	8bae                	mv	s7,a1
    80003c60:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c62:	0001ea17          	auipc	s4,0x1e
    80003c66:	d5ea0a13          	addi	s4,s4,-674 # 800219c0 <sb>
    80003c6a:	00048b1b          	sext.w	s6,s1
    80003c6e:	0044d593          	srli	a1,s1,0x4
    80003c72:	018a2783          	lw	a5,24(s4)
    80003c76:	9dbd                	addw	a1,a1,a5
    80003c78:	8556                	mv	a0,s5
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	954080e7          	jalr	-1708(ra) # 800035ce <bread>
    80003c82:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c84:	05850993          	addi	s3,a0,88
    80003c88:	00f4f793          	andi	a5,s1,15
    80003c8c:	079a                	slli	a5,a5,0x6
    80003c8e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c90:	00099783          	lh	a5,0(s3)
    80003c94:	c785                	beqz	a5,80003cbc <ialloc+0x84>
    brelse(bp);
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	a68080e7          	jalr	-1432(ra) # 800036fe <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c9e:	0485                	addi	s1,s1,1
    80003ca0:	00ca2703          	lw	a4,12(s4)
    80003ca4:	0004879b          	sext.w	a5,s1
    80003ca8:	fce7e1e3          	bltu	a5,a4,80003c6a <ialloc+0x32>
  panic("ialloc: no inodes");
    80003cac:	00005517          	auipc	a0,0x5
    80003cb0:	b0c50513          	addi	a0,a0,-1268 # 800087b8 <syscalls+0x180>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	88a080e7          	jalr	-1910(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003cbc:	04000613          	li	a2,64
    80003cc0:	4581                	li	a1,0
    80003cc2:	854e                	mv	a0,s3
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	01c080e7          	jalr	28(ra) # 80000ce0 <memset>
      dip->type = type;
    80003ccc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cd0:	854a                	mv	a0,s2
    80003cd2:	00001097          	auipc	ra,0x1
    80003cd6:	ca8080e7          	jalr	-856(ra) # 8000497a <log_write>
      brelse(bp);
    80003cda:	854a                	mv	a0,s2
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	a22080e7          	jalr	-1502(ra) # 800036fe <brelse>
      return iget(dev, inum);
    80003ce4:	85da                	mv	a1,s6
    80003ce6:	8556                	mv	a0,s5
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	db4080e7          	jalr	-588(ra) # 80003a9c <iget>
}
    80003cf0:	60a6                	ld	ra,72(sp)
    80003cf2:	6406                	ld	s0,64(sp)
    80003cf4:	74e2                	ld	s1,56(sp)
    80003cf6:	7942                	ld	s2,48(sp)
    80003cf8:	79a2                	ld	s3,40(sp)
    80003cfa:	7a02                	ld	s4,32(sp)
    80003cfc:	6ae2                	ld	s5,24(sp)
    80003cfe:	6b42                	ld	s6,16(sp)
    80003d00:	6ba2                	ld	s7,8(sp)
    80003d02:	6161                	addi	sp,sp,80
    80003d04:	8082                	ret

0000000080003d06 <iupdate>:
{
    80003d06:	1101                	addi	sp,sp,-32
    80003d08:	ec06                	sd	ra,24(sp)
    80003d0a:	e822                	sd	s0,16(sp)
    80003d0c:	e426                	sd	s1,8(sp)
    80003d0e:	e04a                	sd	s2,0(sp)
    80003d10:	1000                	addi	s0,sp,32
    80003d12:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d14:	415c                	lw	a5,4(a0)
    80003d16:	0047d79b          	srliw	a5,a5,0x4
    80003d1a:	0001e597          	auipc	a1,0x1e
    80003d1e:	cbe5a583          	lw	a1,-834(a1) # 800219d8 <sb+0x18>
    80003d22:	9dbd                	addw	a1,a1,a5
    80003d24:	4108                	lw	a0,0(a0)
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	8a8080e7          	jalr	-1880(ra) # 800035ce <bread>
    80003d2e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d30:	05850793          	addi	a5,a0,88
    80003d34:	40c8                	lw	a0,4(s1)
    80003d36:	893d                	andi	a0,a0,15
    80003d38:	051a                	slli	a0,a0,0x6
    80003d3a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d3c:	04449703          	lh	a4,68(s1)
    80003d40:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d44:	04649703          	lh	a4,70(s1)
    80003d48:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d4c:	04849703          	lh	a4,72(s1)
    80003d50:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d54:	04a49703          	lh	a4,74(s1)
    80003d58:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d5c:	44f8                	lw	a4,76(s1)
    80003d5e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d60:	03400613          	li	a2,52
    80003d64:	05048593          	addi	a1,s1,80
    80003d68:	0531                	addi	a0,a0,12
    80003d6a:	ffffd097          	auipc	ra,0xffffd
    80003d6e:	fd6080e7          	jalr	-42(ra) # 80000d40 <memmove>
  log_write(bp);
    80003d72:	854a                	mv	a0,s2
    80003d74:	00001097          	auipc	ra,0x1
    80003d78:	c06080e7          	jalr	-1018(ra) # 8000497a <log_write>
  brelse(bp);
    80003d7c:	854a                	mv	a0,s2
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	980080e7          	jalr	-1664(ra) # 800036fe <brelse>
}
    80003d86:	60e2                	ld	ra,24(sp)
    80003d88:	6442                	ld	s0,16(sp)
    80003d8a:	64a2                	ld	s1,8(sp)
    80003d8c:	6902                	ld	s2,0(sp)
    80003d8e:	6105                	addi	sp,sp,32
    80003d90:	8082                	ret

0000000080003d92 <idup>:
{
    80003d92:	1101                	addi	sp,sp,-32
    80003d94:	ec06                	sd	ra,24(sp)
    80003d96:	e822                	sd	s0,16(sp)
    80003d98:	e426                	sd	s1,8(sp)
    80003d9a:	1000                	addi	s0,sp,32
    80003d9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d9e:	0001e517          	auipc	a0,0x1e
    80003da2:	c4250513          	addi	a0,a0,-958 # 800219e0 <itable>
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	e3e080e7          	jalr	-450(ra) # 80000be4 <acquire>
  ip->ref++;
    80003dae:	449c                	lw	a5,8(s1)
    80003db0:	2785                	addiw	a5,a5,1
    80003db2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003db4:	0001e517          	auipc	a0,0x1e
    80003db8:	c2c50513          	addi	a0,a0,-980 # 800219e0 <itable>
    80003dbc:	ffffd097          	auipc	ra,0xffffd
    80003dc0:	edc080e7          	jalr	-292(ra) # 80000c98 <release>
}
    80003dc4:	8526                	mv	a0,s1
    80003dc6:	60e2                	ld	ra,24(sp)
    80003dc8:	6442                	ld	s0,16(sp)
    80003dca:	64a2                	ld	s1,8(sp)
    80003dcc:	6105                	addi	sp,sp,32
    80003dce:	8082                	ret

0000000080003dd0 <ilock>:
{
    80003dd0:	1101                	addi	sp,sp,-32
    80003dd2:	ec06                	sd	ra,24(sp)
    80003dd4:	e822                	sd	s0,16(sp)
    80003dd6:	e426                	sd	s1,8(sp)
    80003dd8:	e04a                	sd	s2,0(sp)
    80003dda:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ddc:	c115                	beqz	a0,80003e00 <ilock+0x30>
    80003dde:	84aa                	mv	s1,a0
    80003de0:	451c                	lw	a5,8(a0)
    80003de2:	00f05f63          	blez	a5,80003e00 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003de6:	0541                	addi	a0,a0,16
    80003de8:	00001097          	auipc	ra,0x1
    80003dec:	cb2080e7          	jalr	-846(ra) # 80004a9a <acquiresleep>
  if(ip->valid == 0){
    80003df0:	40bc                	lw	a5,64(s1)
    80003df2:	cf99                	beqz	a5,80003e10 <ilock+0x40>
}
    80003df4:	60e2                	ld	ra,24(sp)
    80003df6:	6442                	ld	s0,16(sp)
    80003df8:	64a2                	ld	s1,8(sp)
    80003dfa:	6902                	ld	s2,0(sp)
    80003dfc:	6105                	addi	sp,sp,32
    80003dfe:	8082                	ret
    panic("ilock");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	9d050513          	addi	a0,a0,-1584 # 800087d0 <syscalls+0x198>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	736080e7          	jalr	1846(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e10:	40dc                	lw	a5,4(s1)
    80003e12:	0047d79b          	srliw	a5,a5,0x4
    80003e16:	0001e597          	auipc	a1,0x1e
    80003e1a:	bc25a583          	lw	a1,-1086(a1) # 800219d8 <sb+0x18>
    80003e1e:	9dbd                	addw	a1,a1,a5
    80003e20:	4088                	lw	a0,0(s1)
    80003e22:	fffff097          	auipc	ra,0xfffff
    80003e26:	7ac080e7          	jalr	1964(ra) # 800035ce <bread>
    80003e2a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e2c:	05850593          	addi	a1,a0,88
    80003e30:	40dc                	lw	a5,4(s1)
    80003e32:	8bbd                	andi	a5,a5,15
    80003e34:	079a                	slli	a5,a5,0x6
    80003e36:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e38:	00059783          	lh	a5,0(a1)
    80003e3c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e40:	00259783          	lh	a5,2(a1)
    80003e44:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e48:	00459783          	lh	a5,4(a1)
    80003e4c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e50:	00659783          	lh	a5,6(a1)
    80003e54:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e58:	459c                	lw	a5,8(a1)
    80003e5a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e5c:	03400613          	li	a2,52
    80003e60:	05b1                	addi	a1,a1,12
    80003e62:	05048513          	addi	a0,s1,80
    80003e66:	ffffd097          	auipc	ra,0xffffd
    80003e6a:	eda080e7          	jalr	-294(ra) # 80000d40 <memmove>
    brelse(bp);
    80003e6e:	854a                	mv	a0,s2
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	88e080e7          	jalr	-1906(ra) # 800036fe <brelse>
    ip->valid = 1;
    80003e78:	4785                	li	a5,1
    80003e7a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e7c:	04449783          	lh	a5,68(s1)
    80003e80:	fbb5                	bnez	a5,80003df4 <ilock+0x24>
      panic("ilock: no type");
    80003e82:	00005517          	auipc	a0,0x5
    80003e86:	95650513          	addi	a0,a0,-1706 # 800087d8 <syscalls+0x1a0>
    80003e8a:	ffffc097          	auipc	ra,0xffffc
    80003e8e:	6b4080e7          	jalr	1716(ra) # 8000053e <panic>

0000000080003e92 <iunlock>:
{
    80003e92:	1101                	addi	sp,sp,-32
    80003e94:	ec06                	sd	ra,24(sp)
    80003e96:	e822                	sd	s0,16(sp)
    80003e98:	e426                	sd	s1,8(sp)
    80003e9a:	e04a                	sd	s2,0(sp)
    80003e9c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e9e:	c905                	beqz	a0,80003ece <iunlock+0x3c>
    80003ea0:	84aa                	mv	s1,a0
    80003ea2:	01050913          	addi	s2,a0,16
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00001097          	auipc	ra,0x1
    80003eac:	c8c080e7          	jalr	-884(ra) # 80004b34 <holdingsleep>
    80003eb0:	cd19                	beqz	a0,80003ece <iunlock+0x3c>
    80003eb2:	449c                	lw	a5,8(s1)
    80003eb4:	00f05d63          	blez	a5,80003ece <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003eb8:	854a                	mv	a0,s2
    80003eba:	00001097          	auipc	ra,0x1
    80003ebe:	c36080e7          	jalr	-970(ra) # 80004af0 <releasesleep>
}
    80003ec2:	60e2                	ld	ra,24(sp)
    80003ec4:	6442                	ld	s0,16(sp)
    80003ec6:	64a2                	ld	s1,8(sp)
    80003ec8:	6902                	ld	s2,0(sp)
    80003eca:	6105                	addi	sp,sp,32
    80003ecc:	8082                	ret
    panic("iunlock");
    80003ece:	00005517          	auipc	a0,0x5
    80003ed2:	91a50513          	addi	a0,a0,-1766 # 800087e8 <syscalls+0x1b0>
    80003ed6:	ffffc097          	auipc	ra,0xffffc
    80003eda:	668080e7          	jalr	1640(ra) # 8000053e <panic>

0000000080003ede <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ede:	7179                	addi	sp,sp,-48
    80003ee0:	f406                	sd	ra,40(sp)
    80003ee2:	f022                	sd	s0,32(sp)
    80003ee4:	ec26                	sd	s1,24(sp)
    80003ee6:	e84a                	sd	s2,16(sp)
    80003ee8:	e44e                	sd	s3,8(sp)
    80003eea:	e052                	sd	s4,0(sp)
    80003eec:	1800                	addi	s0,sp,48
    80003eee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ef0:	05050493          	addi	s1,a0,80
    80003ef4:	08050913          	addi	s2,a0,128
    80003ef8:	a021                	j	80003f00 <itrunc+0x22>
    80003efa:	0491                	addi	s1,s1,4
    80003efc:	01248d63          	beq	s1,s2,80003f16 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f00:	408c                	lw	a1,0(s1)
    80003f02:	dde5                	beqz	a1,80003efa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f04:	0009a503          	lw	a0,0(s3)
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	90c080e7          	jalr	-1780(ra) # 80003814 <bfree>
      ip->addrs[i] = 0;
    80003f10:	0004a023          	sw	zero,0(s1)
    80003f14:	b7dd                	j	80003efa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f16:	0809a583          	lw	a1,128(s3)
    80003f1a:	e185                	bnez	a1,80003f3a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f1c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f20:	854e                	mv	a0,s3
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	de4080e7          	jalr	-540(ra) # 80003d06 <iupdate>
}
    80003f2a:	70a2                	ld	ra,40(sp)
    80003f2c:	7402                	ld	s0,32(sp)
    80003f2e:	64e2                	ld	s1,24(sp)
    80003f30:	6942                	ld	s2,16(sp)
    80003f32:	69a2                	ld	s3,8(sp)
    80003f34:	6a02                	ld	s4,0(sp)
    80003f36:	6145                	addi	sp,sp,48
    80003f38:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f3a:	0009a503          	lw	a0,0(s3)
    80003f3e:	fffff097          	auipc	ra,0xfffff
    80003f42:	690080e7          	jalr	1680(ra) # 800035ce <bread>
    80003f46:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f48:	05850493          	addi	s1,a0,88
    80003f4c:	45850913          	addi	s2,a0,1112
    80003f50:	a811                	j	80003f64 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003f52:	0009a503          	lw	a0,0(s3)
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	8be080e7          	jalr	-1858(ra) # 80003814 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003f5e:	0491                	addi	s1,s1,4
    80003f60:	01248563          	beq	s1,s2,80003f6a <itrunc+0x8c>
      if(a[j])
    80003f64:	408c                	lw	a1,0(s1)
    80003f66:	dde5                	beqz	a1,80003f5e <itrunc+0x80>
    80003f68:	b7ed                	j	80003f52 <itrunc+0x74>
    brelse(bp);
    80003f6a:	8552                	mv	a0,s4
    80003f6c:	fffff097          	auipc	ra,0xfffff
    80003f70:	792080e7          	jalr	1938(ra) # 800036fe <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f74:	0809a583          	lw	a1,128(s3)
    80003f78:	0009a503          	lw	a0,0(s3)
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	898080e7          	jalr	-1896(ra) # 80003814 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f84:	0809a023          	sw	zero,128(s3)
    80003f88:	bf51                	j	80003f1c <itrunc+0x3e>

0000000080003f8a <iput>:
{
    80003f8a:	1101                	addi	sp,sp,-32
    80003f8c:	ec06                	sd	ra,24(sp)
    80003f8e:	e822                	sd	s0,16(sp)
    80003f90:	e426                	sd	s1,8(sp)
    80003f92:	e04a                	sd	s2,0(sp)
    80003f94:	1000                	addi	s0,sp,32
    80003f96:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f98:	0001e517          	auipc	a0,0x1e
    80003f9c:	a4850513          	addi	a0,a0,-1464 # 800219e0 <itable>
    80003fa0:	ffffd097          	auipc	ra,0xffffd
    80003fa4:	c44080e7          	jalr	-956(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fa8:	4498                	lw	a4,8(s1)
    80003faa:	4785                	li	a5,1
    80003fac:	02f70363          	beq	a4,a5,80003fd2 <iput+0x48>
  ip->ref--;
    80003fb0:	449c                	lw	a5,8(s1)
    80003fb2:	37fd                	addiw	a5,a5,-1
    80003fb4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fb6:	0001e517          	auipc	a0,0x1e
    80003fba:	a2a50513          	addi	a0,a0,-1494 # 800219e0 <itable>
    80003fbe:	ffffd097          	auipc	ra,0xffffd
    80003fc2:	cda080e7          	jalr	-806(ra) # 80000c98 <release>
}
    80003fc6:	60e2                	ld	ra,24(sp)
    80003fc8:	6442                	ld	s0,16(sp)
    80003fca:	64a2                	ld	s1,8(sp)
    80003fcc:	6902                	ld	s2,0(sp)
    80003fce:	6105                	addi	sp,sp,32
    80003fd0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fd2:	40bc                	lw	a5,64(s1)
    80003fd4:	dff1                	beqz	a5,80003fb0 <iput+0x26>
    80003fd6:	04a49783          	lh	a5,74(s1)
    80003fda:	fbf9                	bnez	a5,80003fb0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fdc:	01048913          	addi	s2,s1,16
    80003fe0:	854a                	mv	a0,s2
    80003fe2:	00001097          	auipc	ra,0x1
    80003fe6:	ab8080e7          	jalr	-1352(ra) # 80004a9a <acquiresleep>
    release(&itable.lock);
    80003fea:	0001e517          	auipc	a0,0x1e
    80003fee:	9f650513          	addi	a0,a0,-1546 # 800219e0 <itable>
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	ca6080e7          	jalr	-858(ra) # 80000c98 <release>
    itrunc(ip);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	ee2080e7          	jalr	-286(ra) # 80003ede <itrunc>
    ip->type = 0;
    80004004:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004008:	8526                	mv	a0,s1
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	cfc080e7          	jalr	-772(ra) # 80003d06 <iupdate>
    ip->valid = 0;
    80004012:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004016:	854a                	mv	a0,s2
    80004018:	00001097          	auipc	ra,0x1
    8000401c:	ad8080e7          	jalr	-1320(ra) # 80004af0 <releasesleep>
    acquire(&itable.lock);
    80004020:	0001e517          	auipc	a0,0x1e
    80004024:	9c050513          	addi	a0,a0,-1600 # 800219e0 <itable>
    80004028:	ffffd097          	auipc	ra,0xffffd
    8000402c:	bbc080e7          	jalr	-1092(ra) # 80000be4 <acquire>
    80004030:	b741                	j	80003fb0 <iput+0x26>

0000000080004032 <iunlockput>:
{
    80004032:	1101                	addi	sp,sp,-32
    80004034:	ec06                	sd	ra,24(sp)
    80004036:	e822                	sd	s0,16(sp)
    80004038:	e426                	sd	s1,8(sp)
    8000403a:	1000                	addi	s0,sp,32
    8000403c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	e54080e7          	jalr	-428(ra) # 80003e92 <iunlock>
  iput(ip);
    80004046:	8526                	mv	a0,s1
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	f42080e7          	jalr	-190(ra) # 80003f8a <iput>
}
    80004050:	60e2                	ld	ra,24(sp)
    80004052:	6442                	ld	s0,16(sp)
    80004054:	64a2                	ld	s1,8(sp)
    80004056:	6105                	addi	sp,sp,32
    80004058:	8082                	ret

000000008000405a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000405a:	1141                	addi	sp,sp,-16
    8000405c:	e422                	sd	s0,8(sp)
    8000405e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004060:	411c                	lw	a5,0(a0)
    80004062:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004064:	415c                	lw	a5,4(a0)
    80004066:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004068:	04451783          	lh	a5,68(a0)
    8000406c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004070:	04a51783          	lh	a5,74(a0)
    80004074:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004078:	04c56783          	lwu	a5,76(a0)
    8000407c:	e99c                	sd	a5,16(a1)
}
    8000407e:	6422                	ld	s0,8(sp)
    80004080:	0141                	addi	sp,sp,16
    80004082:	8082                	ret

0000000080004084 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004084:	457c                	lw	a5,76(a0)
    80004086:	0ed7e963          	bltu	a5,a3,80004178 <readi+0xf4>
{
    8000408a:	7159                	addi	sp,sp,-112
    8000408c:	f486                	sd	ra,104(sp)
    8000408e:	f0a2                	sd	s0,96(sp)
    80004090:	eca6                	sd	s1,88(sp)
    80004092:	e8ca                	sd	s2,80(sp)
    80004094:	e4ce                	sd	s3,72(sp)
    80004096:	e0d2                	sd	s4,64(sp)
    80004098:	fc56                	sd	s5,56(sp)
    8000409a:	f85a                	sd	s6,48(sp)
    8000409c:	f45e                	sd	s7,40(sp)
    8000409e:	f062                	sd	s8,32(sp)
    800040a0:	ec66                	sd	s9,24(sp)
    800040a2:	e86a                	sd	s10,16(sp)
    800040a4:	e46e                	sd	s11,8(sp)
    800040a6:	1880                	addi	s0,sp,112
    800040a8:	8baa                	mv	s7,a0
    800040aa:	8c2e                	mv	s8,a1
    800040ac:	8ab2                	mv	s5,a2
    800040ae:	84b6                	mv	s1,a3
    800040b0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040b2:	9f35                	addw	a4,a4,a3
    return 0;
    800040b4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040b6:	0ad76063          	bltu	a4,a3,80004156 <readi+0xd2>
  if(off + n > ip->size)
    800040ba:	00e7f463          	bgeu	a5,a4,800040c2 <readi+0x3e>
    n = ip->size - off;
    800040be:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040c2:	0a0b0963          	beqz	s6,80004174 <readi+0xf0>
    800040c6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040c8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040cc:	5cfd                	li	s9,-1
    800040ce:	a82d                	j	80004108 <readi+0x84>
    800040d0:	020a1d93          	slli	s11,s4,0x20
    800040d4:	020ddd93          	srli	s11,s11,0x20
    800040d8:	05890613          	addi	a2,s2,88
    800040dc:	86ee                	mv	a3,s11
    800040de:	963a                	add	a2,a2,a4
    800040e0:	85d6                	mv	a1,s5
    800040e2:	8562                	mv	a0,s8
    800040e4:	ffffe097          	auipc	ra,0xffffe
    800040e8:	54a080e7          	jalr	1354(ra) # 8000262e <either_copyout>
    800040ec:	05950d63          	beq	a0,s9,80004146 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040f0:	854a                	mv	a0,s2
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	60c080e7          	jalr	1548(ra) # 800036fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040fa:	013a09bb          	addw	s3,s4,s3
    800040fe:	009a04bb          	addw	s1,s4,s1
    80004102:	9aee                	add	s5,s5,s11
    80004104:	0569f763          	bgeu	s3,s6,80004152 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004108:	000ba903          	lw	s2,0(s7)
    8000410c:	00a4d59b          	srliw	a1,s1,0xa
    80004110:	855e                	mv	a0,s7
    80004112:	00000097          	auipc	ra,0x0
    80004116:	8b0080e7          	jalr	-1872(ra) # 800039c2 <bmap>
    8000411a:	0005059b          	sext.w	a1,a0
    8000411e:	854a                	mv	a0,s2
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	4ae080e7          	jalr	1198(ra) # 800035ce <bread>
    80004128:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000412a:	3ff4f713          	andi	a4,s1,1023
    8000412e:	40ed07bb          	subw	a5,s10,a4
    80004132:	413b06bb          	subw	a3,s6,s3
    80004136:	8a3e                	mv	s4,a5
    80004138:	2781                	sext.w	a5,a5
    8000413a:	0006861b          	sext.w	a2,a3
    8000413e:	f8f679e3          	bgeu	a2,a5,800040d0 <readi+0x4c>
    80004142:	8a36                	mv	s4,a3
    80004144:	b771                	j	800040d0 <readi+0x4c>
      brelse(bp);
    80004146:	854a                	mv	a0,s2
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	5b6080e7          	jalr	1462(ra) # 800036fe <brelse>
      tot = -1;
    80004150:	59fd                	li	s3,-1
  }
  return tot;
    80004152:	0009851b          	sext.w	a0,s3
}
    80004156:	70a6                	ld	ra,104(sp)
    80004158:	7406                	ld	s0,96(sp)
    8000415a:	64e6                	ld	s1,88(sp)
    8000415c:	6946                	ld	s2,80(sp)
    8000415e:	69a6                	ld	s3,72(sp)
    80004160:	6a06                	ld	s4,64(sp)
    80004162:	7ae2                	ld	s5,56(sp)
    80004164:	7b42                	ld	s6,48(sp)
    80004166:	7ba2                	ld	s7,40(sp)
    80004168:	7c02                	ld	s8,32(sp)
    8000416a:	6ce2                	ld	s9,24(sp)
    8000416c:	6d42                	ld	s10,16(sp)
    8000416e:	6da2                	ld	s11,8(sp)
    80004170:	6165                	addi	sp,sp,112
    80004172:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004174:	89da                	mv	s3,s6
    80004176:	bff1                	j	80004152 <readi+0xce>
    return 0;
    80004178:	4501                	li	a0,0
}
    8000417a:	8082                	ret

000000008000417c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000417c:	457c                	lw	a5,76(a0)
    8000417e:	10d7e863          	bltu	a5,a3,8000428e <writei+0x112>
{
    80004182:	7159                	addi	sp,sp,-112
    80004184:	f486                	sd	ra,104(sp)
    80004186:	f0a2                	sd	s0,96(sp)
    80004188:	eca6                	sd	s1,88(sp)
    8000418a:	e8ca                	sd	s2,80(sp)
    8000418c:	e4ce                	sd	s3,72(sp)
    8000418e:	e0d2                	sd	s4,64(sp)
    80004190:	fc56                	sd	s5,56(sp)
    80004192:	f85a                	sd	s6,48(sp)
    80004194:	f45e                	sd	s7,40(sp)
    80004196:	f062                	sd	s8,32(sp)
    80004198:	ec66                	sd	s9,24(sp)
    8000419a:	e86a                	sd	s10,16(sp)
    8000419c:	e46e                	sd	s11,8(sp)
    8000419e:	1880                	addi	s0,sp,112
    800041a0:	8b2a                	mv	s6,a0
    800041a2:	8c2e                	mv	s8,a1
    800041a4:	8ab2                	mv	s5,a2
    800041a6:	8936                	mv	s2,a3
    800041a8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800041aa:	00e687bb          	addw	a5,a3,a4
    800041ae:	0ed7e263          	bltu	a5,a3,80004292 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041b2:	00043737          	lui	a4,0x43
    800041b6:	0ef76063          	bltu	a4,a5,80004296 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ba:	0c0b8863          	beqz	s7,8000428a <writei+0x10e>
    800041be:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041c0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041c4:	5cfd                	li	s9,-1
    800041c6:	a091                	j	8000420a <writei+0x8e>
    800041c8:	02099d93          	slli	s11,s3,0x20
    800041cc:	020ddd93          	srli	s11,s11,0x20
    800041d0:	05848513          	addi	a0,s1,88
    800041d4:	86ee                	mv	a3,s11
    800041d6:	8656                	mv	a2,s5
    800041d8:	85e2                	mv	a1,s8
    800041da:	953a                	add	a0,a0,a4
    800041dc:	ffffe097          	auipc	ra,0xffffe
    800041e0:	4a8080e7          	jalr	1192(ra) # 80002684 <either_copyin>
    800041e4:	07950263          	beq	a0,s9,80004248 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041e8:	8526                	mv	a0,s1
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	790080e7          	jalr	1936(ra) # 8000497a <log_write>
    brelse(bp);
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	50a080e7          	jalr	1290(ra) # 800036fe <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041fc:	01498a3b          	addw	s4,s3,s4
    80004200:	0129893b          	addw	s2,s3,s2
    80004204:	9aee                	add	s5,s5,s11
    80004206:	057a7663          	bgeu	s4,s7,80004252 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000420a:	000b2483          	lw	s1,0(s6)
    8000420e:	00a9559b          	srliw	a1,s2,0xa
    80004212:	855a                	mv	a0,s6
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	7ae080e7          	jalr	1966(ra) # 800039c2 <bmap>
    8000421c:	0005059b          	sext.w	a1,a0
    80004220:	8526                	mv	a0,s1
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	3ac080e7          	jalr	940(ra) # 800035ce <bread>
    8000422a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000422c:	3ff97713          	andi	a4,s2,1023
    80004230:	40ed07bb          	subw	a5,s10,a4
    80004234:	414b86bb          	subw	a3,s7,s4
    80004238:	89be                	mv	s3,a5
    8000423a:	2781                	sext.w	a5,a5
    8000423c:	0006861b          	sext.w	a2,a3
    80004240:	f8f674e3          	bgeu	a2,a5,800041c8 <writei+0x4c>
    80004244:	89b6                	mv	s3,a3
    80004246:	b749                	j	800041c8 <writei+0x4c>
      brelse(bp);
    80004248:	8526                	mv	a0,s1
    8000424a:	fffff097          	auipc	ra,0xfffff
    8000424e:	4b4080e7          	jalr	1204(ra) # 800036fe <brelse>
  }

  if(off > ip->size)
    80004252:	04cb2783          	lw	a5,76(s6)
    80004256:	0127f463          	bgeu	a5,s2,8000425e <writei+0xe2>
    ip->size = off;
    8000425a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000425e:	855a                	mv	a0,s6
    80004260:	00000097          	auipc	ra,0x0
    80004264:	aa6080e7          	jalr	-1370(ra) # 80003d06 <iupdate>

  return tot;
    80004268:	000a051b          	sext.w	a0,s4
}
    8000426c:	70a6                	ld	ra,104(sp)
    8000426e:	7406                	ld	s0,96(sp)
    80004270:	64e6                	ld	s1,88(sp)
    80004272:	6946                	ld	s2,80(sp)
    80004274:	69a6                	ld	s3,72(sp)
    80004276:	6a06                	ld	s4,64(sp)
    80004278:	7ae2                	ld	s5,56(sp)
    8000427a:	7b42                	ld	s6,48(sp)
    8000427c:	7ba2                	ld	s7,40(sp)
    8000427e:	7c02                	ld	s8,32(sp)
    80004280:	6ce2                	ld	s9,24(sp)
    80004282:	6d42                	ld	s10,16(sp)
    80004284:	6da2                	ld	s11,8(sp)
    80004286:	6165                	addi	sp,sp,112
    80004288:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000428a:	8a5e                	mv	s4,s7
    8000428c:	bfc9                	j	8000425e <writei+0xe2>
    return -1;
    8000428e:	557d                	li	a0,-1
}
    80004290:	8082                	ret
    return -1;
    80004292:	557d                	li	a0,-1
    80004294:	bfe1                	j	8000426c <writei+0xf0>
    return -1;
    80004296:	557d                	li	a0,-1
    80004298:	bfd1                	j	8000426c <writei+0xf0>

000000008000429a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000429a:	1141                	addi	sp,sp,-16
    8000429c:	e406                	sd	ra,8(sp)
    8000429e:	e022                	sd	s0,0(sp)
    800042a0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042a2:	4639                	li	a2,14
    800042a4:	ffffd097          	auipc	ra,0xffffd
    800042a8:	b14080e7          	jalr	-1260(ra) # 80000db8 <strncmp>
}
    800042ac:	60a2                	ld	ra,8(sp)
    800042ae:	6402                	ld	s0,0(sp)
    800042b0:	0141                	addi	sp,sp,16
    800042b2:	8082                	ret

00000000800042b4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042b4:	7139                	addi	sp,sp,-64
    800042b6:	fc06                	sd	ra,56(sp)
    800042b8:	f822                	sd	s0,48(sp)
    800042ba:	f426                	sd	s1,40(sp)
    800042bc:	f04a                	sd	s2,32(sp)
    800042be:	ec4e                	sd	s3,24(sp)
    800042c0:	e852                	sd	s4,16(sp)
    800042c2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042c4:	04451703          	lh	a4,68(a0)
    800042c8:	4785                	li	a5,1
    800042ca:	00f71a63          	bne	a4,a5,800042de <dirlookup+0x2a>
    800042ce:	892a                	mv	s2,a0
    800042d0:	89ae                	mv	s3,a1
    800042d2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042d4:	457c                	lw	a5,76(a0)
    800042d6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042d8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042da:	e79d                	bnez	a5,80004308 <dirlookup+0x54>
    800042dc:	a8a5                	j	80004354 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042de:	00004517          	auipc	a0,0x4
    800042e2:	51250513          	addi	a0,a0,1298 # 800087f0 <syscalls+0x1b8>
    800042e6:	ffffc097          	auipc	ra,0xffffc
    800042ea:	258080e7          	jalr	600(ra) # 8000053e <panic>
      panic("dirlookup read");
    800042ee:	00004517          	auipc	a0,0x4
    800042f2:	51a50513          	addi	a0,a0,1306 # 80008808 <syscalls+0x1d0>
    800042f6:	ffffc097          	auipc	ra,0xffffc
    800042fa:	248080e7          	jalr	584(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042fe:	24c1                	addiw	s1,s1,16
    80004300:	04c92783          	lw	a5,76(s2)
    80004304:	04f4f763          	bgeu	s1,a5,80004352 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004308:	4741                	li	a4,16
    8000430a:	86a6                	mv	a3,s1
    8000430c:	fc040613          	addi	a2,s0,-64
    80004310:	4581                	li	a1,0
    80004312:	854a                	mv	a0,s2
    80004314:	00000097          	auipc	ra,0x0
    80004318:	d70080e7          	jalr	-656(ra) # 80004084 <readi>
    8000431c:	47c1                	li	a5,16
    8000431e:	fcf518e3          	bne	a0,a5,800042ee <dirlookup+0x3a>
    if(de.inum == 0)
    80004322:	fc045783          	lhu	a5,-64(s0)
    80004326:	dfe1                	beqz	a5,800042fe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004328:	fc240593          	addi	a1,s0,-62
    8000432c:	854e                	mv	a0,s3
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	f6c080e7          	jalr	-148(ra) # 8000429a <namecmp>
    80004336:	f561                	bnez	a0,800042fe <dirlookup+0x4a>
      if(poff)
    80004338:	000a0463          	beqz	s4,80004340 <dirlookup+0x8c>
        *poff = off;
    8000433c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004340:	fc045583          	lhu	a1,-64(s0)
    80004344:	00092503          	lw	a0,0(s2)
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	754080e7          	jalr	1876(ra) # 80003a9c <iget>
    80004350:	a011                	j	80004354 <dirlookup+0xa0>
  return 0;
    80004352:	4501                	li	a0,0
}
    80004354:	70e2                	ld	ra,56(sp)
    80004356:	7442                	ld	s0,48(sp)
    80004358:	74a2                	ld	s1,40(sp)
    8000435a:	7902                	ld	s2,32(sp)
    8000435c:	69e2                	ld	s3,24(sp)
    8000435e:	6a42                	ld	s4,16(sp)
    80004360:	6121                	addi	sp,sp,64
    80004362:	8082                	ret

0000000080004364 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004364:	711d                	addi	sp,sp,-96
    80004366:	ec86                	sd	ra,88(sp)
    80004368:	e8a2                	sd	s0,80(sp)
    8000436a:	e4a6                	sd	s1,72(sp)
    8000436c:	e0ca                	sd	s2,64(sp)
    8000436e:	fc4e                	sd	s3,56(sp)
    80004370:	f852                	sd	s4,48(sp)
    80004372:	f456                	sd	s5,40(sp)
    80004374:	f05a                	sd	s6,32(sp)
    80004376:	ec5e                	sd	s7,24(sp)
    80004378:	e862                	sd	s8,16(sp)
    8000437a:	e466                	sd	s9,8(sp)
    8000437c:	1080                	addi	s0,sp,96
    8000437e:	84aa                	mv	s1,a0
    80004380:	8b2e                	mv	s6,a1
    80004382:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004384:	00054703          	lbu	a4,0(a0)
    80004388:	02f00793          	li	a5,47
    8000438c:	02f70363          	beq	a4,a5,800043b2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	7ae080e7          	jalr	1966(ra) # 80001b3e <myproc>
    80004398:	15053503          	ld	a0,336(a0)
    8000439c:	00000097          	auipc	ra,0x0
    800043a0:	9f6080e7          	jalr	-1546(ra) # 80003d92 <idup>
    800043a4:	89aa                	mv	s3,a0
  while(*path == '/')
    800043a6:	02f00913          	li	s2,47
  len = path - s;
    800043aa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800043ac:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043ae:	4c05                	li	s8,1
    800043b0:	a865                	j	80004468 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800043b2:	4585                	li	a1,1
    800043b4:	4505                	li	a0,1
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	6e6080e7          	jalr	1766(ra) # 80003a9c <iget>
    800043be:	89aa                	mv	s3,a0
    800043c0:	b7dd                	j	800043a6 <namex+0x42>
      iunlockput(ip);
    800043c2:	854e                	mv	a0,s3
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	c6e080e7          	jalr	-914(ra) # 80004032 <iunlockput>
      return 0;
    800043cc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043ce:	854e                	mv	a0,s3
    800043d0:	60e6                	ld	ra,88(sp)
    800043d2:	6446                	ld	s0,80(sp)
    800043d4:	64a6                	ld	s1,72(sp)
    800043d6:	6906                	ld	s2,64(sp)
    800043d8:	79e2                	ld	s3,56(sp)
    800043da:	7a42                	ld	s4,48(sp)
    800043dc:	7aa2                	ld	s5,40(sp)
    800043de:	7b02                	ld	s6,32(sp)
    800043e0:	6be2                	ld	s7,24(sp)
    800043e2:	6c42                	ld	s8,16(sp)
    800043e4:	6ca2                	ld	s9,8(sp)
    800043e6:	6125                	addi	sp,sp,96
    800043e8:	8082                	ret
      iunlock(ip);
    800043ea:	854e                	mv	a0,s3
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	aa6080e7          	jalr	-1370(ra) # 80003e92 <iunlock>
      return ip;
    800043f4:	bfe9                	j	800043ce <namex+0x6a>
      iunlockput(ip);
    800043f6:	854e                	mv	a0,s3
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	c3a080e7          	jalr	-966(ra) # 80004032 <iunlockput>
      return 0;
    80004400:	89d2                	mv	s3,s4
    80004402:	b7f1                	j	800043ce <namex+0x6a>
  len = path - s;
    80004404:	40b48633          	sub	a2,s1,a1
    80004408:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000440c:	094cd463          	bge	s9,s4,80004494 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004410:	4639                	li	a2,14
    80004412:	8556                	mv	a0,s5
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	92c080e7          	jalr	-1748(ra) # 80000d40 <memmove>
  while(*path == '/')
    8000441c:	0004c783          	lbu	a5,0(s1)
    80004420:	01279763          	bne	a5,s2,8000442e <namex+0xca>
    path++;
    80004424:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004426:	0004c783          	lbu	a5,0(s1)
    8000442a:	ff278de3          	beq	a5,s2,80004424 <namex+0xc0>
    ilock(ip);
    8000442e:	854e                	mv	a0,s3
    80004430:	00000097          	auipc	ra,0x0
    80004434:	9a0080e7          	jalr	-1632(ra) # 80003dd0 <ilock>
    if(ip->type != T_DIR){
    80004438:	04499783          	lh	a5,68(s3)
    8000443c:	f98793e3          	bne	a5,s8,800043c2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004440:	000b0563          	beqz	s6,8000444a <namex+0xe6>
    80004444:	0004c783          	lbu	a5,0(s1)
    80004448:	d3cd                	beqz	a5,800043ea <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000444a:	865e                	mv	a2,s7
    8000444c:	85d6                	mv	a1,s5
    8000444e:	854e                	mv	a0,s3
    80004450:	00000097          	auipc	ra,0x0
    80004454:	e64080e7          	jalr	-412(ra) # 800042b4 <dirlookup>
    80004458:	8a2a                	mv	s4,a0
    8000445a:	dd51                	beqz	a0,800043f6 <namex+0x92>
    iunlockput(ip);
    8000445c:	854e                	mv	a0,s3
    8000445e:	00000097          	auipc	ra,0x0
    80004462:	bd4080e7          	jalr	-1068(ra) # 80004032 <iunlockput>
    ip = next;
    80004466:	89d2                	mv	s3,s4
  while(*path == '/')
    80004468:	0004c783          	lbu	a5,0(s1)
    8000446c:	05279763          	bne	a5,s2,800044ba <namex+0x156>
    path++;
    80004470:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004472:	0004c783          	lbu	a5,0(s1)
    80004476:	ff278de3          	beq	a5,s2,80004470 <namex+0x10c>
  if(*path == 0)
    8000447a:	c79d                	beqz	a5,800044a8 <namex+0x144>
    path++;
    8000447c:	85a6                	mv	a1,s1
  len = path - s;
    8000447e:	8a5e                	mv	s4,s7
    80004480:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004482:	01278963          	beq	a5,s2,80004494 <namex+0x130>
    80004486:	dfbd                	beqz	a5,80004404 <namex+0xa0>
    path++;
    80004488:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000448a:	0004c783          	lbu	a5,0(s1)
    8000448e:	ff279ce3          	bne	a5,s2,80004486 <namex+0x122>
    80004492:	bf8d                	j	80004404 <namex+0xa0>
    memmove(name, s, len);
    80004494:	2601                	sext.w	a2,a2
    80004496:	8556                	mv	a0,s5
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	8a8080e7          	jalr	-1880(ra) # 80000d40 <memmove>
    name[len] = 0;
    800044a0:	9a56                	add	s4,s4,s5
    800044a2:	000a0023          	sb	zero,0(s4)
    800044a6:	bf9d                	j	8000441c <namex+0xb8>
  if(nameiparent){
    800044a8:	f20b03e3          	beqz	s6,800043ce <namex+0x6a>
    iput(ip);
    800044ac:	854e                	mv	a0,s3
    800044ae:	00000097          	auipc	ra,0x0
    800044b2:	adc080e7          	jalr	-1316(ra) # 80003f8a <iput>
    return 0;
    800044b6:	4981                	li	s3,0
    800044b8:	bf19                	j	800043ce <namex+0x6a>
  if(*path == 0)
    800044ba:	d7fd                	beqz	a5,800044a8 <namex+0x144>
  while(*path != '/' && *path != 0)
    800044bc:	0004c783          	lbu	a5,0(s1)
    800044c0:	85a6                	mv	a1,s1
    800044c2:	b7d1                	j	80004486 <namex+0x122>

00000000800044c4 <dirlink>:
{
    800044c4:	7139                	addi	sp,sp,-64
    800044c6:	fc06                	sd	ra,56(sp)
    800044c8:	f822                	sd	s0,48(sp)
    800044ca:	f426                	sd	s1,40(sp)
    800044cc:	f04a                	sd	s2,32(sp)
    800044ce:	ec4e                	sd	s3,24(sp)
    800044d0:	e852                	sd	s4,16(sp)
    800044d2:	0080                	addi	s0,sp,64
    800044d4:	892a                	mv	s2,a0
    800044d6:	8a2e                	mv	s4,a1
    800044d8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044da:	4601                	li	a2,0
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	dd8080e7          	jalr	-552(ra) # 800042b4 <dirlookup>
    800044e4:	e93d                	bnez	a0,8000455a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044e6:	04c92483          	lw	s1,76(s2)
    800044ea:	c49d                	beqz	s1,80004518 <dirlink+0x54>
    800044ec:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044ee:	4741                	li	a4,16
    800044f0:	86a6                	mv	a3,s1
    800044f2:	fc040613          	addi	a2,s0,-64
    800044f6:	4581                	li	a1,0
    800044f8:	854a                	mv	a0,s2
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	b8a080e7          	jalr	-1142(ra) # 80004084 <readi>
    80004502:	47c1                	li	a5,16
    80004504:	06f51163          	bne	a0,a5,80004566 <dirlink+0xa2>
    if(de.inum == 0)
    80004508:	fc045783          	lhu	a5,-64(s0)
    8000450c:	c791                	beqz	a5,80004518 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000450e:	24c1                	addiw	s1,s1,16
    80004510:	04c92783          	lw	a5,76(s2)
    80004514:	fcf4ede3          	bltu	s1,a5,800044ee <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004518:	4639                	li	a2,14
    8000451a:	85d2                	mv	a1,s4
    8000451c:	fc240513          	addi	a0,s0,-62
    80004520:	ffffd097          	auipc	ra,0xffffd
    80004524:	8d4080e7          	jalr	-1836(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80004528:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000452c:	4741                	li	a4,16
    8000452e:	86a6                	mv	a3,s1
    80004530:	fc040613          	addi	a2,s0,-64
    80004534:	4581                	li	a1,0
    80004536:	854a                	mv	a0,s2
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	c44080e7          	jalr	-956(ra) # 8000417c <writei>
    80004540:	872a                	mv	a4,a0
    80004542:	47c1                	li	a5,16
  return 0;
    80004544:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004546:	02f71863          	bne	a4,a5,80004576 <dirlink+0xb2>
}
    8000454a:	70e2                	ld	ra,56(sp)
    8000454c:	7442                	ld	s0,48(sp)
    8000454e:	74a2                	ld	s1,40(sp)
    80004550:	7902                	ld	s2,32(sp)
    80004552:	69e2                	ld	s3,24(sp)
    80004554:	6a42                	ld	s4,16(sp)
    80004556:	6121                	addi	sp,sp,64
    80004558:	8082                	ret
    iput(ip);
    8000455a:	00000097          	auipc	ra,0x0
    8000455e:	a30080e7          	jalr	-1488(ra) # 80003f8a <iput>
    return -1;
    80004562:	557d                	li	a0,-1
    80004564:	b7dd                	j	8000454a <dirlink+0x86>
      panic("dirlink read");
    80004566:	00004517          	auipc	a0,0x4
    8000456a:	2b250513          	addi	a0,a0,690 # 80008818 <syscalls+0x1e0>
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	fd0080e7          	jalr	-48(ra) # 8000053e <panic>
    panic("dirlink");
    80004576:	00004517          	auipc	a0,0x4
    8000457a:	3aa50513          	addi	a0,a0,938 # 80008920 <syscalls+0x2e8>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	fc0080e7          	jalr	-64(ra) # 8000053e <panic>

0000000080004586 <namei>:

struct inode*
namei(char *path)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000458e:	fe040613          	addi	a2,s0,-32
    80004592:	4581                	li	a1,0
    80004594:	00000097          	auipc	ra,0x0
    80004598:	dd0080e7          	jalr	-560(ra) # 80004364 <namex>
}
    8000459c:	60e2                	ld	ra,24(sp)
    8000459e:	6442                	ld	s0,16(sp)
    800045a0:	6105                	addi	sp,sp,32
    800045a2:	8082                	ret

00000000800045a4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045a4:	1141                	addi	sp,sp,-16
    800045a6:	e406                	sd	ra,8(sp)
    800045a8:	e022                	sd	s0,0(sp)
    800045aa:	0800                	addi	s0,sp,16
    800045ac:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045ae:	4585                	li	a1,1
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	db4080e7          	jalr	-588(ra) # 80004364 <namex>
}
    800045b8:	60a2                	ld	ra,8(sp)
    800045ba:	6402                	ld	s0,0(sp)
    800045bc:	0141                	addi	sp,sp,16
    800045be:	8082                	ret

00000000800045c0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045c0:	1101                	addi	sp,sp,-32
    800045c2:	ec06                	sd	ra,24(sp)
    800045c4:	e822                	sd	s0,16(sp)
    800045c6:	e426                	sd	s1,8(sp)
    800045c8:	e04a                	sd	s2,0(sp)
    800045ca:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045cc:	0001f917          	auipc	s2,0x1f
    800045d0:	ebc90913          	addi	s2,s2,-324 # 80023488 <log>
    800045d4:	01892583          	lw	a1,24(s2)
    800045d8:	02892503          	lw	a0,40(s2)
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	ff2080e7          	jalr	-14(ra) # 800035ce <bread>
    800045e4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045e6:	02c92683          	lw	a3,44(s2)
    800045ea:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045ec:	02d05763          	blez	a3,8000461a <write_head+0x5a>
    800045f0:	0001f797          	auipc	a5,0x1f
    800045f4:	ec878793          	addi	a5,a5,-312 # 800234b8 <log+0x30>
    800045f8:	05c50713          	addi	a4,a0,92
    800045fc:	36fd                	addiw	a3,a3,-1
    800045fe:	1682                	slli	a3,a3,0x20
    80004600:	9281                	srli	a3,a3,0x20
    80004602:	068a                	slli	a3,a3,0x2
    80004604:	0001f617          	auipc	a2,0x1f
    80004608:	eb860613          	addi	a2,a2,-328 # 800234bc <log+0x34>
    8000460c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000460e:	4390                	lw	a2,0(a5)
    80004610:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004612:	0791                	addi	a5,a5,4
    80004614:	0711                	addi	a4,a4,4
    80004616:	fed79ce3          	bne	a5,a3,8000460e <write_head+0x4e>
  }
  bwrite(buf);
    8000461a:	8526                	mv	a0,s1
    8000461c:	fffff097          	auipc	ra,0xfffff
    80004620:	0a4080e7          	jalr	164(ra) # 800036c0 <bwrite>
  brelse(buf);
    80004624:	8526                	mv	a0,s1
    80004626:	fffff097          	auipc	ra,0xfffff
    8000462a:	0d8080e7          	jalr	216(ra) # 800036fe <brelse>
}
    8000462e:	60e2                	ld	ra,24(sp)
    80004630:	6442                	ld	s0,16(sp)
    80004632:	64a2                	ld	s1,8(sp)
    80004634:	6902                	ld	s2,0(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret

000000008000463a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000463a:	0001f797          	auipc	a5,0x1f
    8000463e:	e7a7a783          	lw	a5,-390(a5) # 800234b4 <log+0x2c>
    80004642:	0af05d63          	blez	a5,800046fc <install_trans+0xc2>
{
    80004646:	7139                	addi	sp,sp,-64
    80004648:	fc06                	sd	ra,56(sp)
    8000464a:	f822                	sd	s0,48(sp)
    8000464c:	f426                	sd	s1,40(sp)
    8000464e:	f04a                	sd	s2,32(sp)
    80004650:	ec4e                	sd	s3,24(sp)
    80004652:	e852                	sd	s4,16(sp)
    80004654:	e456                	sd	s5,8(sp)
    80004656:	e05a                	sd	s6,0(sp)
    80004658:	0080                	addi	s0,sp,64
    8000465a:	8b2a                	mv	s6,a0
    8000465c:	0001fa97          	auipc	s5,0x1f
    80004660:	e5ca8a93          	addi	s5,s5,-420 # 800234b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004664:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004666:	0001f997          	auipc	s3,0x1f
    8000466a:	e2298993          	addi	s3,s3,-478 # 80023488 <log>
    8000466e:	a035                	j	8000469a <install_trans+0x60>
      bunpin(dbuf);
    80004670:	8526                	mv	a0,s1
    80004672:	fffff097          	auipc	ra,0xfffff
    80004676:	166080e7          	jalr	358(ra) # 800037d8 <bunpin>
    brelse(lbuf);
    8000467a:	854a                	mv	a0,s2
    8000467c:	fffff097          	auipc	ra,0xfffff
    80004680:	082080e7          	jalr	130(ra) # 800036fe <brelse>
    brelse(dbuf);
    80004684:	8526                	mv	a0,s1
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	078080e7          	jalr	120(ra) # 800036fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000468e:	2a05                	addiw	s4,s4,1
    80004690:	0a91                	addi	s5,s5,4
    80004692:	02c9a783          	lw	a5,44(s3)
    80004696:	04fa5963          	bge	s4,a5,800046e8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000469a:	0189a583          	lw	a1,24(s3)
    8000469e:	014585bb          	addw	a1,a1,s4
    800046a2:	2585                	addiw	a1,a1,1
    800046a4:	0289a503          	lw	a0,40(s3)
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	f26080e7          	jalr	-218(ra) # 800035ce <bread>
    800046b0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046b2:	000aa583          	lw	a1,0(s5)
    800046b6:	0289a503          	lw	a0,40(s3)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	f14080e7          	jalr	-236(ra) # 800035ce <bread>
    800046c2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046c4:	40000613          	li	a2,1024
    800046c8:	05890593          	addi	a1,s2,88
    800046cc:	05850513          	addi	a0,a0,88
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	670080e7          	jalr	1648(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046d8:	8526                	mv	a0,s1
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	fe6080e7          	jalr	-26(ra) # 800036c0 <bwrite>
    if(recovering == 0)
    800046e2:	f80b1ce3          	bnez	s6,8000467a <install_trans+0x40>
    800046e6:	b769                	j	80004670 <install_trans+0x36>
}
    800046e8:	70e2                	ld	ra,56(sp)
    800046ea:	7442                	ld	s0,48(sp)
    800046ec:	74a2                	ld	s1,40(sp)
    800046ee:	7902                	ld	s2,32(sp)
    800046f0:	69e2                	ld	s3,24(sp)
    800046f2:	6a42                	ld	s4,16(sp)
    800046f4:	6aa2                	ld	s5,8(sp)
    800046f6:	6b02                	ld	s6,0(sp)
    800046f8:	6121                	addi	sp,sp,64
    800046fa:	8082                	ret
    800046fc:	8082                	ret

00000000800046fe <initlog>:
{
    800046fe:	7179                	addi	sp,sp,-48
    80004700:	f406                	sd	ra,40(sp)
    80004702:	f022                	sd	s0,32(sp)
    80004704:	ec26                	sd	s1,24(sp)
    80004706:	e84a                	sd	s2,16(sp)
    80004708:	e44e                	sd	s3,8(sp)
    8000470a:	1800                	addi	s0,sp,48
    8000470c:	892a                	mv	s2,a0
    8000470e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004710:	0001f497          	auipc	s1,0x1f
    80004714:	d7848493          	addi	s1,s1,-648 # 80023488 <log>
    80004718:	00004597          	auipc	a1,0x4
    8000471c:	11058593          	addi	a1,a1,272 # 80008828 <syscalls+0x1f0>
    80004720:	8526                	mv	a0,s1
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	432080e7          	jalr	1074(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000472a:	0149a583          	lw	a1,20(s3)
    8000472e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004730:	0109a783          	lw	a5,16(s3)
    80004734:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004736:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000473a:	854a                	mv	a0,s2
    8000473c:	fffff097          	auipc	ra,0xfffff
    80004740:	e92080e7          	jalr	-366(ra) # 800035ce <bread>
  log.lh.n = lh->n;
    80004744:	4d3c                	lw	a5,88(a0)
    80004746:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004748:	02f05563          	blez	a5,80004772 <initlog+0x74>
    8000474c:	05c50713          	addi	a4,a0,92
    80004750:	0001f697          	auipc	a3,0x1f
    80004754:	d6868693          	addi	a3,a3,-664 # 800234b8 <log+0x30>
    80004758:	37fd                	addiw	a5,a5,-1
    8000475a:	1782                	slli	a5,a5,0x20
    8000475c:	9381                	srli	a5,a5,0x20
    8000475e:	078a                	slli	a5,a5,0x2
    80004760:	06050613          	addi	a2,a0,96
    80004764:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004766:	4310                	lw	a2,0(a4)
    80004768:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000476a:	0711                	addi	a4,a4,4
    8000476c:	0691                	addi	a3,a3,4
    8000476e:	fef71ce3          	bne	a4,a5,80004766 <initlog+0x68>
  brelse(buf);
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	f8c080e7          	jalr	-116(ra) # 800036fe <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000477a:	4505                	li	a0,1
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	ebe080e7          	jalr	-322(ra) # 8000463a <install_trans>
  log.lh.n = 0;
    80004784:	0001f797          	auipc	a5,0x1f
    80004788:	d207a823          	sw	zero,-720(a5) # 800234b4 <log+0x2c>
  write_head(); // clear the log
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	e34080e7          	jalr	-460(ra) # 800045c0 <write_head>
}
    80004794:	70a2                	ld	ra,40(sp)
    80004796:	7402                	ld	s0,32(sp)
    80004798:	64e2                	ld	s1,24(sp)
    8000479a:	6942                	ld	s2,16(sp)
    8000479c:	69a2                	ld	s3,8(sp)
    8000479e:	6145                	addi	sp,sp,48
    800047a0:	8082                	ret

00000000800047a2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800047a2:	1101                	addi	sp,sp,-32
    800047a4:	ec06                	sd	ra,24(sp)
    800047a6:	e822                	sd	s0,16(sp)
    800047a8:	e426                	sd	s1,8(sp)
    800047aa:	e04a                	sd	s2,0(sp)
    800047ac:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800047ae:	0001f517          	auipc	a0,0x1f
    800047b2:	cda50513          	addi	a0,a0,-806 # 80023488 <log>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	42e080e7          	jalr	1070(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800047be:	0001f497          	auipc	s1,0x1f
    800047c2:	cca48493          	addi	s1,s1,-822 # 80023488 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047c6:	4979                	li	s2,30
    800047c8:	a039                	j	800047d6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047ca:	85a6                	mv	a1,s1
    800047cc:	8526                	mv	a0,s1
    800047ce:	ffffe097          	auipc	ra,0xffffe
    800047d2:	ab0080e7          	jalr	-1360(ra) # 8000227e <sleep>
    if(log.committing){
    800047d6:	50dc                	lw	a5,36(s1)
    800047d8:	fbed                	bnez	a5,800047ca <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047da:	509c                	lw	a5,32(s1)
    800047dc:	0017871b          	addiw	a4,a5,1
    800047e0:	0007069b          	sext.w	a3,a4
    800047e4:	0027179b          	slliw	a5,a4,0x2
    800047e8:	9fb9                	addw	a5,a5,a4
    800047ea:	0017979b          	slliw	a5,a5,0x1
    800047ee:	54d8                	lw	a4,44(s1)
    800047f0:	9fb9                	addw	a5,a5,a4
    800047f2:	00f95963          	bge	s2,a5,80004804 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047f6:	85a6                	mv	a1,s1
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffe097          	auipc	ra,0xffffe
    800047fe:	a84080e7          	jalr	-1404(ra) # 8000227e <sleep>
    80004802:	bfd1                	j	800047d6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004804:	0001f517          	auipc	a0,0x1f
    80004808:	c8450513          	addi	a0,a0,-892 # 80023488 <log>
    8000480c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	48a080e7          	jalr	1162(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004816:	60e2                	ld	ra,24(sp)
    80004818:	6442                	ld	s0,16(sp)
    8000481a:	64a2                	ld	s1,8(sp)
    8000481c:	6902                	ld	s2,0(sp)
    8000481e:	6105                	addi	sp,sp,32
    80004820:	8082                	ret

0000000080004822 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004822:	7139                	addi	sp,sp,-64
    80004824:	fc06                	sd	ra,56(sp)
    80004826:	f822                	sd	s0,48(sp)
    80004828:	f426                	sd	s1,40(sp)
    8000482a:	f04a                	sd	s2,32(sp)
    8000482c:	ec4e                	sd	s3,24(sp)
    8000482e:	e852                	sd	s4,16(sp)
    80004830:	e456                	sd	s5,8(sp)
    80004832:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004834:	0001f497          	auipc	s1,0x1f
    80004838:	c5448493          	addi	s1,s1,-940 # 80023488 <log>
    8000483c:	8526                	mv	a0,s1
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	3a6080e7          	jalr	934(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    80004846:	509c                	lw	a5,32(s1)
    80004848:	37fd                	addiw	a5,a5,-1
    8000484a:	0007891b          	sext.w	s2,a5
    8000484e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004850:	50dc                	lw	a5,36(s1)
    80004852:	efb9                	bnez	a5,800048b0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004854:	06091663          	bnez	s2,800048c0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004858:	0001f497          	auipc	s1,0x1f
    8000485c:	c3048493          	addi	s1,s1,-976 # 80023488 <log>
    80004860:	4785                	li	a5,1
    80004862:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004864:	8526                	mv	a0,s1
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	432080e7          	jalr	1074(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000486e:	54dc                	lw	a5,44(s1)
    80004870:	06f04763          	bgtz	a5,800048de <end_op+0xbc>
    acquire(&log.lock);
    80004874:	0001f497          	auipc	s1,0x1f
    80004878:	c1448493          	addi	s1,s1,-1004 # 80023488 <log>
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	366080e7          	jalr	870(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004886:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000488a:	8526                	mv	a0,s1
    8000488c:	ffffe097          	auipc	ra,0xffffe
    80004890:	b7e080e7          	jalr	-1154(ra) # 8000240a <wakeup>
    release(&log.lock);
    80004894:	8526                	mv	a0,s1
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	402080e7          	jalr	1026(ra) # 80000c98 <release>
}
    8000489e:	70e2                	ld	ra,56(sp)
    800048a0:	7442                	ld	s0,48(sp)
    800048a2:	74a2                	ld	s1,40(sp)
    800048a4:	7902                	ld	s2,32(sp)
    800048a6:	69e2                	ld	s3,24(sp)
    800048a8:	6a42                	ld	s4,16(sp)
    800048aa:	6aa2                	ld	s5,8(sp)
    800048ac:	6121                	addi	sp,sp,64
    800048ae:	8082                	ret
    panic("log.committing");
    800048b0:	00004517          	auipc	a0,0x4
    800048b4:	f8050513          	addi	a0,a0,-128 # 80008830 <syscalls+0x1f8>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	c86080e7          	jalr	-890(ra) # 8000053e <panic>
    wakeup(&log);
    800048c0:	0001f497          	auipc	s1,0x1f
    800048c4:	bc848493          	addi	s1,s1,-1080 # 80023488 <log>
    800048c8:	8526                	mv	a0,s1
    800048ca:	ffffe097          	auipc	ra,0xffffe
    800048ce:	b40080e7          	jalr	-1216(ra) # 8000240a <wakeup>
  release(&log.lock);
    800048d2:	8526                	mv	a0,s1
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	3c4080e7          	jalr	964(ra) # 80000c98 <release>
  if(do_commit){
    800048dc:	b7c9                	j	8000489e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048de:	0001fa97          	auipc	s5,0x1f
    800048e2:	bdaa8a93          	addi	s5,s5,-1062 # 800234b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048e6:	0001fa17          	auipc	s4,0x1f
    800048ea:	ba2a0a13          	addi	s4,s4,-1118 # 80023488 <log>
    800048ee:	018a2583          	lw	a1,24(s4)
    800048f2:	012585bb          	addw	a1,a1,s2
    800048f6:	2585                	addiw	a1,a1,1
    800048f8:	028a2503          	lw	a0,40(s4)
    800048fc:	fffff097          	auipc	ra,0xfffff
    80004900:	cd2080e7          	jalr	-814(ra) # 800035ce <bread>
    80004904:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004906:	000aa583          	lw	a1,0(s5)
    8000490a:	028a2503          	lw	a0,40(s4)
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	cc0080e7          	jalr	-832(ra) # 800035ce <bread>
    80004916:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004918:	40000613          	li	a2,1024
    8000491c:	05850593          	addi	a1,a0,88
    80004920:	05848513          	addi	a0,s1,88
    80004924:	ffffc097          	auipc	ra,0xffffc
    80004928:	41c080e7          	jalr	1052(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    8000492c:	8526                	mv	a0,s1
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	d92080e7          	jalr	-622(ra) # 800036c0 <bwrite>
    brelse(from);
    80004936:	854e                	mv	a0,s3
    80004938:	fffff097          	auipc	ra,0xfffff
    8000493c:	dc6080e7          	jalr	-570(ra) # 800036fe <brelse>
    brelse(to);
    80004940:	8526                	mv	a0,s1
    80004942:	fffff097          	auipc	ra,0xfffff
    80004946:	dbc080e7          	jalr	-580(ra) # 800036fe <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000494a:	2905                	addiw	s2,s2,1
    8000494c:	0a91                	addi	s5,s5,4
    8000494e:	02ca2783          	lw	a5,44(s4)
    80004952:	f8f94ee3          	blt	s2,a5,800048ee <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004956:	00000097          	auipc	ra,0x0
    8000495a:	c6a080e7          	jalr	-918(ra) # 800045c0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000495e:	4501                	li	a0,0
    80004960:	00000097          	auipc	ra,0x0
    80004964:	cda080e7          	jalr	-806(ra) # 8000463a <install_trans>
    log.lh.n = 0;
    80004968:	0001f797          	auipc	a5,0x1f
    8000496c:	b407a623          	sw	zero,-1204(a5) # 800234b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004970:	00000097          	auipc	ra,0x0
    80004974:	c50080e7          	jalr	-944(ra) # 800045c0 <write_head>
    80004978:	bdf5                	j	80004874 <end_op+0x52>

000000008000497a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000497a:	1101                	addi	sp,sp,-32
    8000497c:	ec06                	sd	ra,24(sp)
    8000497e:	e822                	sd	s0,16(sp)
    80004980:	e426                	sd	s1,8(sp)
    80004982:	e04a                	sd	s2,0(sp)
    80004984:	1000                	addi	s0,sp,32
    80004986:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004988:	0001f917          	auipc	s2,0x1f
    8000498c:	b0090913          	addi	s2,s2,-1280 # 80023488 <log>
    80004990:	854a                	mv	a0,s2
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	252080e7          	jalr	594(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000499a:	02c92603          	lw	a2,44(s2)
    8000499e:	47f5                	li	a5,29
    800049a0:	06c7c563          	blt	a5,a2,80004a0a <log_write+0x90>
    800049a4:	0001f797          	auipc	a5,0x1f
    800049a8:	b007a783          	lw	a5,-1280(a5) # 800234a4 <log+0x1c>
    800049ac:	37fd                	addiw	a5,a5,-1
    800049ae:	04f65e63          	bge	a2,a5,80004a0a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800049b2:	0001f797          	auipc	a5,0x1f
    800049b6:	af67a783          	lw	a5,-1290(a5) # 800234a8 <log+0x20>
    800049ba:	06f05063          	blez	a5,80004a1a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049be:	4781                	li	a5,0
    800049c0:	06c05563          	blez	a2,80004a2a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049c4:	44cc                	lw	a1,12(s1)
    800049c6:	0001f717          	auipc	a4,0x1f
    800049ca:	af270713          	addi	a4,a4,-1294 # 800234b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049ce:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049d0:	4314                	lw	a3,0(a4)
    800049d2:	04b68c63          	beq	a3,a1,80004a2a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049d6:	2785                	addiw	a5,a5,1
    800049d8:	0711                	addi	a4,a4,4
    800049da:	fef61be3          	bne	a2,a5,800049d0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049de:	0621                	addi	a2,a2,8
    800049e0:	060a                	slli	a2,a2,0x2
    800049e2:	0001f797          	auipc	a5,0x1f
    800049e6:	aa678793          	addi	a5,a5,-1370 # 80023488 <log>
    800049ea:	963e                	add	a2,a2,a5
    800049ec:	44dc                	lw	a5,12(s1)
    800049ee:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049f0:	8526                	mv	a0,s1
    800049f2:	fffff097          	auipc	ra,0xfffff
    800049f6:	daa080e7          	jalr	-598(ra) # 8000379c <bpin>
    log.lh.n++;
    800049fa:	0001f717          	auipc	a4,0x1f
    800049fe:	a8e70713          	addi	a4,a4,-1394 # 80023488 <log>
    80004a02:	575c                	lw	a5,44(a4)
    80004a04:	2785                	addiw	a5,a5,1
    80004a06:	d75c                	sw	a5,44(a4)
    80004a08:	a835                	j	80004a44 <log_write+0xca>
    panic("too big a transaction");
    80004a0a:	00004517          	auipc	a0,0x4
    80004a0e:	e3650513          	addi	a0,a0,-458 # 80008840 <syscalls+0x208>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004a1a:	00004517          	auipc	a0,0x4
    80004a1e:	e3e50513          	addi	a0,a0,-450 # 80008858 <syscalls+0x220>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	b1c080e7          	jalr	-1252(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a2a:	00878713          	addi	a4,a5,8
    80004a2e:	00271693          	slli	a3,a4,0x2
    80004a32:	0001f717          	auipc	a4,0x1f
    80004a36:	a5670713          	addi	a4,a4,-1450 # 80023488 <log>
    80004a3a:	9736                	add	a4,a4,a3
    80004a3c:	44d4                	lw	a3,12(s1)
    80004a3e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a40:	faf608e3          	beq	a2,a5,800049f0 <log_write+0x76>
  }
  release(&log.lock);
    80004a44:	0001f517          	auipc	a0,0x1f
    80004a48:	a4450513          	addi	a0,a0,-1468 # 80023488 <log>
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	24c080e7          	jalr	588(ra) # 80000c98 <release>
}
    80004a54:	60e2                	ld	ra,24(sp)
    80004a56:	6442                	ld	s0,16(sp)
    80004a58:	64a2                	ld	s1,8(sp)
    80004a5a:	6902                	ld	s2,0(sp)
    80004a5c:	6105                	addi	sp,sp,32
    80004a5e:	8082                	ret

0000000080004a60 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a60:	1101                	addi	sp,sp,-32
    80004a62:	ec06                	sd	ra,24(sp)
    80004a64:	e822                	sd	s0,16(sp)
    80004a66:	e426                	sd	s1,8(sp)
    80004a68:	e04a                	sd	s2,0(sp)
    80004a6a:	1000                	addi	s0,sp,32
    80004a6c:	84aa                	mv	s1,a0
    80004a6e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a70:	00004597          	auipc	a1,0x4
    80004a74:	e0858593          	addi	a1,a1,-504 # 80008878 <syscalls+0x240>
    80004a78:	0521                	addi	a0,a0,8
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	0da080e7          	jalr	218(ra) # 80000b54 <initlock>
  lk->name = name;
    80004a82:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a86:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a8a:	0204a423          	sw	zero,40(s1)
}
    80004a8e:	60e2                	ld	ra,24(sp)
    80004a90:	6442                	ld	s0,16(sp)
    80004a92:	64a2                	ld	s1,8(sp)
    80004a94:	6902                	ld	s2,0(sp)
    80004a96:	6105                	addi	sp,sp,32
    80004a98:	8082                	ret

0000000080004a9a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a9a:	1101                	addi	sp,sp,-32
    80004a9c:	ec06                	sd	ra,24(sp)
    80004a9e:	e822                	sd	s0,16(sp)
    80004aa0:	e426                	sd	s1,8(sp)
    80004aa2:	e04a                	sd	s2,0(sp)
    80004aa4:	1000                	addi	s0,sp,32
    80004aa6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004aa8:	00850913          	addi	s2,a0,8
    80004aac:	854a                	mv	a0,s2
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	136080e7          	jalr	310(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004ab6:	409c                	lw	a5,0(s1)
    80004ab8:	cb89                	beqz	a5,80004aca <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004aba:	85ca                	mv	a1,s2
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	7c0080e7          	jalr	1984(ra) # 8000227e <sleep>
  while (lk->locked) {
    80004ac6:	409c                	lw	a5,0(s1)
    80004ac8:	fbed                	bnez	a5,80004aba <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004aca:	4785                	li	a5,1
    80004acc:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	070080e7          	jalr	112(ra) # 80001b3e <myproc>
    80004ad6:	591c                	lw	a5,48(a0)
    80004ad8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ada:	854a                	mv	a0,s2
    80004adc:	ffffc097          	auipc	ra,0xffffc
    80004ae0:	1bc080e7          	jalr	444(ra) # 80000c98 <release>
}
    80004ae4:	60e2                	ld	ra,24(sp)
    80004ae6:	6442                	ld	s0,16(sp)
    80004ae8:	64a2                	ld	s1,8(sp)
    80004aea:	6902                	ld	s2,0(sp)
    80004aec:	6105                	addi	sp,sp,32
    80004aee:	8082                	ret

0000000080004af0 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004af0:	1101                	addi	sp,sp,-32
    80004af2:	ec06                	sd	ra,24(sp)
    80004af4:	e822                	sd	s0,16(sp)
    80004af6:	e426                	sd	s1,8(sp)
    80004af8:	e04a                	sd	s2,0(sp)
    80004afa:	1000                	addi	s0,sp,32
    80004afc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004afe:	00850913          	addi	s2,a0,8
    80004b02:	854a                	mv	a0,s2
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	0e0080e7          	jalr	224(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004b0c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b10:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b14:	8526                	mv	a0,s1
    80004b16:	ffffe097          	auipc	ra,0xffffe
    80004b1a:	8f4080e7          	jalr	-1804(ra) # 8000240a <wakeup>
  release(&lk->lk);
    80004b1e:	854a                	mv	a0,s2
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	178080e7          	jalr	376(ra) # 80000c98 <release>
}
    80004b28:	60e2                	ld	ra,24(sp)
    80004b2a:	6442                	ld	s0,16(sp)
    80004b2c:	64a2                	ld	s1,8(sp)
    80004b2e:	6902                	ld	s2,0(sp)
    80004b30:	6105                	addi	sp,sp,32
    80004b32:	8082                	ret

0000000080004b34 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b34:	7179                	addi	sp,sp,-48
    80004b36:	f406                	sd	ra,40(sp)
    80004b38:	f022                	sd	s0,32(sp)
    80004b3a:	ec26                	sd	s1,24(sp)
    80004b3c:	e84a                	sd	s2,16(sp)
    80004b3e:	e44e                	sd	s3,8(sp)
    80004b40:	1800                	addi	s0,sp,48
    80004b42:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b44:	00850913          	addi	s2,a0,8
    80004b48:	854a                	mv	a0,s2
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	09a080e7          	jalr	154(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b52:	409c                	lw	a5,0(s1)
    80004b54:	ef99                	bnez	a5,80004b72 <holdingsleep+0x3e>
    80004b56:	4481                	li	s1,0
  release(&lk->lk);
    80004b58:	854a                	mv	a0,s2
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	13e080e7          	jalr	318(ra) # 80000c98 <release>
  return r;
}
    80004b62:	8526                	mv	a0,s1
    80004b64:	70a2                	ld	ra,40(sp)
    80004b66:	7402                	ld	s0,32(sp)
    80004b68:	64e2                	ld	s1,24(sp)
    80004b6a:	6942                	ld	s2,16(sp)
    80004b6c:	69a2                	ld	s3,8(sp)
    80004b6e:	6145                	addi	sp,sp,48
    80004b70:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b72:	0284a983          	lw	s3,40(s1)
    80004b76:	ffffd097          	auipc	ra,0xffffd
    80004b7a:	fc8080e7          	jalr	-56(ra) # 80001b3e <myproc>
    80004b7e:	5904                	lw	s1,48(a0)
    80004b80:	413484b3          	sub	s1,s1,s3
    80004b84:	0014b493          	seqz	s1,s1
    80004b88:	bfc1                	j	80004b58 <holdingsleep+0x24>

0000000080004b8a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b8a:	1141                	addi	sp,sp,-16
    80004b8c:	e406                	sd	ra,8(sp)
    80004b8e:	e022                	sd	s0,0(sp)
    80004b90:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b92:	00004597          	auipc	a1,0x4
    80004b96:	cf658593          	addi	a1,a1,-778 # 80008888 <syscalls+0x250>
    80004b9a:	0001f517          	auipc	a0,0x1f
    80004b9e:	a3650513          	addi	a0,a0,-1482 # 800235d0 <ftable>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	fb2080e7          	jalr	-78(ra) # 80000b54 <initlock>
}
    80004baa:	60a2                	ld	ra,8(sp)
    80004bac:	6402                	ld	s0,0(sp)
    80004bae:	0141                	addi	sp,sp,16
    80004bb0:	8082                	ret

0000000080004bb2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004bb2:	1101                	addi	sp,sp,-32
    80004bb4:	ec06                	sd	ra,24(sp)
    80004bb6:	e822                	sd	s0,16(sp)
    80004bb8:	e426                	sd	s1,8(sp)
    80004bba:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004bbc:	0001f517          	auipc	a0,0x1f
    80004bc0:	a1450513          	addi	a0,a0,-1516 # 800235d0 <ftable>
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	020080e7          	jalr	32(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bcc:	0001f497          	auipc	s1,0x1f
    80004bd0:	a1c48493          	addi	s1,s1,-1508 # 800235e8 <ftable+0x18>
    80004bd4:	00020717          	auipc	a4,0x20
    80004bd8:	9b470713          	addi	a4,a4,-1612 # 80024588 <ftable+0xfb8>
    if(f->ref == 0){
    80004bdc:	40dc                	lw	a5,4(s1)
    80004bde:	cf99                	beqz	a5,80004bfc <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004be0:	02848493          	addi	s1,s1,40
    80004be4:	fee49ce3          	bne	s1,a4,80004bdc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004be8:	0001f517          	auipc	a0,0x1f
    80004bec:	9e850513          	addi	a0,a0,-1560 # 800235d0 <ftable>
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	0a8080e7          	jalr	168(ra) # 80000c98 <release>
  return 0;
    80004bf8:	4481                	li	s1,0
    80004bfa:	a819                	j	80004c10 <filealloc+0x5e>
      f->ref = 1;
    80004bfc:	4785                	li	a5,1
    80004bfe:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c00:	0001f517          	auipc	a0,0x1f
    80004c04:	9d050513          	addi	a0,a0,-1584 # 800235d0 <ftable>
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	090080e7          	jalr	144(ra) # 80000c98 <release>
}
    80004c10:	8526                	mv	a0,s1
    80004c12:	60e2                	ld	ra,24(sp)
    80004c14:	6442                	ld	s0,16(sp)
    80004c16:	64a2                	ld	s1,8(sp)
    80004c18:	6105                	addi	sp,sp,32
    80004c1a:	8082                	ret

0000000080004c1c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c1c:	1101                	addi	sp,sp,-32
    80004c1e:	ec06                	sd	ra,24(sp)
    80004c20:	e822                	sd	s0,16(sp)
    80004c22:	e426                	sd	s1,8(sp)
    80004c24:	1000                	addi	s0,sp,32
    80004c26:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c28:	0001f517          	auipc	a0,0x1f
    80004c2c:	9a850513          	addi	a0,a0,-1624 # 800235d0 <ftable>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	fb4080e7          	jalr	-76(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c38:	40dc                	lw	a5,4(s1)
    80004c3a:	02f05263          	blez	a5,80004c5e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c3e:	2785                	addiw	a5,a5,1
    80004c40:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c42:	0001f517          	auipc	a0,0x1f
    80004c46:	98e50513          	addi	a0,a0,-1650 # 800235d0 <ftable>
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	04e080e7          	jalr	78(ra) # 80000c98 <release>
  return f;
}
    80004c52:	8526                	mv	a0,s1
    80004c54:	60e2                	ld	ra,24(sp)
    80004c56:	6442                	ld	s0,16(sp)
    80004c58:	64a2                	ld	s1,8(sp)
    80004c5a:	6105                	addi	sp,sp,32
    80004c5c:	8082                	ret
    panic("filedup");
    80004c5e:	00004517          	auipc	a0,0x4
    80004c62:	c3250513          	addi	a0,a0,-974 # 80008890 <syscalls+0x258>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8d8080e7          	jalr	-1832(ra) # 8000053e <panic>

0000000080004c6e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c6e:	7139                	addi	sp,sp,-64
    80004c70:	fc06                	sd	ra,56(sp)
    80004c72:	f822                	sd	s0,48(sp)
    80004c74:	f426                	sd	s1,40(sp)
    80004c76:	f04a                	sd	s2,32(sp)
    80004c78:	ec4e                	sd	s3,24(sp)
    80004c7a:	e852                	sd	s4,16(sp)
    80004c7c:	e456                	sd	s5,8(sp)
    80004c7e:	0080                	addi	s0,sp,64
    80004c80:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c82:	0001f517          	auipc	a0,0x1f
    80004c86:	94e50513          	addi	a0,a0,-1714 # 800235d0 <ftable>
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	f5a080e7          	jalr	-166(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004c92:	40dc                	lw	a5,4(s1)
    80004c94:	06f05163          	blez	a5,80004cf6 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c98:	37fd                	addiw	a5,a5,-1
    80004c9a:	0007871b          	sext.w	a4,a5
    80004c9e:	c0dc                	sw	a5,4(s1)
    80004ca0:	06e04363          	bgtz	a4,80004d06 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ca4:	0004a903          	lw	s2,0(s1)
    80004ca8:	0094ca83          	lbu	s5,9(s1)
    80004cac:	0104ba03          	ld	s4,16(s1)
    80004cb0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004cb4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004cb8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004cbc:	0001f517          	auipc	a0,0x1f
    80004cc0:	91450513          	addi	a0,a0,-1772 # 800235d0 <ftable>
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	fd4080e7          	jalr	-44(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004ccc:	4785                	li	a5,1
    80004cce:	04f90d63          	beq	s2,a5,80004d28 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cd2:	3979                	addiw	s2,s2,-2
    80004cd4:	4785                	li	a5,1
    80004cd6:	0527e063          	bltu	a5,s2,80004d16 <fileclose+0xa8>
    begin_op();
    80004cda:	00000097          	auipc	ra,0x0
    80004cde:	ac8080e7          	jalr	-1336(ra) # 800047a2 <begin_op>
    iput(ff.ip);
    80004ce2:	854e                	mv	a0,s3
    80004ce4:	fffff097          	auipc	ra,0xfffff
    80004ce8:	2a6080e7          	jalr	678(ra) # 80003f8a <iput>
    end_op();
    80004cec:	00000097          	auipc	ra,0x0
    80004cf0:	b36080e7          	jalr	-1226(ra) # 80004822 <end_op>
    80004cf4:	a00d                	j	80004d16 <fileclose+0xa8>
    panic("fileclose");
    80004cf6:	00004517          	auipc	a0,0x4
    80004cfa:	ba250513          	addi	a0,a0,-1118 # 80008898 <syscalls+0x260>
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	840080e7          	jalr	-1984(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004d06:	0001f517          	auipc	a0,0x1f
    80004d0a:	8ca50513          	addi	a0,a0,-1846 # 800235d0 <ftable>
    80004d0e:	ffffc097          	auipc	ra,0xffffc
    80004d12:	f8a080e7          	jalr	-118(ra) # 80000c98 <release>
  }
}
    80004d16:	70e2                	ld	ra,56(sp)
    80004d18:	7442                	ld	s0,48(sp)
    80004d1a:	74a2                	ld	s1,40(sp)
    80004d1c:	7902                	ld	s2,32(sp)
    80004d1e:	69e2                	ld	s3,24(sp)
    80004d20:	6a42                	ld	s4,16(sp)
    80004d22:	6aa2                	ld	s5,8(sp)
    80004d24:	6121                	addi	sp,sp,64
    80004d26:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d28:	85d6                	mv	a1,s5
    80004d2a:	8552                	mv	a0,s4
    80004d2c:	00000097          	auipc	ra,0x0
    80004d30:	34c080e7          	jalr	844(ra) # 80005078 <pipeclose>
    80004d34:	b7cd                	j	80004d16 <fileclose+0xa8>

0000000080004d36 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d36:	715d                	addi	sp,sp,-80
    80004d38:	e486                	sd	ra,72(sp)
    80004d3a:	e0a2                	sd	s0,64(sp)
    80004d3c:	fc26                	sd	s1,56(sp)
    80004d3e:	f84a                	sd	s2,48(sp)
    80004d40:	f44e                	sd	s3,40(sp)
    80004d42:	0880                	addi	s0,sp,80
    80004d44:	84aa                	mv	s1,a0
    80004d46:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	df6080e7          	jalr	-522(ra) # 80001b3e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d50:	409c                	lw	a5,0(s1)
    80004d52:	37f9                	addiw	a5,a5,-2
    80004d54:	4705                	li	a4,1
    80004d56:	04f76763          	bltu	a4,a5,80004da4 <filestat+0x6e>
    80004d5a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d5c:	6c88                	ld	a0,24(s1)
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	072080e7          	jalr	114(ra) # 80003dd0 <ilock>
    stati(f->ip, &st);
    80004d66:	fb840593          	addi	a1,s0,-72
    80004d6a:	6c88                	ld	a0,24(s1)
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	2ee080e7          	jalr	750(ra) # 8000405a <stati>
    iunlock(f->ip);
    80004d74:	6c88                	ld	a0,24(s1)
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	11c080e7          	jalr	284(ra) # 80003e92 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d7e:	46e1                	li	a3,24
    80004d80:	fb840613          	addi	a2,s0,-72
    80004d84:	85ce                	mv	a1,s3
    80004d86:	05093503          	ld	a0,80(s2)
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	8e8080e7          	jalr	-1816(ra) # 80001672 <copyout>
    80004d92:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d96:	60a6                	ld	ra,72(sp)
    80004d98:	6406                	ld	s0,64(sp)
    80004d9a:	74e2                	ld	s1,56(sp)
    80004d9c:	7942                	ld	s2,48(sp)
    80004d9e:	79a2                	ld	s3,40(sp)
    80004da0:	6161                	addi	sp,sp,80
    80004da2:	8082                	ret
  return -1;
    80004da4:	557d                	li	a0,-1
    80004da6:	bfc5                	j	80004d96 <filestat+0x60>

0000000080004da8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004da8:	7179                	addi	sp,sp,-48
    80004daa:	f406                	sd	ra,40(sp)
    80004dac:	f022                	sd	s0,32(sp)
    80004dae:	ec26                	sd	s1,24(sp)
    80004db0:	e84a                	sd	s2,16(sp)
    80004db2:	e44e                	sd	s3,8(sp)
    80004db4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004db6:	00854783          	lbu	a5,8(a0)
    80004dba:	c3d5                	beqz	a5,80004e5e <fileread+0xb6>
    80004dbc:	84aa                	mv	s1,a0
    80004dbe:	89ae                	mv	s3,a1
    80004dc0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dc2:	411c                	lw	a5,0(a0)
    80004dc4:	4705                	li	a4,1
    80004dc6:	04e78963          	beq	a5,a4,80004e18 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dca:	470d                	li	a4,3
    80004dcc:	04e78d63          	beq	a5,a4,80004e26 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dd0:	4709                	li	a4,2
    80004dd2:	06e79e63          	bne	a5,a4,80004e4e <fileread+0xa6>
    ilock(f->ip);
    80004dd6:	6d08                	ld	a0,24(a0)
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	ff8080e7          	jalr	-8(ra) # 80003dd0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004de0:	874a                	mv	a4,s2
    80004de2:	5094                	lw	a3,32(s1)
    80004de4:	864e                	mv	a2,s3
    80004de6:	4585                	li	a1,1
    80004de8:	6c88                	ld	a0,24(s1)
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	29a080e7          	jalr	666(ra) # 80004084 <readi>
    80004df2:	892a                	mv	s2,a0
    80004df4:	00a05563          	blez	a0,80004dfe <fileread+0x56>
      f->off += r;
    80004df8:	509c                	lw	a5,32(s1)
    80004dfa:	9fa9                	addw	a5,a5,a0
    80004dfc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004dfe:	6c88                	ld	a0,24(s1)
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	092080e7          	jalr	146(ra) # 80003e92 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e08:	854a                	mv	a0,s2
    80004e0a:	70a2                	ld	ra,40(sp)
    80004e0c:	7402                	ld	s0,32(sp)
    80004e0e:	64e2                	ld	s1,24(sp)
    80004e10:	6942                	ld	s2,16(sp)
    80004e12:	69a2                	ld	s3,8(sp)
    80004e14:	6145                	addi	sp,sp,48
    80004e16:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e18:	6908                	ld	a0,16(a0)
    80004e1a:	00000097          	auipc	ra,0x0
    80004e1e:	3c8080e7          	jalr	968(ra) # 800051e2 <piperead>
    80004e22:	892a                	mv	s2,a0
    80004e24:	b7d5                	j	80004e08 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e26:	02451783          	lh	a5,36(a0)
    80004e2a:	03079693          	slli	a3,a5,0x30
    80004e2e:	92c1                	srli	a3,a3,0x30
    80004e30:	4725                	li	a4,9
    80004e32:	02d76863          	bltu	a4,a3,80004e62 <fileread+0xba>
    80004e36:	0792                	slli	a5,a5,0x4
    80004e38:	0001e717          	auipc	a4,0x1e
    80004e3c:	6f870713          	addi	a4,a4,1784 # 80023530 <devsw>
    80004e40:	97ba                	add	a5,a5,a4
    80004e42:	639c                	ld	a5,0(a5)
    80004e44:	c38d                	beqz	a5,80004e66 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e46:	4505                	li	a0,1
    80004e48:	9782                	jalr	a5
    80004e4a:	892a                	mv	s2,a0
    80004e4c:	bf75                	j	80004e08 <fileread+0x60>
    panic("fileread");
    80004e4e:	00004517          	auipc	a0,0x4
    80004e52:	a5a50513          	addi	a0,a0,-1446 # 800088a8 <syscalls+0x270>
    80004e56:	ffffb097          	auipc	ra,0xffffb
    80004e5a:	6e8080e7          	jalr	1768(ra) # 8000053e <panic>
    return -1;
    80004e5e:	597d                	li	s2,-1
    80004e60:	b765                	j	80004e08 <fileread+0x60>
      return -1;
    80004e62:	597d                	li	s2,-1
    80004e64:	b755                	j	80004e08 <fileread+0x60>
    80004e66:	597d                	li	s2,-1
    80004e68:	b745                	j	80004e08 <fileread+0x60>

0000000080004e6a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e6a:	715d                	addi	sp,sp,-80
    80004e6c:	e486                	sd	ra,72(sp)
    80004e6e:	e0a2                	sd	s0,64(sp)
    80004e70:	fc26                	sd	s1,56(sp)
    80004e72:	f84a                	sd	s2,48(sp)
    80004e74:	f44e                	sd	s3,40(sp)
    80004e76:	f052                	sd	s4,32(sp)
    80004e78:	ec56                	sd	s5,24(sp)
    80004e7a:	e85a                	sd	s6,16(sp)
    80004e7c:	e45e                	sd	s7,8(sp)
    80004e7e:	e062                	sd	s8,0(sp)
    80004e80:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e82:	00954783          	lbu	a5,9(a0)
    80004e86:	10078663          	beqz	a5,80004f92 <filewrite+0x128>
    80004e8a:	892a                	mv	s2,a0
    80004e8c:	8aae                	mv	s5,a1
    80004e8e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e90:	411c                	lw	a5,0(a0)
    80004e92:	4705                	li	a4,1
    80004e94:	02e78263          	beq	a5,a4,80004eb8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e98:	470d                	li	a4,3
    80004e9a:	02e78663          	beq	a5,a4,80004ec6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e9e:	4709                	li	a4,2
    80004ea0:	0ee79163          	bne	a5,a4,80004f82 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ea4:	0ac05d63          	blez	a2,80004f5e <filewrite+0xf4>
    int i = 0;
    80004ea8:	4981                	li	s3,0
    80004eaa:	6b05                	lui	s6,0x1
    80004eac:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004eb0:	6b85                	lui	s7,0x1
    80004eb2:	c00b8b9b          	addiw	s7,s7,-1024
    80004eb6:	a861                	j	80004f4e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004eb8:	6908                	ld	a0,16(a0)
    80004eba:	00000097          	auipc	ra,0x0
    80004ebe:	22e080e7          	jalr	558(ra) # 800050e8 <pipewrite>
    80004ec2:	8a2a                	mv	s4,a0
    80004ec4:	a045                	j	80004f64 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ec6:	02451783          	lh	a5,36(a0)
    80004eca:	03079693          	slli	a3,a5,0x30
    80004ece:	92c1                	srli	a3,a3,0x30
    80004ed0:	4725                	li	a4,9
    80004ed2:	0cd76263          	bltu	a4,a3,80004f96 <filewrite+0x12c>
    80004ed6:	0792                	slli	a5,a5,0x4
    80004ed8:	0001e717          	auipc	a4,0x1e
    80004edc:	65870713          	addi	a4,a4,1624 # 80023530 <devsw>
    80004ee0:	97ba                	add	a5,a5,a4
    80004ee2:	679c                	ld	a5,8(a5)
    80004ee4:	cbdd                	beqz	a5,80004f9a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ee6:	4505                	li	a0,1
    80004ee8:	9782                	jalr	a5
    80004eea:	8a2a                	mv	s4,a0
    80004eec:	a8a5                	j	80004f64 <filewrite+0xfa>
    80004eee:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ef2:	00000097          	auipc	ra,0x0
    80004ef6:	8b0080e7          	jalr	-1872(ra) # 800047a2 <begin_op>
      ilock(f->ip);
    80004efa:	01893503          	ld	a0,24(s2)
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	ed2080e7          	jalr	-302(ra) # 80003dd0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f06:	8762                	mv	a4,s8
    80004f08:	02092683          	lw	a3,32(s2)
    80004f0c:	01598633          	add	a2,s3,s5
    80004f10:	4585                	li	a1,1
    80004f12:	01893503          	ld	a0,24(s2)
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	266080e7          	jalr	614(ra) # 8000417c <writei>
    80004f1e:	84aa                	mv	s1,a0
    80004f20:	00a05763          	blez	a0,80004f2e <filewrite+0xc4>
        f->off += r;
    80004f24:	02092783          	lw	a5,32(s2)
    80004f28:	9fa9                	addw	a5,a5,a0
    80004f2a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f2e:	01893503          	ld	a0,24(s2)
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	f60080e7          	jalr	-160(ra) # 80003e92 <iunlock>
      end_op();
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	8e8080e7          	jalr	-1816(ra) # 80004822 <end_op>

      if(r != n1){
    80004f42:	009c1f63          	bne	s8,s1,80004f60 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f46:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f4a:	0149db63          	bge	s3,s4,80004f60 <filewrite+0xf6>
      int n1 = n - i;
    80004f4e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f52:	84be                	mv	s1,a5
    80004f54:	2781                	sext.w	a5,a5
    80004f56:	f8fb5ce3          	bge	s6,a5,80004eee <filewrite+0x84>
    80004f5a:	84de                	mv	s1,s7
    80004f5c:	bf49                	j	80004eee <filewrite+0x84>
    int i = 0;
    80004f5e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f60:	013a1f63          	bne	s4,s3,80004f7e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f64:	8552                	mv	a0,s4
    80004f66:	60a6                	ld	ra,72(sp)
    80004f68:	6406                	ld	s0,64(sp)
    80004f6a:	74e2                	ld	s1,56(sp)
    80004f6c:	7942                	ld	s2,48(sp)
    80004f6e:	79a2                	ld	s3,40(sp)
    80004f70:	7a02                	ld	s4,32(sp)
    80004f72:	6ae2                	ld	s5,24(sp)
    80004f74:	6b42                	ld	s6,16(sp)
    80004f76:	6ba2                	ld	s7,8(sp)
    80004f78:	6c02                	ld	s8,0(sp)
    80004f7a:	6161                	addi	sp,sp,80
    80004f7c:	8082                	ret
    ret = (i == n ? n : -1);
    80004f7e:	5a7d                	li	s4,-1
    80004f80:	b7d5                	j	80004f64 <filewrite+0xfa>
    panic("filewrite");
    80004f82:	00004517          	auipc	a0,0x4
    80004f86:	93650513          	addi	a0,a0,-1738 # 800088b8 <syscalls+0x280>
    80004f8a:	ffffb097          	auipc	ra,0xffffb
    80004f8e:	5b4080e7          	jalr	1460(ra) # 8000053e <panic>
    return -1;
    80004f92:	5a7d                	li	s4,-1
    80004f94:	bfc1                	j	80004f64 <filewrite+0xfa>
      return -1;
    80004f96:	5a7d                	li	s4,-1
    80004f98:	b7f1                	j	80004f64 <filewrite+0xfa>
    80004f9a:	5a7d                	li	s4,-1
    80004f9c:	b7e1                	j	80004f64 <filewrite+0xfa>

0000000080004f9e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f9e:	7179                	addi	sp,sp,-48
    80004fa0:	f406                	sd	ra,40(sp)
    80004fa2:	f022                	sd	s0,32(sp)
    80004fa4:	ec26                	sd	s1,24(sp)
    80004fa6:	e84a                	sd	s2,16(sp)
    80004fa8:	e44e                	sd	s3,8(sp)
    80004faa:	e052                	sd	s4,0(sp)
    80004fac:	1800                	addi	s0,sp,48
    80004fae:	84aa                	mv	s1,a0
    80004fb0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004fb2:	0005b023          	sd	zero,0(a1)
    80004fb6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004fba:	00000097          	auipc	ra,0x0
    80004fbe:	bf8080e7          	jalr	-1032(ra) # 80004bb2 <filealloc>
    80004fc2:	e088                	sd	a0,0(s1)
    80004fc4:	c551                	beqz	a0,80005050 <pipealloc+0xb2>
    80004fc6:	00000097          	auipc	ra,0x0
    80004fca:	bec080e7          	jalr	-1044(ra) # 80004bb2 <filealloc>
    80004fce:	00aa3023          	sd	a0,0(s4)
    80004fd2:	c92d                	beqz	a0,80005044 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	b20080e7          	jalr	-1248(ra) # 80000af4 <kalloc>
    80004fdc:	892a                	mv	s2,a0
    80004fde:	c125                	beqz	a0,8000503e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fe0:	4985                	li	s3,1
    80004fe2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fe6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ff2:	00003597          	auipc	a1,0x3
    80004ff6:	58658593          	addi	a1,a1,1414 # 80008578 <states.1784+0x1b8>
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	b5a080e7          	jalr	-1190(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80005002:	609c                	ld	a5,0(s1)
    80005004:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005008:	609c                	ld	a5,0(s1)
    8000500a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000500e:	609c                	ld	a5,0(s1)
    80005010:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005014:	609c                	ld	a5,0(s1)
    80005016:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000501a:	000a3783          	ld	a5,0(s4)
    8000501e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005022:	000a3783          	ld	a5,0(s4)
    80005026:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000502a:	000a3783          	ld	a5,0(s4)
    8000502e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005032:	000a3783          	ld	a5,0(s4)
    80005036:	0127b823          	sd	s2,16(a5)
  return 0;
    8000503a:	4501                	li	a0,0
    8000503c:	a025                	j	80005064 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000503e:	6088                	ld	a0,0(s1)
    80005040:	e501                	bnez	a0,80005048 <pipealloc+0xaa>
    80005042:	a039                	j	80005050 <pipealloc+0xb2>
    80005044:	6088                	ld	a0,0(s1)
    80005046:	c51d                	beqz	a0,80005074 <pipealloc+0xd6>
    fileclose(*f0);
    80005048:	00000097          	auipc	ra,0x0
    8000504c:	c26080e7          	jalr	-986(ra) # 80004c6e <fileclose>
  if(*f1)
    80005050:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005054:	557d                	li	a0,-1
  if(*f1)
    80005056:	c799                	beqz	a5,80005064 <pipealloc+0xc6>
    fileclose(*f1);
    80005058:	853e                	mv	a0,a5
    8000505a:	00000097          	auipc	ra,0x0
    8000505e:	c14080e7          	jalr	-1004(ra) # 80004c6e <fileclose>
  return -1;
    80005062:	557d                	li	a0,-1
}
    80005064:	70a2                	ld	ra,40(sp)
    80005066:	7402                	ld	s0,32(sp)
    80005068:	64e2                	ld	s1,24(sp)
    8000506a:	6942                	ld	s2,16(sp)
    8000506c:	69a2                	ld	s3,8(sp)
    8000506e:	6a02                	ld	s4,0(sp)
    80005070:	6145                	addi	sp,sp,48
    80005072:	8082                	ret
  return -1;
    80005074:	557d                	li	a0,-1
    80005076:	b7fd                	j	80005064 <pipealloc+0xc6>

0000000080005078 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005078:	1101                	addi	sp,sp,-32
    8000507a:	ec06                	sd	ra,24(sp)
    8000507c:	e822                	sd	s0,16(sp)
    8000507e:	e426                	sd	s1,8(sp)
    80005080:	e04a                	sd	s2,0(sp)
    80005082:	1000                	addi	s0,sp,32
    80005084:	84aa                	mv	s1,a0
    80005086:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005088:	ffffc097          	auipc	ra,0xffffc
    8000508c:	b5c080e7          	jalr	-1188(ra) # 80000be4 <acquire>
  if(writable){
    80005090:	02090d63          	beqz	s2,800050ca <pipeclose+0x52>
    pi->writeopen = 0;
    80005094:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005098:	21848513          	addi	a0,s1,536
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	36e080e7          	jalr	878(ra) # 8000240a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800050a4:	2204b783          	ld	a5,544(s1)
    800050a8:	eb95                	bnez	a5,800050dc <pipeclose+0x64>
    release(&pi->lock);
    800050aa:	8526                	mv	a0,s1
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	bec080e7          	jalr	-1044(ra) # 80000c98 <release>
    kfree((char*)pi);
    800050b4:	8526                	mv	a0,s1
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	942080e7          	jalr	-1726(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    800050be:	60e2                	ld	ra,24(sp)
    800050c0:	6442                	ld	s0,16(sp)
    800050c2:	64a2                	ld	s1,8(sp)
    800050c4:	6902                	ld	s2,0(sp)
    800050c6:	6105                	addi	sp,sp,32
    800050c8:	8082                	ret
    pi->readopen = 0;
    800050ca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050ce:	21c48513          	addi	a0,s1,540
    800050d2:	ffffd097          	auipc	ra,0xffffd
    800050d6:	338080e7          	jalr	824(ra) # 8000240a <wakeup>
    800050da:	b7e9                	j	800050a4 <pipeclose+0x2c>
    release(&pi->lock);
    800050dc:	8526                	mv	a0,s1
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	bba080e7          	jalr	-1094(ra) # 80000c98 <release>
}
    800050e6:	bfe1                	j	800050be <pipeclose+0x46>

00000000800050e8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050e8:	7159                	addi	sp,sp,-112
    800050ea:	f486                	sd	ra,104(sp)
    800050ec:	f0a2                	sd	s0,96(sp)
    800050ee:	eca6                	sd	s1,88(sp)
    800050f0:	e8ca                	sd	s2,80(sp)
    800050f2:	e4ce                	sd	s3,72(sp)
    800050f4:	e0d2                	sd	s4,64(sp)
    800050f6:	fc56                	sd	s5,56(sp)
    800050f8:	f85a                	sd	s6,48(sp)
    800050fa:	f45e                	sd	s7,40(sp)
    800050fc:	f062                	sd	s8,32(sp)
    800050fe:	ec66                	sd	s9,24(sp)
    80005100:	1880                	addi	s0,sp,112
    80005102:	84aa                	mv	s1,a0
    80005104:	8aae                	mv	s5,a1
    80005106:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005108:	ffffd097          	auipc	ra,0xffffd
    8000510c:	a36080e7          	jalr	-1482(ra) # 80001b3e <myproc>
    80005110:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005112:	8526                	mv	a0,s1
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	ad0080e7          	jalr	-1328(ra) # 80000be4 <acquire>
  while(i < n){
    8000511c:	0d405163          	blez	s4,800051de <pipewrite+0xf6>
    80005120:	8ba6                	mv	s7,s1
  int i = 0;
    80005122:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005124:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005126:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000512a:	21c48c13          	addi	s8,s1,540
    8000512e:	a08d                	j	80005190 <pipewrite+0xa8>
      release(&pi->lock);
    80005130:	8526                	mv	a0,s1
    80005132:	ffffc097          	auipc	ra,0xffffc
    80005136:	b66080e7          	jalr	-1178(ra) # 80000c98 <release>
      return -1;
    8000513a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000513c:	854a                	mv	a0,s2
    8000513e:	70a6                	ld	ra,104(sp)
    80005140:	7406                	ld	s0,96(sp)
    80005142:	64e6                	ld	s1,88(sp)
    80005144:	6946                	ld	s2,80(sp)
    80005146:	69a6                	ld	s3,72(sp)
    80005148:	6a06                	ld	s4,64(sp)
    8000514a:	7ae2                	ld	s5,56(sp)
    8000514c:	7b42                	ld	s6,48(sp)
    8000514e:	7ba2                	ld	s7,40(sp)
    80005150:	7c02                	ld	s8,32(sp)
    80005152:	6ce2                	ld	s9,24(sp)
    80005154:	6165                	addi	sp,sp,112
    80005156:	8082                	ret
      wakeup(&pi->nread);
    80005158:	8566                	mv	a0,s9
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	2b0080e7          	jalr	688(ra) # 8000240a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005162:	85de                	mv	a1,s7
    80005164:	8562                	mv	a0,s8
    80005166:	ffffd097          	auipc	ra,0xffffd
    8000516a:	118080e7          	jalr	280(ra) # 8000227e <sleep>
    8000516e:	a839                	j	8000518c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005170:	21c4a783          	lw	a5,540(s1)
    80005174:	0017871b          	addiw	a4,a5,1
    80005178:	20e4ae23          	sw	a4,540(s1)
    8000517c:	1ff7f793          	andi	a5,a5,511
    80005180:	97a6                	add	a5,a5,s1
    80005182:	f9f44703          	lbu	a4,-97(s0)
    80005186:	00e78c23          	sb	a4,24(a5)
      i++;
    8000518a:	2905                	addiw	s2,s2,1
  while(i < n){
    8000518c:	03495d63          	bge	s2,s4,800051c6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005190:	2204a783          	lw	a5,544(s1)
    80005194:	dfd1                	beqz	a5,80005130 <pipewrite+0x48>
    80005196:	0289a783          	lw	a5,40(s3)
    8000519a:	fbd9                	bnez	a5,80005130 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000519c:	2184a783          	lw	a5,536(s1)
    800051a0:	21c4a703          	lw	a4,540(s1)
    800051a4:	2007879b          	addiw	a5,a5,512
    800051a8:	faf708e3          	beq	a4,a5,80005158 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800051ac:	4685                	li	a3,1
    800051ae:	01590633          	add	a2,s2,s5
    800051b2:	f9f40593          	addi	a1,s0,-97
    800051b6:	0509b503          	ld	a0,80(s3)
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	544080e7          	jalr	1348(ra) # 800016fe <copyin>
    800051c2:	fb6517e3          	bne	a0,s6,80005170 <pipewrite+0x88>
  wakeup(&pi->nread);
    800051c6:	21848513          	addi	a0,s1,536
    800051ca:	ffffd097          	auipc	ra,0xffffd
    800051ce:	240080e7          	jalr	576(ra) # 8000240a <wakeup>
  release(&pi->lock);
    800051d2:	8526                	mv	a0,s1
    800051d4:	ffffc097          	auipc	ra,0xffffc
    800051d8:	ac4080e7          	jalr	-1340(ra) # 80000c98 <release>
  return i;
    800051dc:	b785                	j	8000513c <pipewrite+0x54>
  int i = 0;
    800051de:	4901                	li	s2,0
    800051e0:	b7dd                	j	800051c6 <pipewrite+0xde>

00000000800051e2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051e2:	715d                	addi	sp,sp,-80
    800051e4:	e486                	sd	ra,72(sp)
    800051e6:	e0a2                	sd	s0,64(sp)
    800051e8:	fc26                	sd	s1,56(sp)
    800051ea:	f84a                	sd	s2,48(sp)
    800051ec:	f44e                	sd	s3,40(sp)
    800051ee:	f052                	sd	s4,32(sp)
    800051f0:	ec56                	sd	s5,24(sp)
    800051f2:	e85a                	sd	s6,16(sp)
    800051f4:	0880                	addi	s0,sp,80
    800051f6:	84aa                	mv	s1,a0
    800051f8:	892e                	mv	s2,a1
    800051fa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	942080e7          	jalr	-1726(ra) # 80001b3e <myproc>
    80005204:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005206:	8b26                	mv	s6,s1
    80005208:	8526                	mv	a0,s1
    8000520a:	ffffc097          	auipc	ra,0xffffc
    8000520e:	9da080e7          	jalr	-1574(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005212:	2184a703          	lw	a4,536(s1)
    80005216:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000521a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000521e:	02f71463          	bne	a4,a5,80005246 <piperead+0x64>
    80005222:	2244a783          	lw	a5,548(s1)
    80005226:	c385                	beqz	a5,80005246 <piperead+0x64>
    if(pr->killed){
    80005228:	028a2783          	lw	a5,40(s4)
    8000522c:	ebc1                	bnez	a5,800052bc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000522e:	85da                	mv	a1,s6
    80005230:	854e                	mv	a0,s3
    80005232:	ffffd097          	auipc	ra,0xffffd
    80005236:	04c080e7          	jalr	76(ra) # 8000227e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000523a:	2184a703          	lw	a4,536(s1)
    8000523e:	21c4a783          	lw	a5,540(s1)
    80005242:	fef700e3          	beq	a4,a5,80005222 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005246:	09505263          	blez	s5,800052ca <piperead+0xe8>
    8000524a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000524c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000524e:	2184a783          	lw	a5,536(s1)
    80005252:	21c4a703          	lw	a4,540(s1)
    80005256:	02f70d63          	beq	a4,a5,80005290 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000525a:	0017871b          	addiw	a4,a5,1
    8000525e:	20e4ac23          	sw	a4,536(s1)
    80005262:	1ff7f793          	andi	a5,a5,511
    80005266:	97a6                	add	a5,a5,s1
    80005268:	0187c783          	lbu	a5,24(a5)
    8000526c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005270:	4685                	li	a3,1
    80005272:	fbf40613          	addi	a2,s0,-65
    80005276:	85ca                	mv	a1,s2
    80005278:	050a3503          	ld	a0,80(s4)
    8000527c:	ffffc097          	auipc	ra,0xffffc
    80005280:	3f6080e7          	jalr	1014(ra) # 80001672 <copyout>
    80005284:	01650663          	beq	a0,s6,80005290 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005288:	2985                	addiw	s3,s3,1
    8000528a:	0905                	addi	s2,s2,1
    8000528c:	fd3a91e3          	bne	s5,s3,8000524e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005290:	21c48513          	addi	a0,s1,540
    80005294:	ffffd097          	auipc	ra,0xffffd
    80005298:	176080e7          	jalr	374(ra) # 8000240a <wakeup>
  release(&pi->lock);
    8000529c:	8526                	mv	a0,s1
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	9fa080e7          	jalr	-1542(ra) # 80000c98 <release>
  return i;
}
    800052a6:	854e                	mv	a0,s3
    800052a8:	60a6                	ld	ra,72(sp)
    800052aa:	6406                	ld	s0,64(sp)
    800052ac:	74e2                	ld	s1,56(sp)
    800052ae:	7942                	ld	s2,48(sp)
    800052b0:	79a2                	ld	s3,40(sp)
    800052b2:	7a02                	ld	s4,32(sp)
    800052b4:	6ae2                	ld	s5,24(sp)
    800052b6:	6b42                	ld	s6,16(sp)
    800052b8:	6161                	addi	sp,sp,80
    800052ba:	8082                	ret
      release(&pi->lock);
    800052bc:	8526                	mv	a0,s1
    800052be:	ffffc097          	auipc	ra,0xffffc
    800052c2:	9da080e7          	jalr	-1574(ra) # 80000c98 <release>
      return -1;
    800052c6:	59fd                	li	s3,-1
    800052c8:	bff9                	j	800052a6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052ca:	4981                	li	s3,0
    800052cc:	b7d1                	j	80005290 <piperead+0xae>

00000000800052ce <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800052ce:	df010113          	addi	sp,sp,-528
    800052d2:	20113423          	sd	ra,520(sp)
    800052d6:	20813023          	sd	s0,512(sp)
    800052da:	ffa6                	sd	s1,504(sp)
    800052dc:	fbca                	sd	s2,496(sp)
    800052de:	f7ce                	sd	s3,488(sp)
    800052e0:	f3d2                	sd	s4,480(sp)
    800052e2:	efd6                	sd	s5,472(sp)
    800052e4:	ebda                	sd	s6,464(sp)
    800052e6:	e7de                	sd	s7,456(sp)
    800052e8:	e3e2                	sd	s8,448(sp)
    800052ea:	ff66                	sd	s9,440(sp)
    800052ec:	fb6a                	sd	s10,432(sp)
    800052ee:	f76e                	sd	s11,424(sp)
    800052f0:	0c00                	addi	s0,sp,528
    800052f2:	84aa                	mv	s1,a0
    800052f4:	dea43c23          	sd	a0,-520(s0)
    800052f8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052fc:	ffffd097          	auipc	ra,0xffffd
    80005300:	842080e7          	jalr	-1982(ra) # 80001b3e <myproc>
    80005304:	892a                	mv	s2,a0

  begin_op();
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	49c080e7          	jalr	1180(ra) # 800047a2 <begin_op>

  if((ip = namei(path)) == 0){
    8000530e:	8526                	mv	a0,s1
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	276080e7          	jalr	630(ra) # 80004586 <namei>
    80005318:	c92d                	beqz	a0,8000538a <exec+0xbc>
    8000531a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	ab4080e7          	jalr	-1356(ra) # 80003dd0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005324:	04000713          	li	a4,64
    80005328:	4681                	li	a3,0
    8000532a:	e5040613          	addi	a2,s0,-432
    8000532e:	4581                	li	a1,0
    80005330:	8526                	mv	a0,s1
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	d52080e7          	jalr	-686(ra) # 80004084 <readi>
    8000533a:	04000793          	li	a5,64
    8000533e:	00f51a63          	bne	a0,a5,80005352 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005342:	e5042703          	lw	a4,-432(s0)
    80005346:	464c47b7          	lui	a5,0x464c4
    8000534a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000534e:	04f70463          	beq	a4,a5,80005396 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005352:	8526                	mv	a0,s1
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	cde080e7          	jalr	-802(ra) # 80004032 <iunlockput>
    end_op();
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	4c6080e7          	jalr	1222(ra) # 80004822 <end_op>
  }
  return -1;
    80005364:	557d                	li	a0,-1
}
    80005366:	20813083          	ld	ra,520(sp)
    8000536a:	20013403          	ld	s0,512(sp)
    8000536e:	74fe                	ld	s1,504(sp)
    80005370:	795e                	ld	s2,496(sp)
    80005372:	79be                	ld	s3,488(sp)
    80005374:	7a1e                	ld	s4,480(sp)
    80005376:	6afe                	ld	s5,472(sp)
    80005378:	6b5e                	ld	s6,464(sp)
    8000537a:	6bbe                	ld	s7,456(sp)
    8000537c:	6c1e                	ld	s8,448(sp)
    8000537e:	7cfa                	ld	s9,440(sp)
    80005380:	7d5a                	ld	s10,432(sp)
    80005382:	7dba                	ld	s11,424(sp)
    80005384:	21010113          	addi	sp,sp,528
    80005388:	8082                	ret
    end_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	498080e7          	jalr	1176(ra) # 80004822 <end_op>
    return -1;
    80005392:	557d                	li	a0,-1
    80005394:	bfc9                	j	80005366 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005396:	854a                	mv	a0,s2
    80005398:	ffffd097          	auipc	ra,0xffffd
    8000539c:	86a080e7          	jalr	-1942(ra) # 80001c02 <proc_pagetable>
    800053a0:	8baa                	mv	s7,a0
    800053a2:	d945                	beqz	a0,80005352 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a4:	e7042983          	lw	s3,-400(s0)
    800053a8:	e8845783          	lhu	a5,-376(s0)
    800053ac:	c7ad                	beqz	a5,80005416 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ae:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053b0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800053b2:	6c85                	lui	s9,0x1
    800053b4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053b8:	def43823          	sd	a5,-528(s0)
    800053bc:	a42d                	j	800055e6 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053be:	00003517          	auipc	a0,0x3
    800053c2:	50a50513          	addi	a0,a0,1290 # 800088c8 <syscalls+0x290>
    800053c6:	ffffb097          	auipc	ra,0xffffb
    800053ca:	178080e7          	jalr	376(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053ce:	8756                	mv	a4,s5
    800053d0:	012d86bb          	addw	a3,s11,s2
    800053d4:	4581                	li	a1,0
    800053d6:	8526                	mv	a0,s1
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	cac080e7          	jalr	-852(ra) # 80004084 <readi>
    800053e0:	2501                	sext.w	a0,a0
    800053e2:	1aaa9963          	bne	s5,a0,80005594 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800053e6:	6785                	lui	a5,0x1
    800053e8:	0127893b          	addw	s2,a5,s2
    800053ec:	77fd                	lui	a5,0xfffff
    800053ee:	01478a3b          	addw	s4,a5,s4
    800053f2:	1f897163          	bgeu	s2,s8,800055d4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800053f6:	02091593          	slli	a1,s2,0x20
    800053fa:	9181                	srli	a1,a1,0x20
    800053fc:	95ea                	add	a1,a1,s10
    800053fe:	855e                	mv	a0,s7
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	c6e080e7          	jalr	-914(ra) # 8000106e <walkaddr>
    80005408:	862a                	mv	a2,a0
    if(pa == 0)
    8000540a:	d955                	beqz	a0,800053be <exec+0xf0>
      n = PGSIZE;
    8000540c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000540e:	fd9a70e3          	bgeu	s4,s9,800053ce <exec+0x100>
      n = sz - i;
    80005412:	8ad2                	mv	s5,s4
    80005414:	bf6d                	j	800053ce <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005416:	4901                	li	s2,0
  iunlockput(ip);
    80005418:	8526                	mv	a0,s1
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	c18080e7          	jalr	-1000(ra) # 80004032 <iunlockput>
  end_op();
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	400080e7          	jalr	1024(ra) # 80004822 <end_op>
  p = myproc();
    8000542a:	ffffc097          	auipc	ra,0xffffc
    8000542e:	714080e7          	jalr	1812(ra) # 80001b3e <myproc>
    80005432:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005434:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005438:	6785                	lui	a5,0x1
    8000543a:	17fd                	addi	a5,a5,-1
    8000543c:	993e                	add	s2,s2,a5
    8000543e:	757d                	lui	a0,0xfffff
    80005440:	00a977b3          	and	a5,s2,a0
    80005444:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005448:	6609                	lui	a2,0x2
    8000544a:	963e                	add	a2,a2,a5
    8000544c:	85be                	mv	a1,a5
    8000544e:	855e                	mv	a0,s7
    80005450:	ffffc097          	auipc	ra,0xffffc
    80005454:	fd2080e7          	jalr	-46(ra) # 80001422 <uvmalloc>
    80005458:	8b2a                	mv	s6,a0
  ip = 0;
    8000545a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000545c:	12050c63          	beqz	a0,80005594 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005460:	75f9                	lui	a1,0xffffe
    80005462:	95aa                	add	a1,a1,a0
    80005464:	855e                	mv	a0,s7
    80005466:	ffffc097          	auipc	ra,0xffffc
    8000546a:	1da080e7          	jalr	474(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    8000546e:	7c7d                	lui	s8,0xfffff
    80005470:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005472:	e0043783          	ld	a5,-512(s0)
    80005476:	6388                	ld	a0,0(a5)
    80005478:	c535                	beqz	a0,800054e4 <exec+0x216>
    8000547a:	e9040993          	addi	s3,s0,-368
    8000547e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005482:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005484:	ffffc097          	auipc	ra,0xffffc
    80005488:	9e0080e7          	jalr	-1568(ra) # 80000e64 <strlen>
    8000548c:	2505                	addiw	a0,a0,1
    8000548e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005492:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005496:	13896363          	bltu	s2,s8,800055bc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000549a:	e0043d83          	ld	s11,-512(s0)
    8000549e:	000dba03          	ld	s4,0(s11)
    800054a2:	8552                	mv	a0,s4
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	9c0080e7          	jalr	-1600(ra) # 80000e64 <strlen>
    800054ac:	0015069b          	addiw	a3,a0,1
    800054b0:	8652                	mv	a2,s4
    800054b2:	85ca                	mv	a1,s2
    800054b4:	855e                	mv	a0,s7
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	1bc080e7          	jalr	444(ra) # 80001672 <copyout>
    800054be:	10054363          	bltz	a0,800055c4 <exec+0x2f6>
    ustack[argc] = sp;
    800054c2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054c6:	0485                	addi	s1,s1,1
    800054c8:	008d8793          	addi	a5,s11,8
    800054cc:	e0f43023          	sd	a5,-512(s0)
    800054d0:	008db503          	ld	a0,8(s11)
    800054d4:	c911                	beqz	a0,800054e8 <exec+0x21a>
    if(argc >= MAXARG)
    800054d6:	09a1                	addi	s3,s3,8
    800054d8:	fb3c96e3          	bne	s9,s3,80005484 <exec+0x1b6>
  sz = sz1;
    800054dc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054e0:	4481                	li	s1,0
    800054e2:	a84d                	j	80005594 <exec+0x2c6>
  sp = sz;
    800054e4:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800054e6:	4481                	li	s1,0
  ustack[argc] = 0;
    800054e8:	00349793          	slli	a5,s1,0x3
    800054ec:	f9040713          	addi	a4,s0,-112
    800054f0:	97ba                	add	a5,a5,a4
    800054f2:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800054f6:	00148693          	addi	a3,s1,1
    800054fa:	068e                	slli	a3,a3,0x3
    800054fc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005500:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005504:	01897663          	bgeu	s2,s8,80005510 <exec+0x242>
  sz = sz1;
    80005508:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000550c:	4481                	li	s1,0
    8000550e:	a059                	j	80005594 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005510:	e9040613          	addi	a2,s0,-368
    80005514:	85ca                	mv	a1,s2
    80005516:	855e                	mv	a0,s7
    80005518:	ffffc097          	auipc	ra,0xffffc
    8000551c:	15a080e7          	jalr	346(ra) # 80001672 <copyout>
    80005520:	0a054663          	bltz	a0,800055cc <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005524:	058ab783          	ld	a5,88(s5)
    80005528:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000552c:	df843783          	ld	a5,-520(s0)
    80005530:	0007c703          	lbu	a4,0(a5)
    80005534:	cf11                	beqz	a4,80005550 <exec+0x282>
    80005536:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005538:	02f00693          	li	a3,47
    8000553c:	a039                	j	8000554a <exec+0x27c>
      last = s+1;
    8000553e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005542:	0785                	addi	a5,a5,1
    80005544:	fff7c703          	lbu	a4,-1(a5)
    80005548:	c701                	beqz	a4,80005550 <exec+0x282>
    if(*s == '/')
    8000554a:	fed71ce3          	bne	a4,a3,80005542 <exec+0x274>
    8000554e:	bfc5                	j	8000553e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005550:	4641                	li	a2,16
    80005552:	df843583          	ld	a1,-520(s0)
    80005556:	158a8513          	addi	a0,s5,344
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	8d8080e7          	jalr	-1832(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005562:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005566:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000556a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000556e:	058ab783          	ld	a5,88(s5)
    80005572:	e6843703          	ld	a4,-408(s0)
    80005576:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005578:	058ab783          	ld	a5,88(s5)
    8000557c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005580:	85ea                	mv	a1,s10
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	71c080e7          	jalr	1820(ra) # 80001c9e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000558a:	0004851b          	sext.w	a0,s1
    8000558e:	bbe1                	j	80005366 <exec+0x98>
    80005590:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005594:	e0843583          	ld	a1,-504(s0)
    80005598:	855e                	mv	a0,s7
    8000559a:	ffffc097          	auipc	ra,0xffffc
    8000559e:	704080e7          	jalr	1796(ra) # 80001c9e <proc_freepagetable>
  if(ip){
    800055a2:	da0498e3          	bnez	s1,80005352 <exec+0x84>
  return -1;
    800055a6:	557d                	li	a0,-1
    800055a8:	bb7d                	j	80005366 <exec+0x98>
    800055aa:	e1243423          	sd	s2,-504(s0)
    800055ae:	b7dd                	j	80005594 <exec+0x2c6>
    800055b0:	e1243423          	sd	s2,-504(s0)
    800055b4:	b7c5                	j	80005594 <exec+0x2c6>
    800055b6:	e1243423          	sd	s2,-504(s0)
    800055ba:	bfe9                	j	80005594 <exec+0x2c6>
  sz = sz1;
    800055bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055c0:	4481                	li	s1,0
    800055c2:	bfc9                	j	80005594 <exec+0x2c6>
  sz = sz1;
    800055c4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055c8:	4481                	li	s1,0
    800055ca:	b7e9                	j	80005594 <exec+0x2c6>
  sz = sz1;
    800055cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800055d0:	4481                	li	s1,0
    800055d2:	b7c9                	j	80005594 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800055d4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055d8:	2b05                	addiw	s6,s6,1
    800055da:	0389899b          	addiw	s3,s3,56
    800055de:	e8845783          	lhu	a5,-376(s0)
    800055e2:	e2fb5be3          	bge	s6,a5,80005418 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055e6:	2981                	sext.w	s3,s3
    800055e8:	03800713          	li	a4,56
    800055ec:	86ce                	mv	a3,s3
    800055ee:	e1840613          	addi	a2,s0,-488
    800055f2:	4581                	li	a1,0
    800055f4:	8526                	mv	a0,s1
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	a8e080e7          	jalr	-1394(ra) # 80004084 <readi>
    800055fe:	03800793          	li	a5,56
    80005602:	f8f517e3          	bne	a0,a5,80005590 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005606:	e1842783          	lw	a5,-488(s0)
    8000560a:	4705                	li	a4,1
    8000560c:	fce796e3          	bne	a5,a4,800055d8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005610:	e4043603          	ld	a2,-448(s0)
    80005614:	e3843783          	ld	a5,-456(s0)
    80005618:	f8f669e3          	bltu	a2,a5,800055aa <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000561c:	e2843783          	ld	a5,-472(s0)
    80005620:	963e                	add	a2,a2,a5
    80005622:	f8f667e3          	bltu	a2,a5,800055b0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005626:	85ca                	mv	a1,s2
    80005628:	855e                	mv	a0,s7
    8000562a:	ffffc097          	auipc	ra,0xffffc
    8000562e:	df8080e7          	jalr	-520(ra) # 80001422 <uvmalloc>
    80005632:	e0a43423          	sd	a0,-504(s0)
    80005636:	d141                	beqz	a0,800055b6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005638:	e2843d03          	ld	s10,-472(s0)
    8000563c:	df043783          	ld	a5,-528(s0)
    80005640:	00fd77b3          	and	a5,s10,a5
    80005644:	fba1                	bnez	a5,80005594 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005646:	e2042d83          	lw	s11,-480(s0)
    8000564a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000564e:	f80c03e3          	beqz	s8,800055d4 <exec+0x306>
    80005652:	8a62                	mv	s4,s8
    80005654:	4901                	li	s2,0
    80005656:	b345                	j	800053f6 <exec+0x128>

0000000080005658 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005658:	7179                	addi	sp,sp,-48
    8000565a:	f406                	sd	ra,40(sp)
    8000565c:	f022                	sd	s0,32(sp)
    8000565e:	ec26                	sd	s1,24(sp)
    80005660:	e84a                	sd	s2,16(sp)
    80005662:	1800                	addi	s0,sp,48
    80005664:	892e                	mv	s2,a1
    80005666:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005668:	fdc40593          	addi	a1,s0,-36
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	992080e7          	jalr	-1646(ra) # 80002ffe <argint>
    80005674:	04054063          	bltz	a0,800056b4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005678:	fdc42703          	lw	a4,-36(s0)
    8000567c:	47bd                	li	a5,15
    8000567e:	02e7ed63          	bltu	a5,a4,800056b8 <argfd+0x60>
    80005682:	ffffc097          	auipc	ra,0xffffc
    80005686:	4bc080e7          	jalr	1212(ra) # 80001b3e <myproc>
    8000568a:	fdc42703          	lw	a4,-36(s0)
    8000568e:	01a70793          	addi	a5,a4,26
    80005692:	078e                	slli	a5,a5,0x3
    80005694:	953e                	add	a0,a0,a5
    80005696:	611c                	ld	a5,0(a0)
    80005698:	c395                	beqz	a5,800056bc <argfd+0x64>
    return -1;
  if(pfd)
    8000569a:	00090463          	beqz	s2,800056a2 <argfd+0x4a>
    *pfd = fd;
    8000569e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056a2:	4501                	li	a0,0
  if(pf)
    800056a4:	c091                	beqz	s1,800056a8 <argfd+0x50>
    *pf = f;
    800056a6:	e09c                	sd	a5,0(s1)
}
    800056a8:	70a2                	ld	ra,40(sp)
    800056aa:	7402                	ld	s0,32(sp)
    800056ac:	64e2                	ld	s1,24(sp)
    800056ae:	6942                	ld	s2,16(sp)
    800056b0:	6145                	addi	sp,sp,48
    800056b2:	8082                	ret
    return -1;
    800056b4:	557d                	li	a0,-1
    800056b6:	bfcd                	j	800056a8 <argfd+0x50>
    return -1;
    800056b8:	557d                	li	a0,-1
    800056ba:	b7fd                	j	800056a8 <argfd+0x50>
    800056bc:	557d                	li	a0,-1
    800056be:	b7ed                	j	800056a8 <argfd+0x50>

00000000800056c0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056c0:	1101                	addi	sp,sp,-32
    800056c2:	ec06                	sd	ra,24(sp)
    800056c4:	e822                	sd	s0,16(sp)
    800056c6:	e426                	sd	s1,8(sp)
    800056c8:	1000                	addi	s0,sp,32
    800056ca:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056cc:	ffffc097          	auipc	ra,0xffffc
    800056d0:	472080e7          	jalr	1138(ra) # 80001b3e <myproc>
    800056d4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056d6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd70d0>
    800056da:	4501                	li	a0,0
    800056dc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056de:	6398                	ld	a4,0(a5)
    800056e0:	cb19                	beqz	a4,800056f6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056e2:	2505                	addiw	a0,a0,1
    800056e4:	07a1                	addi	a5,a5,8
    800056e6:	fed51ce3          	bne	a0,a3,800056de <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056ea:	557d                	li	a0,-1
}
    800056ec:	60e2                	ld	ra,24(sp)
    800056ee:	6442                	ld	s0,16(sp)
    800056f0:	64a2                	ld	s1,8(sp)
    800056f2:	6105                	addi	sp,sp,32
    800056f4:	8082                	ret
      p->ofile[fd] = f;
    800056f6:	01a50793          	addi	a5,a0,26
    800056fa:	078e                	slli	a5,a5,0x3
    800056fc:	963e                	add	a2,a2,a5
    800056fe:	e204                	sd	s1,0(a2)
      return fd;
    80005700:	b7f5                	j	800056ec <fdalloc+0x2c>

0000000080005702 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005702:	715d                	addi	sp,sp,-80
    80005704:	e486                	sd	ra,72(sp)
    80005706:	e0a2                	sd	s0,64(sp)
    80005708:	fc26                	sd	s1,56(sp)
    8000570a:	f84a                	sd	s2,48(sp)
    8000570c:	f44e                	sd	s3,40(sp)
    8000570e:	f052                	sd	s4,32(sp)
    80005710:	ec56                	sd	s5,24(sp)
    80005712:	0880                	addi	s0,sp,80
    80005714:	89ae                	mv	s3,a1
    80005716:	8ab2                	mv	s5,a2
    80005718:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000571a:	fb040593          	addi	a1,s0,-80
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	e86080e7          	jalr	-378(ra) # 800045a4 <nameiparent>
    80005726:	892a                	mv	s2,a0
    80005728:	12050f63          	beqz	a0,80005866 <create+0x164>
    return 0;

  ilock(dp);
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	6a4080e7          	jalr	1700(ra) # 80003dd0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005734:	4601                	li	a2,0
    80005736:	fb040593          	addi	a1,s0,-80
    8000573a:	854a                	mv	a0,s2
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	b78080e7          	jalr	-1160(ra) # 800042b4 <dirlookup>
    80005744:	84aa                	mv	s1,a0
    80005746:	c921                	beqz	a0,80005796 <create+0x94>
    iunlockput(dp);
    80005748:	854a                	mv	a0,s2
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	8e8080e7          	jalr	-1816(ra) # 80004032 <iunlockput>
    ilock(ip);
    80005752:	8526                	mv	a0,s1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	67c080e7          	jalr	1660(ra) # 80003dd0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000575c:	2981                	sext.w	s3,s3
    8000575e:	4789                	li	a5,2
    80005760:	02f99463          	bne	s3,a5,80005788 <create+0x86>
    80005764:	0444d783          	lhu	a5,68(s1)
    80005768:	37f9                	addiw	a5,a5,-2
    8000576a:	17c2                	slli	a5,a5,0x30
    8000576c:	93c1                	srli	a5,a5,0x30
    8000576e:	4705                	li	a4,1
    80005770:	00f76c63          	bltu	a4,a5,80005788 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005774:	8526                	mv	a0,s1
    80005776:	60a6                	ld	ra,72(sp)
    80005778:	6406                	ld	s0,64(sp)
    8000577a:	74e2                	ld	s1,56(sp)
    8000577c:	7942                	ld	s2,48(sp)
    8000577e:	79a2                	ld	s3,40(sp)
    80005780:	7a02                	ld	s4,32(sp)
    80005782:	6ae2                	ld	s5,24(sp)
    80005784:	6161                	addi	sp,sp,80
    80005786:	8082                	ret
    iunlockput(ip);
    80005788:	8526                	mv	a0,s1
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	8a8080e7          	jalr	-1880(ra) # 80004032 <iunlockput>
    return 0;
    80005792:	4481                	li	s1,0
    80005794:	b7c5                	j	80005774 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005796:	85ce                	mv	a1,s3
    80005798:	00092503          	lw	a0,0(s2)
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	49c080e7          	jalr	1180(ra) # 80003c38 <ialloc>
    800057a4:	84aa                	mv	s1,a0
    800057a6:	c529                	beqz	a0,800057f0 <create+0xee>
  ilock(ip);
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	628080e7          	jalr	1576(ra) # 80003dd0 <ilock>
  ip->major = major;
    800057b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800057b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800057b8:	4785                	li	a5,1
    800057ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057be:	8526                	mv	a0,s1
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	546080e7          	jalr	1350(ra) # 80003d06 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057c8:	2981                	sext.w	s3,s3
    800057ca:	4785                	li	a5,1
    800057cc:	02f98a63          	beq	s3,a5,80005800 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800057d0:	40d0                	lw	a2,4(s1)
    800057d2:	fb040593          	addi	a1,s0,-80
    800057d6:	854a                	mv	a0,s2
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	cec080e7          	jalr	-788(ra) # 800044c4 <dirlink>
    800057e0:	06054b63          	bltz	a0,80005856 <create+0x154>
  iunlockput(dp);
    800057e4:	854a                	mv	a0,s2
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	84c080e7          	jalr	-1972(ra) # 80004032 <iunlockput>
  return ip;
    800057ee:	b759                	j	80005774 <create+0x72>
    panic("create: ialloc");
    800057f0:	00003517          	auipc	a0,0x3
    800057f4:	0f850513          	addi	a0,a0,248 # 800088e8 <syscalls+0x2b0>
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	d46080e7          	jalr	-698(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005800:	04a95783          	lhu	a5,74(s2)
    80005804:	2785                	addiw	a5,a5,1
    80005806:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000580a:	854a                	mv	a0,s2
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	4fa080e7          	jalr	1274(ra) # 80003d06 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005814:	40d0                	lw	a2,4(s1)
    80005816:	00003597          	auipc	a1,0x3
    8000581a:	0e258593          	addi	a1,a1,226 # 800088f8 <syscalls+0x2c0>
    8000581e:	8526                	mv	a0,s1
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	ca4080e7          	jalr	-860(ra) # 800044c4 <dirlink>
    80005828:	00054f63          	bltz	a0,80005846 <create+0x144>
    8000582c:	00492603          	lw	a2,4(s2)
    80005830:	00003597          	auipc	a1,0x3
    80005834:	0d058593          	addi	a1,a1,208 # 80008900 <syscalls+0x2c8>
    80005838:	8526                	mv	a0,s1
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	c8a080e7          	jalr	-886(ra) # 800044c4 <dirlink>
    80005842:	f80557e3          	bgez	a0,800057d0 <create+0xce>
      panic("create dots");
    80005846:	00003517          	auipc	a0,0x3
    8000584a:	0c250513          	addi	a0,a0,194 # 80008908 <syscalls+0x2d0>
    8000584e:	ffffb097          	auipc	ra,0xffffb
    80005852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005856:	00003517          	auipc	a0,0x3
    8000585a:	0c250513          	addi	a0,a0,194 # 80008918 <syscalls+0x2e0>
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>
    return 0;
    80005866:	84aa                	mv	s1,a0
    80005868:	b731                	j	80005774 <create+0x72>

000000008000586a <sys_dup>:
{
    8000586a:	7179                	addi	sp,sp,-48
    8000586c:	f406                	sd	ra,40(sp)
    8000586e:	f022                	sd	s0,32(sp)
    80005870:	ec26                	sd	s1,24(sp)
    80005872:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005874:	fd840613          	addi	a2,s0,-40
    80005878:	4581                	li	a1,0
    8000587a:	4501                	li	a0,0
    8000587c:	00000097          	auipc	ra,0x0
    80005880:	ddc080e7          	jalr	-548(ra) # 80005658 <argfd>
    return -1;
    80005884:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005886:	02054363          	bltz	a0,800058ac <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000588a:	fd843503          	ld	a0,-40(s0)
    8000588e:	00000097          	auipc	ra,0x0
    80005892:	e32080e7          	jalr	-462(ra) # 800056c0 <fdalloc>
    80005896:	84aa                	mv	s1,a0
    return -1;
    80005898:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000589a:	00054963          	bltz	a0,800058ac <sys_dup+0x42>
  filedup(f);
    8000589e:	fd843503          	ld	a0,-40(s0)
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	37a080e7          	jalr	890(ra) # 80004c1c <filedup>
  return fd;
    800058aa:	87a6                	mv	a5,s1
}
    800058ac:	853e                	mv	a0,a5
    800058ae:	70a2                	ld	ra,40(sp)
    800058b0:	7402                	ld	s0,32(sp)
    800058b2:	64e2                	ld	s1,24(sp)
    800058b4:	6145                	addi	sp,sp,48
    800058b6:	8082                	ret

00000000800058b8 <sys_read>:
{
    800058b8:	7179                	addi	sp,sp,-48
    800058ba:	f406                	sd	ra,40(sp)
    800058bc:	f022                	sd	s0,32(sp)
    800058be:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c0:	fe840613          	addi	a2,s0,-24
    800058c4:	4581                	li	a1,0
    800058c6:	4501                	li	a0,0
    800058c8:	00000097          	auipc	ra,0x0
    800058cc:	d90080e7          	jalr	-624(ra) # 80005658 <argfd>
    return -1;
    800058d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d2:	04054163          	bltz	a0,80005914 <sys_read+0x5c>
    800058d6:	fe440593          	addi	a1,s0,-28
    800058da:	4509                	li	a0,2
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	722080e7          	jalr	1826(ra) # 80002ffe <argint>
    return -1;
    800058e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e6:	02054763          	bltz	a0,80005914 <sys_read+0x5c>
    800058ea:	fd840593          	addi	a1,s0,-40
    800058ee:	4505                	li	a0,1
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	730080e7          	jalr	1840(ra) # 80003020 <argaddr>
    return -1;
    800058f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fa:	00054d63          	bltz	a0,80005914 <sys_read+0x5c>
  return fileread(f, p, n);
    800058fe:	fe442603          	lw	a2,-28(s0)
    80005902:	fd843583          	ld	a1,-40(s0)
    80005906:	fe843503          	ld	a0,-24(s0)
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	49e080e7          	jalr	1182(ra) # 80004da8 <fileread>
    80005912:	87aa                	mv	a5,a0
}
    80005914:	853e                	mv	a0,a5
    80005916:	70a2                	ld	ra,40(sp)
    80005918:	7402                	ld	s0,32(sp)
    8000591a:	6145                	addi	sp,sp,48
    8000591c:	8082                	ret

000000008000591e <sys_write>:
{
    8000591e:	7179                	addi	sp,sp,-48
    80005920:	f406                	sd	ra,40(sp)
    80005922:	f022                	sd	s0,32(sp)
    80005924:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005926:	fe840613          	addi	a2,s0,-24
    8000592a:	4581                	li	a1,0
    8000592c:	4501                	li	a0,0
    8000592e:	00000097          	auipc	ra,0x0
    80005932:	d2a080e7          	jalr	-726(ra) # 80005658 <argfd>
    return -1;
    80005936:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005938:	04054163          	bltz	a0,8000597a <sys_write+0x5c>
    8000593c:	fe440593          	addi	a1,s0,-28
    80005940:	4509                	li	a0,2
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	6bc080e7          	jalr	1724(ra) # 80002ffe <argint>
    return -1;
    8000594a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000594c:	02054763          	bltz	a0,8000597a <sys_write+0x5c>
    80005950:	fd840593          	addi	a1,s0,-40
    80005954:	4505                	li	a0,1
    80005956:	ffffd097          	auipc	ra,0xffffd
    8000595a:	6ca080e7          	jalr	1738(ra) # 80003020 <argaddr>
    return -1;
    8000595e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005960:	00054d63          	bltz	a0,8000597a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005964:	fe442603          	lw	a2,-28(s0)
    80005968:	fd843583          	ld	a1,-40(s0)
    8000596c:	fe843503          	ld	a0,-24(s0)
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	4fa080e7          	jalr	1274(ra) # 80004e6a <filewrite>
    80005978:	87aa                	mv	a5,a0
}
    8000597a:	853e                	mv	a0,a5
    8000597c:	70a2                	ld	ra,40(sp)
    8000597e:	7402                	ld	s0,32(sp)
    80005980:	6145                	addi	sp,sp,48
    80005982:	8082                	ret

0000000080005984 <sys_close>:
{
    80005984:	1101                	addi	sp,sp,-32
    80005986:	ec06                	sd	ra,24(sp)
    80005988:	e822                	sd	s0,16(sp)
    8000598a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000598c:	fe040613          	addi	a2,s0,-32
    80005990:	fec40593          	addi	a1,s0,-20
    80005994:	4501                	li	a0,0
    80005996:	00000097          	auipc	ra,0x0
    8000599a:	cc2080e7          	jalr	-830(ra) # 80005658 <argfd>
    return -1;
    8000599e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059a0:	02054463          	bltz	a0,800059c8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059a4:	ffffc097          	auipc	ra,0xffffc
    800059a8:	19a080e7          	jalr	410(ra) # 80001b3e <myproc>
    800059ac:	fec42783          	lw	a5,-20(s0)
    800059b0:	07e9                	addi	a5,a5,26
    800059b2:	078e                	slli	a5,a5,0x3
    800059b4:	97aa                	add	a5,a5,a0
    800059b6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059ba:	fe043503          	ld	a0,-32(s0)
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	2b0080e7          	jalr	688(ra) # 80004c6e <fileclose>
  return 0;
    800059c6:	4781                	li	a5,0
}
    800059c8:	853e                	mv	a0,a5
    800059ca:	60e2                	ld	ra,24(sp)
    800059cc:	6442                	ld	s0,16(sp)
    800059ce:	6105                	addi	sp,sp,32
    800059d0:	8082                	ret

00000000800059d2 <sys_fstat>:
{
    800059d2:	1101                	addi	sp,sp,-32
    800059d4:	ec06                	sd	ra,24(sp)
    800059d6:	e822                	sd	s0,16(sp)
    800059d8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059da:	fe840613          	addi	a2,s0,-24
    800059de:	4581                	li	a1,0
    800059e0:	4501                	li	a0,0
    800059e2:	00000097          	auipc	ra,0x0
    800059e6:	c76080e7          	jalr	-906(ra) # 80005658 <argfd>
    return -1;
    800059ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059ec:	02054563          	bltz	a0,80005a16 <sys_fstat+0x44>
    800059f0:	fe040593          	addi	a1,s0,-32
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	62a080e7          	jalr	1578(ra) # 80003020 <argaddr>
    return -1;
    800059fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a00:	00054b63          	bltz	a0,80005a16 <sys_fstat+0x44>
  return filestat(f, st);
    80005a04:	fe043583          	ld	a1,-32(s0)
    80005a08:	fe843503          	ld	a0,-24(s0)
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	32a080e7          	jalr	810(ra) # 80004d36 <filestat>
    80005a14:	87aa                	mv	a5,a0
}
    80005a16:	853e                	mv	a0,a5
    80005a18:	60e2                	ld	ra,24(sp)
    80005a1a:	6442                	ld	s0,16(sp)
    80005a1c:	6105                	addi	sp,sp,32
    80005a1e:	8082                	ret

0000000080005a20 <sys_link>:
{
    80005a20:	7169                	addi	sp,sp,-304
    80005a22:	f606                	sd	ra,296(sp)
    80005a24:	f222                	sd	s0,288(sp)
    80005a26:	ee26                	sd	s1,280(sp)
    80005a28:	ea4a                	sd	s2,272(sp)
    80005a2a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a2c:	08000613          	li	a2,128
    80005a30:	ed040593          	addi	a1,s0,-304
    80005a34:	4501                	li	a0,0
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	60c080e7          	jalr	1548(ra) # 80003042 <argstr>
    return -1;
    80005a3e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a40:	10054e63          	bltz	a0,80005b5c <sys_link+0x13c>
    80005a44:	08000613          	li	a2,128
    80005a48:	f5040593          	addi	a1,s0,-176
    80005a4c:	4505                	li	a0,1
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	5f4080e7          	jalr	1524(ra) # 80003042 <argstr>
    return -1;
    80005a56:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a58:	10054263          	bltz	a0,80005b5c <sys_link+0x13c>
  begin_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	d46080e7          	jalr	-698(ra) # 800047a2 <begin_op>
  if((ip = namei(old)) == 0){
    80005a64:	ed040513          	addi	a0,s0,-304
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	b1e080e7          	jalr	-1250(ra) # 80004586 <namei>
    80005a70:	84aa                	mv	s1,a0
    80005a72:	c551                	beqz	a0,80005afe <sys_link+0xde>
  ilock(ip);
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	35c080e7          	jalr	860(ra) # 80003dd0 <ilock>
  if(ip->type == T_DIR){
    80005a7c:	04449703          	lh	a4,68(s1)
    80005a80:	4785                	li	a5,1
    80005a82:	08f70463          	beq	a4,a5,80005b0a <sys_link+0xea>
  ip->nlink++;
    80005a86:	04a4d783          	lhu	a5,74(s1)
    80005a8a:	2785                	addiw	a5,a5,1
    80005a8c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a90:	8526                	mv	a0,s1
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	274080e7          	jalr	628(ra) # 80003d06 <iupdate>
  iunlock(ip);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	3f6080e7          	jalr	1014(ra) # 80003e92 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005aa4:	fd040593          	addi	a1,s0,-48
    80005aa8:	f5040513          	addi	a0,s0,-176
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	af8080e7          	jalr	-1288(ra) # 800045a4 <nameiparent>
    80005ab4:	892a                	mv	s2,a0
    80005ab6:	c935                	beqz	a0,80005b2a <sys_link+0x10a>
  ilock(dp);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	318080e7          	jalr	792(ra) # 80003dd0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005ac0:	00092703          	lw	a4,0(s2)
    80005ac4:	409c                	lw	a5,0(s1)
    80005ac6:	04f71d63          	bne	a4,a5,80005b20 <sys_link+0x100>
    80005aca:	40d0                	lw	a2,4(s1)
    80005acc:	fd040593          	addi	a1,s0,-48
    80005ad0:	854a                	mv	a0,s2
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	9f2080e7          	jalr	-1550(ra) # 800044c4 <dirlink>
    80005ada:	04054363          	bltz	a0,80005b20 <sys_link+0x100>
  iunlockput(dp);
    80005ade:	854a                	mv	a0,s2
    80005ae0:	ffffe097          	auipc	ra,0xffffe
    80005ae4:	552080e7          	jalr	1362(ra) # 80004032 <iunlockput>
  iput(ip);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	4a0080e7          	jalr	1184(ra) # 80003f8a <iput>
  end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	d30080e7          	jalr	-720(ra) # 80004822 <end_op>
  return 0;
    80005afa:	4781                	li	a5,0
    80005afc:	a085                	j	80005b5c <sys_link+0x13c>
    end_op();
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	d24080e7          	jalr	-732(ra) # 80004822 <end_op>
    return -1;
    80005b06:	57fd                	li	a5,-1
    80005b08:	a891                	j	80005b5c <sys_link+0x13c>
    iunlockput(ip);
    80005b0a:	8526                	mv	a0,s1
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	526080e7          	jalr	1318(ra) # 80004032 <iunlockput>
    end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	d0e080e7          	jalr	-754(ra) # 80004822 <end_op>
    return -1;
    80005b1c:	57fd                	li	a5,-1
    80005b1e:	a83d                	j	80005b5c <sys_link+0x13c>
    iunlockput(dp);
    80005b20:	854a                	mv	a0,s2
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	510080e7          	jalr	1296(ra) # 80004032 <iunlockput>
  ilock(ip);
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	2a4080e7          	jalr	676(ra) # 80003dd0 <ilock>
  ip->nlink--;
    80005b34:	04a4d783          	lhu	a5,74(s1)
    80005b38:	37fd                	addiw	a5,a5,-1
    80005b3a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	1c6080e7          	jalr	454(ra) # 80003d06 <iupdate>
  iunlockput(ip);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	4e8080e7          	jalr	1256(ra) # 80004032 <iunlockput>
  end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	cd0080e7          	jalr	-816(ra) # 80004822 <end_op>
  return -1;
    80005b5a:	57fd                	li	a5,-1
}
    80005b5c:	853e                	mv	a0,a5
    80005b5e:	70b2                	ld	ra,296(sp)
    80005b60:	7412                	ld	s0,288(sp)
    80005b62:	64f2                	ld	s1,280(sp)
    80005b64:	6952                	ld	s2,272(sp)
    80005b66:	6155                	addi	sp,sp,304
    80005b68:	8082                	ret

0000000080005b6a <sys_unlink>:
{
    80005b6a:	7151                	addi	sp,sp,-240
    80005b6c:	f586                	sd	ra,232(sp)
    80005b6e:	f1a2                	sd	s0,224(sp)
    80005b70:	eda6                	sd	s1,216(sp)
    80005b72:	e9ca                	sd	s2,208(sp)
    80005b74:	e5ce                	sd	s3,200(sp)
    80005b76:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b78:	08000613          	li	a2,128
    80005b7c:	f3040593          	addi	a1,s0,-208
    80005b80:	4501                	li	a0,0
    80005b82:	ffffd097          	auipc	ra,0xffffd
    80005b86:	4c0080e7          	jalr	1216(ra) # 80003042 <argstr>
    80005b8a:	18054163          	bltz	a0,80005d0c <sys_unlink+0x1a2>
  begin_op();
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	c14080e7          	jalr	-1004(ra) # 800047a2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b96:	fb040593          	addi	a1,s0,-80
    80005b9a:	f3040513          	addi	a0,s0,-208
    80005b9e:	fffff097          	auipc	ra,0xfffff
    80005ba2:	a06080e7          	jalr	-1530(ra) # 800045a4 <nameiparent>
    80005ba6:	84aa                	mv	s1,a0
    80005ba8:	c979                	beqz	a0,80005c7e <sys_unlink+0x114>
  ilock(dp);
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	226080e7          	jalr	550(ra) # 80003dd0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bb2:	00003597          	auipc	a1,0x3
    80005bb6:	d4658593          	addi	a1,a1,-698 # 800088f8 <syscalls+0x2c0>
    80005bba:	fb040513          	addi	a0,s0,-80
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	6dc080e7          	jalr	1756(ra) # 8000429a <namecmp>
    80005bc6:	14050a63          	beqz	a0,80005d1a <sys_unlink+0x1b0>
    80005bca:	00003597          	auipc	a1,0x3
    80005bce:	d3658593          	addi	a1,a1,-714 # 80008900 <syscalls+0x2c8>
    80005bd2:	fb040513          	addi	a0,s0,-80
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	6c4080e7          	jalr	1732(ra) # 8000429a <namecmp>
    80005bde:	12050e63          	beqz	a0,80005d1a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005be2:	f2c40613          	addi	a2,s0,-212
    80005be6:	fb040593          	addi	a1,s0,-80
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	6c8080e7          	jalr	1736(ra) # 800042b4 <dirlookup>
    80005bf4:	892a                	mv	s2,a0
    80005bf6:	12050263          	beqz	a0,80005d1a <sys_unlink+0x1b0>
  ilock(ip);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	1d6080e7          	jalr	470(ra) # 80003dd0 <ilock>
  if(ip->nlink < 1)
    80005c02:	04a91783          	lh	a5,74(s2)
    80005c06:	08f05263          	blez	a5,80005c8a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c0a:	04491703          	lh	a4,68(s2)
    80005c0e:	4785                	li	a5,1
    80005c10:	08f70563          	beq	a4,a5,80005c9a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c14:	4641                	li	a2,16
    80005c16:	4581                	li	a1,0
    80005c18:	fc040513          	addi	a0,s0,-64
    80005c1c:	ffffb097          	auipc	ra,0xffffb
    80005c20:	0c4080e7          	jalr	196(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c24:	4741                	li	a4,16
    80005c26:	f2c42683          	lw	a3,-212(s0)
    80005c2a:	fc040613          	addi	a2,s0,-64
    80005c2e:	4581                	li	a1,0
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	54a080e7          	jalr	1354(ra) # 8000417c <writei>
    80005c3a:	47c1                	li	a5,16
    80005c3c:	0af51563          	bne	a0,a5,80005ce6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c40:	04491703          	lh	a4,68(s2)
    80005c44:	4785                	li	a5,1
    80005c46:	0af70863          	beq	a4,a5,80005cf6 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c4a:	8526                	mv	a0,s1
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	3e6080e7          	jalr	998(ra) # 80004032 <iunlockput>
  ip->nlink--;
    80005c54:	04a95783          	lhu	a5,74(s2)
    80005c58:	37fd                	addiw	a5,a5,-1
    80005c5a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c5e:	854a                	mv	a0,s2
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	0a6080e7          	jalr	166(ra) # 80003d06 <iupdate>
  iunlockput(ip);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	3c8080e7          	jalr	968(ra) # 80004032 <iunlockput>
  end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	bb0080e7          	jalr	-1104(ra) # 80004822 <end_op>
  return 0;
    80005c7a:	4501                	li	a0,0
    80005c7c:	a84d                	j	80005d2e <sys_unlink+0x1c4>
    end_op();
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	ba4080e7          	jalr	-1116(ra) # 80004822 <end_op>
    return -1;
    80005c86:	557d                	li	a0,-1
    80005c88:	a05d                	j	80005d2e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c8a:	00003517          	auipc	a0,0x3
    80005c8e:	c9e50513          	addi	a0,a0,-866 # 80008928 <syscalls+0x2f0>
    80005c92:	ffffb097          	auipc	ra,0xffffb
    80005c96:	8ac080e7          	jalr	-1876(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c9a:	04c92703          	lw	a4,76(s2)
    80005c9e:	02000793          	li	a5,32
    80005ca2:	f6e7f9e3          	bgeu	a5,a4,80005c14 <sys_unlink+0xaa>
    80005ca6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005caa:	4741                	li	a4,16
    80005cac:	86ce                	mv	a3,s3
    80005cae:	f1840613          	addi	a2,s0,-232
    80005cb2:	4581                	li	a1,0
    80005cb4:	854a                	mv	a0,s2
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	3ce080e7          	jalr	974(ra) # 80004084 <readi>
    80005cbe:	47c1                	li	a5,16
    80005cc0:	00f51b63          	bne	a0,a5,80005cd6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cc4:	f1845783          	lhu	a5,-232(s0)
    80005cc8:	e7a1                	bnez	a5,80005d10 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cca:	29c1                	addiw	s3,s3,16
    80005ccc:	04c92783          	lw	a5,76(s2)
    80005cd0:	fcf9ede3          	bltu	s3,a5,80005caa <sys_unlink+0x140>
    80005cd4:	b781                	j	80005c14 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cd6:	00003517          	auipc	a0,0x3
    80005cda:	c6a50513          	addi	a0,a0,-918 # 80008940 <syscalls+0x308>
    80005cde:	ffffb097          	auipc	ra,0xffffb
    80005ce2:	860080e7          	jalr	-1952(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005ce6:	00003517          	auipc	a0,0x3
    80005cea:	c7250513          	addi	a0,a0,-910 # 80008958 <syscalls+0x320>
    80005cee:	ffffb097          	auipc	ra,0xffffb
    80005cf2:	850080e7          	jalr	-1968(ra) # 8000053e <panic>
    dp->nlink--;
    80005cf6:	04a4d783          	lhu	a5,74(s1)
    80005cfa:	37fd                	addiw	a5,a5,-1
    80005cfc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d00:	8526                	mv	a0,s1
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	004080e7          	jalr	4(ra) # 80003d06 <iupdate>
    80005d0a:	b781                	j	80005c4a <sys_unlink+0xe0>
    return -1;
    80005d0c:	557d                	li	a0,-1
    80005d0e:	a005                	j	80005d2e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d10:	854a                	mv	a0,s2
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	320080e7          	jalr	800(ra) # 80004032 <iunlockput>
  iunlockput(dp);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	316080e7          	jalr	790(ra) # 80004032 <iunlockput>
  end_op();
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	afe080e7          	jalr	-1282(ra) # 80004822 <end_op>
  return -1;
    80005d2c:	557d                	li	a0,-1
}
    80005d2e:	70ae                	ld	ra,232(sp)
    80005d30:	740e                	ld	s0,224(sp)
    80005d32:	64ee                	ld	s1,216(sp)
    80005d34:	694e                	ld	s2,208(sp)
    80005d36:	69ae                	ld	s3,200(sp)
    80005d38:	616d                	addi	sp,sp,240
    80005d3a:	8082                	ret

0000000080005d3c <sys_open>:

uint64
sys_open(void)
{
    80005d3c:	7131                	addi	sp,sp,-192
    80005d3e:	fd06                	sd	ra,184(sp)
    80005d40:	f922                	sd	s0,176(sp)
    80005d42:	f526                	sd	s1,168(sp)
    80005d44:	f14a                	sd	s2,160(sp)
    80005d46:	ed4e                	sd	s3,152(sp)
    80005d48:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d4a:	08000613          	li	a2,128
    80005d4e:	f5040593          	addi	a1,s0,-176
    80005d52:	4501                	li	a0,0
    80005d54:	ffffd097          	auipc	ra,0xffffd
    80005d58:	2ee080e7          	jalr	750(ra) # 80003042 <argstr>
    return -1;
    80005d5c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005d5e:	0c054163          	bltz	a0,80005e20 <sys_open+0xe4>
    80005d62:	f4c40593          	addi	a1,s0,-180
    80005d66:	4505                	li	a0,1
    80005d68:	ffffd097          	auipc	ra,0xffffd
    80005d6c:	296080e7          	jalr	662(ra) # 80002ffe <argint>
    80005d70:	0a054863          	bltz	a0,80005e20 <sys_open+0xe4>

  begin_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	a2e080e7          	jalr	-1490(ra) # 800047a2 <begin_op>

  if(omode & O_CREATE){
    80005d7c:	f4c42783          	lw	a5,-180(s0)
    80005d80:	2007f793          	andi	a5,a5,512
    80005d84:	cbdd                	beqz	a5,80005e3a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005d86:	4681                	li	a3,0
    80005d88:	4601                	li	a2,0
    80005d8a:	4589                	li	a1,2
    80005d8c:	f5040513          	addi	a0,s0,-176
    80005d90:	00000097          	auipc	ra,0x0
    80005d94:	972080e7          	jalr	-1678(ra) # 80005702 <create>
    80005d98:	892a                	mv	s2,a0
    if(ip == 0){
    80005d9a:	c959                	beqz	a0,80005e30 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d9c:	04491703          	lh	a4,68(s2)
    80005da0:	478d                	li	a5,3
    80005da2:	00f71763          	bne	a4,a5,80005db0 <sys_open+0x74>
    80005da6:	04695703          	lhu	a4,70(s2)
    80005daa:	47a5                	li	a5,9
    80005dac:	0ce7ec63          	bltu	a5,a4,80005e84 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	e02080e7          	jalr	-510(ra) # 80004bb2 <filealloc>
    80005db8:	89aa                	mv	s3,a0
    80005dba:	10050263          	beqz	a0,80005ebe <sys_open+0x182>
    80005dbe:	00000097          	auipc	ra,0x0
    80005dc2:	902080e7          	jalr	-1790(ra) # 800056c0 <fdalloc>
    80005dc6:	84aa                	mv	s1,a0
    80005dc8:	0e054663          	bltz	a0,80005eb4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dcc:	04491703          	lh	a4,68(s2)
    80005dd0:	478d                	li	a5,3
    80005dd2:	0cf70463          	beq	a4,a5,80005e9a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005dd6:	4789                	li	a5,2
    80005dd8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ddc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005de0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005de4:	f4c42783          	lw	a5,-180(s0)
    80005de8:	0017c713          	xori	a4,a5,1
    80005dec:	8b05                	andi	a4,a4,1
    80005dee:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005df2:	0037f713          	andi	a4,a5,3
    80005df6:	00e03733          	snez	a4,a4
    80005dfa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005dfe:	4007f793          	andi	a5,a5,1024
    80005e02:	c791                	beqz	a5,80005e0e <sys_open+0xd2>
    80005e04:	04491703          	lh	a4,68(s2)
    80005e08:	4789                	li	a5,2
    80005e0a:	08f70f63          	beq	a4,a5,80005ea8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e0e:	854a                	mv	a0,s2
    80005e10:	ffffe097          	auipc	ra,0xffffe
    80005e14:	082080e7          	jalr	130(ra) # 80003e92 <iunlock>
  end_op();
    80005e18:	fffff097          	auipc	ra,0xfffff
    80005e1c:	a0a080e7          	jalr	-1526(ra) # 80004822 <end_op>

  return fd;
}
    80005e20:	8526                	mv	a0,s1
    80005e22:	70ea                	ld	ra,184(sp)
    80005e24:	744a                	ld	s0,176(sp)
    80005e26:	74aa                	ld	s1,168(sp)
    80005e28:	790a                	ld	s2,160(sp)
    80005e2a:	69ea                	ld	s3,152(sp)
    80005e2c:	6129                	addi	sp,sp,192
    80005e2e:	8082                	ret
      end_op();
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	9f2080e7          	jalr	-1550(ra) # 80004822 <end_op>
      return -1;
    80005e38:	b7e5                	j	80005e20 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e3a:	f5040513          	addi	a0,s0,-176
    80005e3e:	ffffe097          	auipc	ra,0xffffe
    80005e42:	748080e7          	jalr	1864(ra) # 80004586 <namei>
    80005e46:	892a                	mv	s2,a0
    80005e48:	c905                	beqz	a0,80005e78 <sys_open+0x13c>
    ilock(ip);
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	f86080e7          	jalr	-122(ra) # 80003dd0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e52:	04491703          	lh	a4,68(s2)
    80005e56:	4785                	li	a5,1
    80005e58:	f4f712e3          	bne	a4,a5,80005d9c <sys_open+0x60>
    80005e5c:	f4c42783          	lw	a5,-180(s0)
    80005e60:	dba1                	beqz	a5,80005db0 <sys_open+0x74>
      iunlockput(ip);
    80005e62:	854a                	mv	a0,s2
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	1ce080e7          	jalr	462(ra) # 80004032 <iunlockput>
      end_op();
    80005e6c:	fffff097          	auipc	ra,0xfffff
    80005e70:	9b6080e7          	jalr	-1610(ra) # 80004822 <end_op>
      return -1;
    80005e74:	54fd                	li	s1,-1
    80005e76:	b76d                	j	80005e20 <sys_open+0xe4>
      end_op();
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	9aa080e7          	jalr	-1622(ra) # 80004822 <end_op>
      return -1;
    80005e80:	54fd                	li	s1,-1
    80005e82:	bf79                	j	80005e20 <sys_open+0xe4>
    iunlockput(ip);
    80005e84:	854a                	mv	a0,s2
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	1ac080e7          	jalr	428(ra) # 80004032 <iunlockput>
    end_op();
    80005e8e:	fffff097          	auipc	ra,0xfffff
    80005e92:	994080e7          	jalr	-1644(ra) # 80004822 <end_op>
    return -1;
    80005e96:	54fd                	li	s1,-1
    80005e98:	b761                	j	80005e20 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e9a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e9e:	04691783          	lh	a5,70(s2)
    80005ea2:	02f99223          	sh	a5,36(s3)
    80005ea6:	bf2d                	j	80005de0 <sys_open+0xa4>
    itrunc(ip);
    80005ea8:	854a                	mv	a0,s2
    80005eaa:	ffffe097          	auipc	ra,0xffffe
    80005eae:	034080e7          	jalr	52(ra) # 80003ede <itrunc>
    80005eb2:	bfb1                	j	80005e0e <sys_open+0xd2>
      fileclose(f);
    80005eb4:	854e                	mv	a0,s3
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	db8080e7          	jalr	-584(ra) # 80004c6e <fileclose>
    iunlockput(ip);
    80005ebe:	854a                	mv	a0,s2
    80005ec0:	ffffe097          	auipc	ra,0xffffe
    80005ec4:	172080e7          	jalr	370(ra) # 80004032 <iunlockput>
    end_op();
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	95a080e7          	jalr	-1702(ra) # 80004822 <end_op>
    return -1;
    80005ed0:	54fd                	li	s1,-1
    80005ed2:	b7b9                	j	80005e20 <sys_open+0xe4>

0000000080005ed4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ed4:	7175                	addi	sp,sp,-144
    80005ed6:	e506                	sd	ra,136(sp)
    80005ed8:	e122                	sd	s0,128(sp)
    80005eda:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	8c6080e7          	jalr	-1850(ra) # 800047a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ee4:	08000613          	li	a2,128
    80005ee8:	f7040593          	addi	a1,s0,-144
    80005eec:	4501                	li	a0,0
    80005eee:	ffffd097          	auipc	ra,0xffffd
    80005ef2:	154080e7          	jalr	340(ra) # 80003042 <argstr>
    80005ef6:	02054963          	bltz	a0,80005f28 <sys_mkdir+0x54>
    80005efa:	4681                	li	a3,0
    80005efc:	4601                	li	a2,0
    80005efe:	4585                	li	a1,1
    80005f00:	f7040513          	addi	a0,s0,-144
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	7fe080e7          	jalr	2046(ra) # 80005702 <create>
    80005f0c:	cd11                	beqz	a0,80005f28 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f0e:	ffffe097          	auipc	ra,0xffffe
    80005f12:	124080e7          	jalr	292(ra) # 80004032 <iunlockput>
  end_op();
    80005f16:	fffff097          	auipc	ra,0xfffff
    80005f1a:	90c080e7          	jalr	-1780(ra) # 80004822 <end_op>
  return 0;
    80005f1e:	4501                	li	a0,0
}
    80005f20:	60aa                	ld	ra,136(sp)
    80005f22:	640a                	ld	s0,128(sp)
    80005f24:	6149                	addi	sp,sp,144
    80005f26:	8082                	ret
    end_op();
    80005f28:	fffff097          	auipc	ra,0xfffff
    80005f2c:	8fa080e7          	jalr	-1798(ra) # 80004822 <end_op>
    return -1;
    80005f30:	557d                	li	a0,-1
    80005f32:	b7fd                	j	80005f20 <sys_mkdir+0x4c>

0000000080005f34 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f34:	7135                	addi	sp,sp,-160
    80005f36:	ed06                	sd	ra,152(sp)
    80005f38:	e922                	sd	s0,144(sp)
    80005f3a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f3c:	fffff097          	auipc	ra,0xfffff
    80005f40:	866080e7          	jalr	-1946(ra) # 800047a2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f44:	08000613          	li	a2,128
    80005f48:	f7040593          	addi	a1,s0,-144
    80005f4c:	4501                	li	a0,0
    80005f4e:	ffffd097          	auipc	ra,0xffffd
    80005f52:	0f4080e7          	jalr	244(ra) # 80003042 <argstr>
    80005f56:	04054a63          	bltz	a0,80005faa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005f5a:	f6c40593          	addi	a1,s0,-148
    80005f5e:	4505                	li	a0,1
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	09e080e7          	jalr	158(ra) # 80002ffe <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f68:	04054163          	bltz	a0,80005faa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005f6c:	f6840593          	addi	a1,s0,-152
    80005f70:	4509                	li	a0,2
    80005f72:	ffffd097          	auipc	ra,0xffffd
    80005f76:	08c080e7          	jalr	140(ra) # 80002ffe <argint>
     argint(1, &major) < 0 ||
    80005f7a:	02054863          	bltz	a0,80005faa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f7e:	f6841683          	lh	a3,-152(s0)
    80005f82:	f6c41603          	lh	a2,-148(s0)
    80005f86:	458d                	li	a1,3
    80005f88:	f7040513          	addi	a0,s0,-144
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	776080e7          	jalr	1910(ra) # 80005702 <create>
     argint(2, &minor) < 0 ||
    80005f94:	c919                	beqz	a0,80005faa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	09c080e7          	jalr	156(ra) # 80004032 <iunlockput>
  end_op();
    80005f9e:	fffff097          	auipc	ra,0xfffff
    80005fa2:	884080e7          	jalr	-1916(ra) # 80004822 <end_op>
  return 0;
    80005fa6:	4501                	li	a0,0
    80005fa8:	a031                	j	80005fb4 <sys_mknod+0x80>
    end_op();
    80005faa:	fffff097          	auipc	ra,0xfffff
    80005fae:	878080e7          	jalr	-1928(ra) # 80004822 <end_op>
    return -1;
    80005fb2:	557d                	li	a0,-1
}
    80005fb4:	60ea                	ld	ra,152(sp)
    80005fb6:	644a                	ld	s0,144(sp)
    80005fb8:	610d                	addi	sp,sp,160
    80005fba:	8082                	ret

0000000080005fbc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fbc:	7135                	addi	sp,sp,-160
    80005fbe:	ed06                	sd	ra,152(sp)
    80005fc0:	e922                	sd	s0,144(sp)
    80005fc2:	e526                	sd	s1,136(sp)
    80005fc4:	e14a                	sd	s2,128(sp)
    80005fc6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	b76080e7          	jalr	-1162(ra) # 80001b3e <myproc>
    80005fd0:	892a                	mv	s2,a0
  
  begin_op();
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	7d0080e7          	jalr	2000(ra) # 800047a2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fda:	08000613          	li	a2,128
    80005fde:	f6040593          	addi	a1,s0,-160
    80005fe2:	4501                	li	a0,0
    80005fe4:	ffffd097          	auipc	ra,0xffffd
    80005fe8:	05e080e7          	jalr	94(ra) # 80003042 <argstr>
    80005fec:	04054b63          	bltz	a0,80006042 <sys_chdir+0x86>
    80005ff0:	f6040513          	addi	a0,s0,-160
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	592080e7          	jalr	1426(ra) # 80004586 <namei>
    80005ffc:	84aa                	mv	s1,a0
    80005ffe:	c131                	beqz	a0,80006042 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	dd0080e7          	jalr	-560(ra) # 80003dd0 <ilock>
  if(ip->type != T_DIR){
    80006008:	04449703          	lh	a4,68(s1)
    8000600c:	4785                	li	a5,1
    8000600e:	04f71063          	bne	a4,a5,8000604e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006012:	8526                	mv	a0,s1
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	e7e080e7          	jalr	-386(ra) # 80003e92 <iunlock>
  iput(p->cwd);
    8000601c:	15093503          	ld	a0,336(s2)
    80006020:	ffffe097          	auipc	ra,0xffffe
    80006024:	f6a080e7          	jalr	-150(ra) # 80003f8a <iput>
  end_op();
    80006028:	ffffe097          	auipc	ra,0xffffe
    8000602c:	7fa080e7          	jalr	2042(ra) # 80004822 <end_op>
  p->cwd = ip;
    80006030:	14993823          	sd	s1,336(s2)
  return 0;
    80006034:	4501                	li	a0,0
}
    80006036:	60ea                	ld	ra,152(sp)
    80006038:	644a                	ld	s0,144(sp)
    8000603a:	64aa                	ld	s1,136(sp)
    8000603c:	690a                	ld	s2,128(sp)
    8000603e:	610d                	addi	sp,sp,160
    80006040:	8082                	ret
    end_op();
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	7e0080e7          	jalr	2016(ra) # 80004822 <end_op>
    return -1;
    8000604a:	557d                	li	a0,-1
    8000604c:	b7ed                	j	80006036 <sys_chdir+0x7a>
    iunlockput(ip);
    8000604e:	8526                	mv	a0,s1
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	fe2080e7          	jalr	-30(ra) # 80004032 <iunlockput>
    end_op();
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	7ca080e7          	jalr	1994(ra) # 80004822 <end_op>
    return -1;
    80006060:	557d                	li	a0,-1
    80006062:	bfd1                	j	80006036 <sys_chdir+0x7a>

0000000080006064 <sys_exec>:

uint64
sys_exec(void)
{
    80006064:	7145                	addi	sp,sp,-464
    80006066:	e786                	sd	ra,456(sp)
    80006068:	e3a2                	sd	s0,448(sp)
    8000606a:	ff26                	sd	s1,440(sp)
    8000606c:	fb4a                	sd	s2,432(sp)
    8000606e:	f74e                	sd	s3,424(sp)
    80006070:	f352                	sd	s4,416(sp)
    80006072:	ef56                	sd	s5,408(sp)
    80006074:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006076:	08000613          	li	a2,128
    8000607a:	f4040593          	addi	a1,s0,-192
    8000607e:	4501                	li	a0,0
    80006080:	ffffd097          	auipc	ra,0xffffd
    80006084:	fc2080e7          	jalr	-62(ra) # 80003042 <argstr>
    return -1;
    80006088:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000608a:	0c054a63          	bltz	a0,8000615e <sys_exec+0xfa>
    8000608e:	e3840593          	addi	a1,s0,-456
    80006092:	4505                	li	a0,1
    80006094:	ffffd097          	auipc	ra,0xffffd
    80006098:	f8c080e7          	jalr	-116(ra) # 80003020 <argaddr>
    8000609c:	0c054163          	bltz	a0,8000615e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060a0:	10000613          	li	a2,256
    800060a4:	4581                	li	a1,0
    800060a6:	e4040513          	addi	a0,s0,-448
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	c36080e7          	jalr	-970(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060b2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060b6:	89a6                	mv	s3,s1
    800060b8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060ba:	02000a13          	li	s4,32
    800060be:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060c2:	00391513          	slli	a0,s2,0x3
    800060c6:	e3040593          	addi	a1,s0,-464
    800060ca:	e3843783          	ld	a5,-456(s0)
    800060ce:	953e                	add	a0,a0,a5
    800060d0:	ffffd097          	auipc	ra,0xffffd
    800060d4:	e94080e7          	jalr	-364(ra) # 80002f64 <fetchaddr>
    800060d8:	02054a63          	bltz	a0,8000610c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800060dc:	e3043783          	ld	a5,-464(s0)
    800060e0:	c3b9                	beqz	a5,80006126 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	a12080e7          	jalr	-1518(ra) # 80000af4 <kalloc>
    800060ea:	85aa                	mv	a1,a0
    800060ec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060f0:	cd11                	beqz	a0,8000610c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060f2:	6605                	lui	a2,0x1
    800060f4:	e3043503          	ld	a0,-464(s0)
    800060f8:	ffffd097          	auipc	ra,0xffffd
    800060fc:	ebe080e7          	jalr	-322(ra) # 80002fb6 <fetchstr>
    80006100:	00054663          	bltz	a0,8000610c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006104:	0905                	addi	s2,s2,1
    80006106:	09a1                	addi	s3,s3,8
    80006108:	fb491be3          	bne	s2,s4,800060be <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000610c:	10048913          	addi	s2,s1,256
    80006110:	6088                	ld	a0,0(s1)
    80006112:	c529                	beqz	a0,8000615c <sys_exec+0xf8>
    kfree(argv[i]);
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	8e4080e7          	jalr	-1820(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000611c:	04a1                	addi	s1,s1,8
    8000611e:	ff2499e3          	bne	s1,s2,80006110 <sys_exec+0xac>
  return -1;
    80006122:	597d                	li	s2,-1
    80006124:	a82d                	j	8000615e <sys_exec+0xfa>
      argv[i] = 0;
    80006126:	0a8e                	slli	s5,s5,0x3
    80006128:	fc040793          	addi	a5,s0,-64
    8000612c:	9abe                	add	s5,s5,a5
    8000612e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006132:	e4040593          	addi	a1,s0,-448
    80006136:	f4040513          	addi	a0,s0,-192
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	194080e7          	jalr	404(ra) # 800052ce <exec>
    80006142:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006144:	10048993          	addi	s3,s1,256
    80006148:	6088                	ld	a0,0(s1)
    8000614a:	c911                	beqz	a0,8000615e <sys_exec+0xfa>
    kfree(argv[i]);
    8000614c:	ffffb097          	auipc	ra,0xffffb
    80006150:	8ac080e7          	jalr	-1876(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006154:	04a1                	addi	s1,s1,8
    80006156:	ff3499e3          	bne	s1,s3,80006148 <sys_exec+0xe4>
    8000615a:	a011                	j	8000615e <sys_exec+0xfa>
  return -1;
    8000615c:	597d                	li	s2,-1
}
    8000615e:	854a                	mv	a0,s2
    80006160:	60be                	ld	ra,456(sp)
    80006162:	641e                	ld	s0,448(sp)
    80006164:	74fa                	ld	s1,440(sp)
    80006166:	795a                	ld	s2,432(sp)
    80006168:	79ba                	ld	s3,424(sp)
    8000616a:	7a1a                	ld	s4,416(sp)
    8000616c:	6afa                	ld	s5,408(sp)
    8000616e:	6179                	addi	sp,sp,464
    80006170:	8082                	ret

0000000080006172 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006172:	7139                	addi	sp,sp,-64
    80006174:	fc06                	sd	ra,56(sp)
    80006176:	f822                	sd	s0,48(sp)
    80006178:	f426                	sd	s1,40(sp)
    8000617a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000617c:	ffffc097          	auipc	ra,0xffffc
    80006180:	9c2080e7          	jalr	-1598(ra) # 80001b3e <myproc>
    80006184:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006186:	fd840593          	addi	a1,s0,-40
    8000618a:	4501                	li	a0,0
    8000618c:	ffffd097          	auipc	ra,0xffffd
    80006190:	e94080e7          	jalr	-364(ra) # 80003020 <argaddr>
    return -1;
    80006194:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006196:	0e054063          	bltz	a0,80006276 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000619a:	fc840593          	addi	a1,s0,-56
    8000619e:	fd040513          	addi	a0,s0,-48
    800061a2:	fffff097          	auipc	ra,0xfffff
    800061a6:	dfc080e7          	jalr	-516(ra) # 80004f9e <pipealloc>
    return -1;
    800061aa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061ac:	0c054563          	bltz	a0,80006276 <sys_pipe+0x104>
  fd0 = -1;
    800061b0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061b4:	fd043503          	ld	a0,-48(s0)
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	508080e7          	jalr	1288(ra) # 800056c0 <fdalloc>
    800061c0:	fca42223          	sw	a0,-60(s0)
    800061c4:	08054c63          	bltz	a0,8000625c <sys_pipe+0xea>
    800061c8:	fc843503          	ld	a0,-56(s0)
    800061cc:	fffff097          	auipc	ra,0xfffff
    800061d0:	4f4080e7          	jalr	1268(ra) # 800056c0 <fdalloc>
    800061d4:	fca42023          	sw	a0,-64(s0)
    800061d8:	06054863          	bltz	a0,80006248 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061dc:	4691                	li	a3,4
    800061de:	fc440613          	addi	a2,s0,-60
    800061e2:	fd843583          	ld	a1,-40(s0)
    800061e6:	68a8                	ld	a0,80(s1)
    800061e8:	ffffb097          	auipc	ra,0xffffb
    800061ec:	48a080e7          	jalr	1162(ra) # 80001672 <copyout>
    800061f0:	02054063          	bltz	a0,80006210 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061f4:	4691                	li	a3,4
    800061f6:	fc040613          	addi	a2,s0,-64
    800061fa:	fd843583          	ld	a1,-40(s0)
    800061fe:	0591                	addi	a1,a1,4
    80006200:	68a8                	ld	a0,80(s1)
    80006202:	ffffb097          	auipc	ra,0xffffb
    80006206:	470080e7          	jalr	1136(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000620a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000620c:	06055563          	bgez	a0,80006276 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006210:	fc442783          	lw	a5,-60(s0)
    80006214:	07e9                	addi	a5,a5,26
    80006216:	078e                	slli	a5,a5,0x3
    80006218:	97a6                	add	a5,a5,s1
    8000621a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000621e:	fc042503          	lw	a0,-64(s0)
    80006222:	0569                	addi	a0,a0,26
    80006224:	050e                	slli	a0,a0,0x3
    80006226:	9526                	add	a0,a0,s1
    80006228:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000622c:	fd043503          	ld	a0,-48(s0)
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	a3e080e7          	jalr	-1474(ra) # 80004c6e <fileclose>
    fileclose(wf);
    80006238:	fc843503          	ld	a0,-56(s0)
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	a32080e7          	jalr	-1486(ra) # 80004c6e <fileclose>
    return -1;
    80006244:	57fd                	li	a5,-1
    80006246:	a805                	j	80006276 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006248:	fc442783          	lw	a5,-60(s0)
    8000624c:	0007c863          	bltz	a5,8000625c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006250:	01a78513          	addi	a0,a5,26
    80006254:	050e                	slli	a0,a0,0x3
    80006256:	9526                	add	a0,a0,s1
    80006258:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000625c:	fd043503          	ld	a0,-48(s0)
    80006260:	fffff097          	auipc	ra,0xfffff
    80006264:	a0e080e7          	jalr	-1522(ra) # 80004c6e <fileclose>
    fileclose(wf);
    80006268:	fc843503          	ld	a0,-56(s0)
    8000626c:	fffff097          	auipc	ra,0xfffff
    80006270:	a02080e7          	jalr	-1534(ra) # 80004c6e <fileclose>
    return -1;
    80006274:	57fd                	li	a5,-1
}
    80006276:	853e                	mv	a0,a5
    80006278:	70e2                	ld	ra,56(sp)
    8000627a:	7442                	ld	s0,48(sp)
    8000627c:	74a2                	ld	s1,40(sp)
    8000627e:	6121                	addi	sp,sp,64
    80006280:	8082                	ret
	...

0000000080006290 <kernelvec>:
    80006290:	7111                	addi	sp,sp,-256
    80006292:	e006                	sd	ra,0(sp)
    80006294:	e40a                	sd	sp,8(sp)
    80006296:	e80e                	sd	gp,16(sp)
    80006298:	ec12                	sd	tp,24(sp)
    8000629a:	f016                	sd	t0,32(sp)
    8000629c:	f41a                	sd	t1,40(sp)
    8000629e:	f81e                	sd	t2,48(sp)
    800062a0:	fc22                	sd	s0,56(sp)
    800062a2:	e0a6                	sd	s1,64(sp)
    800062a4:	e4aa                	sd	a0,72(sp)
    800062a6:	e8ae                	sd	a1,80(sp)
    800062a8:	ecb2                	sd	a2,88(sp)
    800062aa:	f0b6                	sd	a3,96(sp)
    800062ac:	f4ba                	sd	a4,104(sp)
    800062ae:	f8be                	sd	a5,112(sp)
    800062b0:	fcc2                	sd	a6,120(sp)
    800062b2:	e146                	sd	a7,128(sp)
    800062b4:	e54a                	sd	s2,136(sp)
    800062b6:	e94e                	sd	s3,144(sp)
    800062b8:	ed52                	sd	s4,152(sp)
    800062ba:	f156                	sd	s5,160(sp)
    800062bc:	f55a                	sd	s6,168(sp)
    800062be:	f95e                	sd	s7,176(sp)
    800062c0:	fd62                	sd	s8,184(sp)
    800062c2:	e1e6                	sd	s9,192(sp)
    800062c4:	e5ea                	sd	s10,200(sp)
    800062c6:	e9ee                	sd	s11,208(sp)
    800062c8:	edf2                	sd	t3,216(sp)
    800062ca:	f1f6                	sd	t4,224(sp)
    800062cc:	f5fa                	sd	t5,232(sp)
    800062ce:	f9fe                	sd	t6,240(sp)
    800062d0:	b61fc0ef          	jal	ra,80002e30 <kerneltrap>
    800062d4:	6082                	ld	ra,0(sp)
    800062d6:	6122                	ld	sp,8(sp)
    800062d8:	61c2                	ld	gp,16(sp)
    800062da:	7282                	ld	t0,32(sp)
    800062dc:	7322                	ld	t1,40(sp)
    800062de:	73c2                	ld	t2,48(sp)
    800062e0:	7462                	ld	s0,56(sp)
    800062e2:	6486                	ld	s1,64(sp)
    800062e4:	6526                	ld	a0,72(sp)
    800062e6:	65c6                	ld	a1,80(sp)
    800062e8:	6666                	ld	a2,88(sp)
    800062ea:	7686                	ld	a3,96(sp)
    800062ec:	7726                	ld	a4,104(sp)
    800062ee:	77c6                	ld	a5,112(sp)
    800062f0:	7866                	ld	a6,120(sp)
    800062f2:	688a                	ld	a7,128(sp)
    800062f4:	692a                	ld	s2,136(sp)
    800062f6:	69ca                	ld	s3,144(sp)
    800062f8:	6a6a                	ld	s4,152(sp)
    800062fa:	7a8a                	ld	s5,160(sp)
    800062fc:	7b2a                	ld	s6,168(sp)
    800062fe:	7bca                	ld	s7,176(sp)
    80006300:	7c6a                	ld	s8,184(sp)
    80006302:	6c8e                	ld	s9,192(sp)
    80006304:	6d2e                	ld	s10,200(sp)
    80006306:	6dce                	ld	s11,208(sp)
    80006308:	6e6e                	ld	t3,216(sp)
    8000630a:	7e8e                	ld	t4,224(sp)
    8000630c:	7f2e                	ld	t5,232(sp)
    8000630e:	7fce                	ld	t6,240(sp)
    80006310:	6111                	addi	sp,sp,256
    80006312:	10200073          	sret
    80006316:	00000013          	nop
    8000631a:	00000013          	nop
    8000631e:	0001                	nop

0000000080006320 <timervec>:
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	e10c                	sd	a1,0(a0)
    80006326:	e510                	sd	a2,8(a0)
    80006328:	e914                	sd	a3,16(a0)
    8000632a:	6d0c                	ld	a1,24(a0)
    8000632c:	7110                	ld	a2,32(a0)
    8000632e:	6194                	ld	a3,0(a1)
    80006330:	96b2                	add	a3,a3,a2
    80006332:	e194                	sd	a3,0(a1)
    80006334:	4589                	li	a1,2
    80006336:	14459073          	csrw	sip,a1
    8000633a:	6914                	ld	a3,16(a0)
    8000633c:	6510                	ld	a2,8(a0)
    8000633e:	610c                	ld	a1,0(a0)
    80006340:	34051573          	csrrw	a0,mscratch,a0
    80006344:	30200073          	mret
	...

000000008000634a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000634a:	1141                	addi	sp,sp,-16
    8000634c:	e422                	sd	s0,8(sp)
    8000634e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006350:	0c0007b7          	lui	a5,0xc000
    80006354:	4705                	li	a4,1
    80006356:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006358:	c3d8                	sw	a4,4(a5)
}
    8000635a:	6422                	ld	s0,8(sp)
    8000635c:	0141                	addi	sp,sp,16
    8000635e:	8082                	ret

0000000080006360 <plicinithart>:

void
plicinithart(void)
{
    80006360:	1141                	addi	sp,sp,-16
    80006362:	e406                	sd	ra,8(sp)
    80006364:	e022                	sd	s0,0(sp)
    80006366:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006368:	ffffb097          	auipc	ra,0xffffb
    8000636c:	7aa080e7          	jalr	1962(ra) # 80001b12 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006370:	0085171b          	slliw	a4,a0,0x8
    80006374:	0c0027b7          	lui	a5,0xc002
    80006378:	97ba                	add	a5,a5,a4
    8000637a:	40200713          	li	a4,1026
    8000637e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006382:	00d5151b          	slliw	a0,a0,0xd
    80006386:	0c2017b7          	lui	a5,0xc201
    8000638a:	953e                	add	a0,a0,a5
    8000638c:	00052023          	sw	zero,0(a0)
}
    80006390:	60a2                	ld	ra,8(sp)
    80006392:	6402                	ld	s0,0(sp)
    80006394:	0141                	addi	sp,sp,16
    80006396:	8082                	ret

0000000080006398 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006398:	1141                	addi	sp,sp,-16
    8000639a:	e406                	sd	ra,8(sp)
    8000639c:	e022                	sd	s0,0(sp)
    8000639e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	772080e7          	jalr	1906(ra) # 80001b12 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063a8:	00d5179b          	slliw	a5,a0,0xd
    800063ac:	0c201537          	lui	a0,0xc201
    800063b0:	953e                	add	a0,a0,a5
  return irq;
}
    800063b2:	4148                	lw	a0,4(a0)
    800063b4:	60a2                	ld	ra,8(sp)
    800063b6:	6402                	ld	s0,0(sp)
    800063b8:	0141                	addi	sp,sp,16
    800063ba:	8082                	ret

00000000800063bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063bc:	1101                	addi	sp,sp,-32
    800063be:	ec06                	sd	ra,24(sp)
    800063c0:	e822                	sd	s0,16(sp)
    800063c2:	e426                	sd	s1,8(sp)
    800063c4:	1000                	addi	s0,sp,32
    800063c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063c8:	ffffb097          	auipc	ra,0xffffb
    800063cc:	74a080e7          	jalr	1866(ra) # 80001b12 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063d0:	00d5151b          	slliw	a0,a0,0xd
    800063d4:	0c2017b7          	lui	a5,0xc201
    800063d8:	97aa                	add	a5,a5,a0
    800063da:	c3c4                	sw	s1,4(a5)
}
    800063dc:	60e2                	ld	ra,24(sp)
    800063de:	6442                	ld	s0,16(sp)
    800063e0:	64a2                	ld	s1,8(sp)
    800063e2:	6105                	addi	sp,sp,32
    800063e4:	8082                	ret

00000000800063e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063e6:	1141                	addi	sp,sp,-16
    800063e8:	e406                	sd	ra,8(sp)
    800063ea:	e022                	sd	s0,0(sp)
    800063ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ee:	479d                	li	a5,7
    800063f0:	06a7c963          	blt	a5,a0,80006462 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800063f4:	0001f797          	auipc	a5,0x1f
    800063f8:	c0c78793          	addi	a5,a5,-1012 # 80025000 <disk>
    800063fc:	00a78733          	add	a4,a5,a0
    80006400:	6789                	lui	a5,0x2
    80006402:	97ba                	add	a5,a5,a4
    80006404:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006408:	e7ad                	bnez	a5,80006472 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000640a:	00451793          	slli	a5,a0,0x4
    8000640e:	00021717          	auipc	a4,0x21
    80006412:	bf270713          	addi	a4,a4,-1038 # 80027000 <disk+0x2000>
    80006416:	6314                	ld	a3,0(a4)
    80006418:	96be                	add	a3,a3,a5
    8000641a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000641e:	6314                	ld	a3,0(a4)
    80006420:	96be                	add	a3,a3,a5
    80006422:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006426:	6314                	ld	a3,0(a4)
    80006428:	96be                	add	a3,a3,a5
    8000642a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000642e:	6318                	ld	a4,0(a4)
    80006430:	97ba                	add	a5,a5,a4
    80006432:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006436:	0001f797          	auipc	a5,0x1f
    8000643a:	bca78793          	addi	a5,a5,-1078 # 80025000 <disk>
    8000643e:	97aa                	add	a5,a5,a0
    80006440:	6509                	lui	a0,0x2
    80006442:	953e                	add	a0,a0,a5
    80006444:	4785                	li	a5,1
    80006446:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000644a:	00021517          	auipc	a0,0x21
    8000644e:	bce50513          	addi	a0,a0,-1074 # 80027018 <disk+0x2018>
    80006452:	ffffc097          	auipc	ra,0xffffc
    80006456:	fb8080e7          	jalr	-72(ra) # 8000240a <wakeup>
}
    8000645a:	60a2                	ld	ra,8(sp)
    8000645c:	6402                	ld	s0,0(sp)
    8000645e:	0141                	addi	sp,sp,16
    80006460:	8082                	ret
    panic("free_desc 1");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	50650513          	addi	a0,a0,1286 # 80008968 <syscalls+0x330>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d4080e7          	jalr	212(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	50650513          	addi	a0,a0,1286 # 80008978 <syscalls+0x340>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>

0000000080006482 <virtio_disk_init>:
{
    80006482:	1101                	addi	sp,sp,-32
    80006484:	ec06                	sd	ra,24(sp)
    80006486:	e822                	sd	s0,16(sp)
    80006488:	e426                	sd	s1,8(sp)
    8000648a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000648c:	00002597          	auipc	a1,0x2
    80006490:	4fc58593          	addi	a1,a1,1276 # 80008988 <syscalls+0x350>
    80006494:	00021517          	auipc	a0,0x21
    80006498:	c9450513          	addi	a0,a0,-876 # 80027128 <disk+0x2128>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	6b8080e7          	jalr	1720(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a4:	100017b7          	lui	a5,0x10001
    800064a8:	4398                	lw	a4,0(a5)
    800064aa:	2701                	sext.w	a4,a4
    800064ac:	747277b7          	lui	a5,0x74727
    800064b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800064b4:	0ef71163          	bne	a4,a5,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064b8:	100017b7          	lui	a5,0x10001
    800064bc:	43dc                	lw	a5,4(a5)
    800064be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064c0:	4705                	li	a4,1
    800064c2:	0ce79a63          	bne	a5,a4,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064c6:	100017b7          	lui	a5,0x10001
    800064ca:	479c                	lw	a5,8(a5)
    800064cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800064ce:	4709                	li	a4,2
    800064d0:	0ce79363          	bne	a5,a4,80006596 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064d4:	100017b7          	lui	a5,0x10001
    800064d8:	47d8                	lw	a4,12(a5)
    800064da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064dc:	554d47b7          	lui	a5,0x554d4
    800064e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064e4:	0af71963          	bne	a4,a5,80006596 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064e8:	100017b7          	lui	a5,0x10001
    800064ec:	4705                	li	a4,1
    800064ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064f0:	470d                	li	a4,3
    800064f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064f6:	c7ffe737          	lui	a4,0xc7ffe
    800064fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd675f>
    800064fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006500:	2701                	sext.w	a4,a4
    80006502:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006504:	472d                	li	a4,11
    80006506:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006508:	473d                	li	a4,15
    8000650a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000650c:	6705                	lui	a4,0x1
    8000650e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006510:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006514:	5bdc                	lw	a5,52(a5)
    80006516:	2781                	sext.w	a5,a5
  if(max == 0)
    80006518:	c7d9                	beqz	a5,800065a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000651a:	471d                	li	a4,7
    8000651c:	08f77d63          	bgeu	a4,a5,800065b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006520:	100014b7          	lui	s1,0x10001
    80006524:	47a1                	li	a5,8
    80006526:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006528:	6609                	lui	a2,0x2
    8000652a:	4581                	li	a1,0
    8000652c:	0001f517          	auipc	a0,0x1f
    80006530:	ad450513          	addi	a0,a0,-1324 # 80025000 <disk>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	7ac080e7          	jalr	1964(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000653c:	0001f717          	auipc	a4,0x1f
    80006540:	ac470713          	addi	a4,a4,-1340 # 80025000 <disk>
    80006544:	00c75793          	srli	a5,a4,0xc
    80006548:	2781                	sext.w	a5,a5
    8000654a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000654c:	00021797          	auipc	a5,0x21
    80006550:	ab478793          	addi	a5,a5,-1356 # 80027000 <disk+0x2000>
    80006554:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006556:	0001f717          	auipc	a4,0x1f
    8000655a:	b2a70713          	addi	a4,a4,-1238 # 80025080 <disk+0x80>
    8000655e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006560:	00020717          	auipc	a4,0x20
    80006564:	aa070713          	addi	a4,a4,-1376 # 80026000 <disk+0x1000>
    80006568:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000656a:	4705                	li	a4,1
    8000656c:	00e78c23          	sb	a4,24(a5)
    80006570:	00e78ca3          	sb	a4,25(a5)
    80006574:	00e78d23          	sb	a4,26(a5)
    80006578:	00e78da3          	sb	a4,27(a5)
    8000657c:	00e78e23          	sb	a4,28(a5)
    80006580:	00e78ea3          	sb	a4,29(a5)
    80006584:	00e78f23          	sb	a4,30(a5)
    80006588:	00e78fa3          	sb	a4,31(a5)
}
    8000658c:	60e2                	ld	ra,24(sp)
    8000658e:	6442                	ld	s0,16(sp)
    80006590:	64a2                	ld	s1,8(sp)
    80006592:	6105                	addi	sp,sp,32
    80006594:	8082                	ret
    panic("could not find virtio disk");
    80006596:	00002517          	auipc	a0,0x2
    8000659a:	40250513          	addi	a0,a0,1026 # 80008998 <syscalls+0x360>
    8000659e:	ffffa097          	auipc	ra,0xffffa
    800065a2:	fa0080e7          	jalr	-96(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800065a6:	00002517          	auipc	a0,0x2
    800065aa:	41250513          	addi	a0,a0,1042 # 800089b8 <syscalls+0x380>
    800065ae:	ffffa097          	auipc	ra,0xffffa
    800065b2:	f90080e7          	jalr	-112(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800065b6:	00002517          	auipc	a0,0x2
    800065ba:	42250513          	addi	a0,a0,1058 # 800089d8 <syscalls+0x3a0>
    800065be:	ffffa097          	auipc	ra,0xffffa
    800065c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>

00000000800065c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800065c6:	7159                	addi	sp,sp,-112
    800065c8:	f486                	sd	ra,104(sp)
    800065ca:	f0a2                	sd	s0,96(sp)
    800065cc:	eca6                	sd	s1,88(sp)
    800065ce:	e8ca                	sd	s2,80(sp)
    800065d0:	e4ce                	sd	s3,72(sp)
    800065d2:	e0d2                	sd	s4,64(sp)
    800065d4:	fc56                	sd	s5,56(sp)
    800065d6:	f85a                	sd	s6,48(sp)
    800065d8:	f45e                	sd	s7,40(sp)
    800065da:	f062                	sd	s8,32(sp)
    800065dc:	ec66                	sd	s9,24(sp)
    800065de:	e86a                	sd	s10,16(sp)
    800065e0:	1880                	addi	s0,sp,112
    800065e2:	892a                	mv	s2,a0
    800065e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800065e6:	00c52c83          	lw	s9,12(a0)
    800065ea:	001c9c9b          	slliw	s9,s9,0x1
    800065ee:	1c82                	slli	s9,s9,0x20
    800065f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800065f4:	00021517          	auipc	a0,0x21
    800065f8:	b3450513          	addi	a0,a0,-1228 # 80027128 <disk+0x2128>
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	5e8080e7          	jalr	1512(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006604:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006606:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006608:	0001fb97          	auipc	s7,0x1f
    8000660c:	9f8b8b93          	addi	s7,s7,-1544 # 80025000 <disk>
    80006610:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006612:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006614:	8a4e                	mv	s4,s3
    80006616:	a051                	j	8000669a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006618:	00fb86b3          	add	a3,s7,a5
    8000661c:	96da                	add	a3,a3,s6
    8000661e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006622:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006624:	0207c563          	bltz	a5,8000664e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006628:	2485                	addiw	s1,s1,1
    8000662a:	0711                	addi	a4,a4,4
    8000662c:	25548063          	beq	s1,s5,8000686c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006630:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006632:	00021697          	auipc	a3,0x21
    80006636:	9e668693          	addi	a3,a3,-1562 # 80027018 <disk+0x2018>
    8000663a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000663c:	0006c583          	lbu	a1,0(a3)
    80006640:	fde1                	bnez	a1,80006618 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006642:	2785                	addiw	a5,a5,1
    80006644:	0685                	addi	a3,a3,1
    80006646:	ff879be3          	bne	a5,s8,8000663c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000664a:	57fd                	li	a5,-1
    8000664c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000664e:	02905a63          	blez	s1,80006682 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006652:	f9042503          	lw	a0,-112(s0)
    80006656:	00000097          	auipc	ra,0x0
    8000665a:	d90080e7          	jalr	-624(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000665e:	4785                	li	a5,1
    80006660:	0297d163          	bge	a5,s1,80006682 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006664:	f9442503          	lw	a0,-108(s0)
    80006668:	00000097          	auipc	ra,0x0
    8000666c:	d7e080e7          	jalr	-642(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006670:	4789                	li	a5,2
    80006672:	0097d863          	bge	a5,s1,80006682 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006676:	f9842503          	lw	a0,-104(s0)
    8000667a:	00000097          	auipc	ra,0x0
    8000667e:	d6c080e7          	jalr	-660(ra) # 800063e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006682:	00021597          	auipc	a1,0x21
    80006686:	aa658593          	addi	a1,a1,-1370 # 80027128 <disk+0x2128>
    8000668a:	00021517          	auipc	a0,0x21
    8000668e:	98e50513          	addi	a0,a0,-1650 # 80027018 <disk+0x2018>
    80006692:	ffffc097          	auipc	ra,0xffffc
    80006696:	bec080e7          	jalr	-1044(ra) # 8000227e <sleep>
  for(int i = 0; i < 3; i++){
    8000669a:	f9040713          	addi	a4,s0,-112
    8000669e:	84ce                	mv	s1,s3
    800066a0:	bf41                	j	80006630 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800066a2:	20058713          	addi	a4,a1,512
    800066a6:	00471693          	slli	a3,a4,0x4
    800066aa:	0001f717          	auipc	a4,0x1f
    800066ae:	95670713          	addi	a4,a4,-1706 # 80025000 <disk>
    800066b2:	9736                	add	a4,a4,a3
    800066b4:	4685                	li	a3,1
    800066b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066ba:	20058713          	addi	a4,a1,512
    800066be:	00471693          	slli	a3,a4,0x4
    800066c2:	0001f717          	auipc	a4,0x1f
    800066c6:	93e70713          	addi	a4,a4,-1730 # 80025000 <disk>
    800066ca:	9736                	add	a4,a4,a3
    800066cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800066d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066d4:	7679                	lui	a2,0xffffe
    800066d6:	963e                	add	a2,a2,a5
    800066d8:	00021697          	auipc	a3,0x21
    800066dc:	92868693          	addi	a3,a3,-1752 # 80027000 <disk+0x2000>
    800066e0:	6298                	ld	a4,0(a3)
    800066e2:	9732                	add	a4,a4,a2
    800066e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066e6:	6298                	ld	a4,0(a3)
    800066e8:	9732                	add	a4,a4,a2
    800066ea:	4541                	li	a0,16
    800066ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800066ee:	6298                	ld	a4,0(a3)
    800066f0:	9732                	add	a4,a4,a2
    800066f2:	4505                	li	a0,1
    800066f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800066f8:	f9442703          	lw	a4,-108(s0)
    800066fc:	6288                	ld	a0,0(a3)
    800066fe:	962a                	add	a2,a2,a0
    80006700:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd600e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006704:	0712                	slli	a4,a4,0x4
    80006706:	6290                	ld	a2,0(a3)
    80006708:	963a                	add	a2,a2,a4
    8000670a:	05890513          	addi	a0,s2,88
    8000670e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006710:	6294                	ld	a3,0(a3)
    80006712:	96ba                	add	a3,a3,a4
    80006714:	40000613          	li	a2,1024
    80006718:	c690                	sw	a2,8(a3)
  if(write)
    8000671a:	140d0063          	beqz	s10,8000685a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000671e:	00021697          	auipc	a3,0x21
    80006722:	8e26b683          	ld	a3,-1822(a3) # 80027000 <disk+0x2000>
    80006726:	96ba                	add	a3,a3,a4
    80006728:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000672c:	0001f817          	auipc	a6,0x1f
    80006730:	8d480813          	addi	a6,a6,-1836 # 80025000 <disk>
    80006734:	00021517          	auipc	a0,0x21
    80006738:	8cc50513          	addi	a0,a0,-1844 # 80027000 <disk+0x2000>
    8000673c:	6114                	ld	a3,0(a0)
    8000673e:	96ba                	add	a3,a3,a4
    80006740:	00c6d603          	lhu	a2,12(a3)
    80006744:	00166613          	ori	a2,a2,1
    80006748:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000674c:	f9842683          	lw	a3,-104(s0)
    80006750:	6110                	ld	a2,0(a0)
    80006752:	9732                	add	a4,a4,a2
    80006754:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006758:	20058613          	addi	a2,a1,512
    8000675c:	0612                	slli	a2,a2,0x4
    8000675e:	9642                	add	a2,a2,a6
    80006760:	577d                	li	a4,-1
    80006762:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006766:	00469713          	slli	a4,a3,0x4
    8000676a:	6114                	ld	a3,0(a0)
    8000676c:	96ba                	add	a3,a3,a4
    8000676e:	03078793          	addi	a5,a5,48
    80006772:	97c2                	add	a5,a5,a6
    80006774:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006776:	611c                	ld	a5,0(a0)
    80006778:	97ba                	add	a5,a5,a4
    8000677a:	4685                	li	a3,1
    8000677c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000677e:	611c                	ld	a5,0(a0)
    80006780:	97ba                	add	a5,a5,a4
    80006782:	4809                	li	a6,2
    80006784:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006788:	611c                	ld	a5,0(a0)
    8000678a:	973e                	add	a4,a4,a5
    8000678c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006790:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006794:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006798:	6518                	ld	a4,8(a0)
    8000679a:	00275783          	lhu	a5,2(a4)
    8000679e:	8b9d                	andi	a5,a5,7
    800067a0:	0786                	slli	a5,a5,0x1
    800067a2:	97ba                	add	a5,a5,a4
    800067a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067ac:	6518                	ld	a4,8(a0)
    800067ae:	00275783          	lhu	a5,2(a4)
    800067b2:	2785                	addiw	a5,a5,1
    800067b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067bc:	100017b7          	lui	a5,0x10001
    800067c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067c4:	00492703          	lw	a4,4(s2)
    800067c8:	4785                	li	a5,1
    800067ca:	02f71163          	bne	a4,a5,800067ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800067ce:	00021997          	auipc	s3,0x21
    800067d2:	95a98993          	addi	s3,s3,-1702 # 80027128 <disk+0x2128>
  while(b->disk == 1) {
    800067d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800067d8:	85ce                	mv	a1,s3
    800067da:	854a                	mv	a0,s2
    800067dc:	ffffc097          	auipc	ra,0xffffc
    800067e0:	aa2080e7          	jalr	-1374(ra) # 8000227e <sleep>
  while(b->disk == 1) {
    800067e4:	00492783          	lw	a5,4(s2)
    800067e8:	fe9788e3          	beq	a5,s1,800067d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800067ec:	f9042903          	lw	s2,-112(s0)
    800067f0:	20090793          	addi	a5,s2,512
    800067f4:	00479713          	slli	a4,a5,0x4
    800067f8:	0001f797          	auipc	a5,0x1f
    800067fc:	80878793          	addi	a5,a5,-2040 # 80025000 <disk>
    80006800:	97ba                	add	a5,a5,a4
    80006802:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006806:	00020997          	auipc	s3,0x20
    8000680a:	7fa98993          	addi	s3,s3,2042 # 80027000 <disk+0x2000>
    8000680e:	00491713          	slli	a4,s2,0x4
    80006812:	0009b783          	ld	a5,0(s3)
    80006816:	97ba                	add	a5,a5,a4
    80006818:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000681c:	854a                	mv	a0,s2
    8000681e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006822:	00000097          	auipc	ra,0x0
    80006826:	bc4080e7          	jalr	-1084(ra) # 800063e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000682a:	8885                	andi	s1,s1,1
    8000682c:	f0ed                	bnez	s1,8000680e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000682e:	00021517          	auipc	a0,0x21
    80006832:	8fa50513          	addi	a0,a0,-1798 # 80027128 <disk+0x2128>
    80006836:	ffffa097          	auipc	ra,0xffffa
    8000683a:	462080e7          	jalr	1122(ra) # 80000c98 <release>
}
    8000683e:	70a6                	ld	ra,104(sp)
    80006840:	7406                	ld	s0,96(sp)
    80006842:	64e6                	ld	s1,88(sp)
    80006844:	6946                	ld	s2,80(sp)
    80006846:	69a6                	ld	s3,72(sp)
    80006848:	6a06                	ld	s4,64(sp)
    8000684a:	7ae2                	ld	s5,56(sp)
    8000684c:	7b42                	ld	s6,48(sp)
    8000684e:	7ba2                	ld	s7,40(sp)
    80006850:	7c02                	ld	s8,32(sp)
    80006852:	6ce2                	ld	s9,24(sp)
    80006854:	6d42                	ld	s10,16(sp)
    80006856:	6165                	addi	sp,sp,112
    80006858:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000685a:	00020697          	auipc	a3,0x20
    8000685e:	7a66b683          	ld	a3,1958(a3) # 80027000 <disk+0x2000>
    80006862:	96ba                	add	a3,a3,a4
    80006864:	4609                	li	a2,2
    80006866:	00c69623          	sh	a2,12(a3)
    8000686a:	b5c9                	j	8000672c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000686c:	f9042583          	lw	a1,-112(s0)
    80006870:	20058793          	addi	a5,a1,512
    80006874:	0792                	slli	a5,a5,0x4
    80006876:	0001f517          	auipc	a0,0x1f
    8000687a:	83250513          	addi	a0,a0,-1998 # 800250a8 <disk+0xa8>
    8000687e:	953e                	add	a0,a0,a5
  if(write)
    80006880:	e20d11e3          	bnez	s10,800066a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006884:	20058713          	addi	a4,a1,512
    80006888:	00471693          	slli	a3,a4,0x4
    8000688c:	0001e717          	auipc	a4,0x1e
    80006890:	77470713          	addi	a4,a4,1908 # 80025000 <disk>
    80006894:	9736                	add	a4,a4,a3
    80006896:	0a072423          	sw	zero,168(a4)
    8000689a:	b505                	j	800066ba <virtio_disk_rw+0xf4>

000000008000689c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000689c:	1101                	addi	sp,sp,-32
    8000689e:	ec06                	sd	ra,24(sp)
    800068a0:	e822                	sd	s0,16(sp)
    800068a2:	e426                	sd	s1,8(sp)
    800068a4:	e04a                	sd	s2,0(sp)
    800068a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800068a8:	00021517          	auipc	a0,0x21
    800068ac:	88050513          	addi	a0,a0,-1920 # 80027128 <disk+0x2128>
    800068b0:	ffffa097          	auipc	ra,0xffffa
    800068b4:	334080e7          	jalr	820(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068b8:	10001737          	lui	a4,0x10001
    800068bc:	533c                	lw	a5,96(a4)
    800068be:	8b8d                	andi	a5,a5,3
    800068c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068c6:	00020797          	auipc	a5,0x20
    800068ca:	73a78793          	addi	a5,a5,1850 # 80027000 <disk+0x2000>
    800068ce:	6b94                	ld	a3,16(a5)
    800068d0:	0207d703          	lhu	a4,32(a5)
    800068d4:	0026d783          	lhu	a5,2(a3)
    800068d8:	06f70163          	beq	a4,a5,8000693a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068dc:	0001e917          	auipc	s2,0x1e
    800068e0:	72490913          	addi	s2,s2,1828 # 80025000 <disk>
    800068e4:	00020497          	auipc	s1,0x20
    800068e8:	71c48493          	addi	s1,s1,1820 # 80027000 <disk+0x2000>
    __sync_synchronize();
    800068ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068f0:	6898                	ld	a4,16(s1)
    800068f2:	0204d783          	lhu	a5,32(s1)
    800068f6:	8b9d                	andi	a5,a5,7
    800068f8:	078e                	slli	a5,a5,0x3
    800068fa:	97ba                	add	a5,a5,a4
    800068fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068fe:	20078713          	addi	a4,a5,512
    80006902:	0712                	slli	a4,a4,0x4
    80006904:	974a                	add	a4,a4,s2
    80006906:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000690a:	e731                	bnez	a4,80006956 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000690c:	20078793          	addi	a5,a5,512
    80006910:	0792                	slli	a5,a5,0x4
    80006912:	97ca                	add	a5,a5,s2
    80006914:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006916:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000691a:	ffffc097          	auipc	ra,0xffffc
    8000691e:	af0080e7          	jalr	-1296(ra) # 8000240a <wakeup>

    disk.used_idx += 1;
    80006922:	0204d783          	lhu	a5,32(s1)
    80006926:	2785                	addiw	a5,a5,1
    80006928:	17c2                	slli	a5,a5,0x30
    8000692a:	93c1                	srli	a5,a5,0x30
    8000692c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006930:	6898                	ld	a4,16(s1)
    80006932:	00275703          	lhu	a4,2(a4)
    80006936:	faf71be3          	bne	a4,a5,800068ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000693a:	00020517          	auipc	a0,0x20
    8000693e:	7ee50513          	addi	a0,a0,2030 # 80027128 <disk+0x2128>
    80006942:	ffffa097          	auipc	ra,0xffffa
    80006946:	356080e7          	jalr	854(ra) # 80000c98 <release>
}
    8000694a:	60e2                	ld	ra,24(sp)
    8000694c:	6442                	ld	s0,16(sp)
    8000694e:	64a2                	ld	s1,8(sp)
    80006950:	6902                	ld	s2,0(sp)
    80006952:	6105                	addi	sp,sp,32
    80006954:	8082                	ret
      panic("virtio_disk_intr status");
    80006956:	00002517          	auipc	a0,0x2
    8000695a:	0a250513          	addi	a0,a0,162 # 800089f8 <syscalls+0x3c0>
    8000695e:	ffffa097          	auipc	ra,0xffffa
    80006962:	be0080e7          	jalr	-1056(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
