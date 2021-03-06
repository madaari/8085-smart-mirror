// POINTER TO NUMBER OF CHARACTERS
# SW_REG EQU 80H
# PORTA EQU 81H
# PORTB EQU 82H
# PORTC EQU 83H
# ORG 0000H
	   JMP MAIN
# ORG 003CH
	   JMP RST7_5
# ORG 0500

MAIN:	   LXI SP,80FF	// STACK POINTER INITIALIZE
	   LXI H,8001	// MEMORY POINTER
	   MVI A,0B
	   SIM
	   CALL PPI_INIT	// INITIALIZE PPI FOR LCD
	   CALL BIG_DELAY
	   CALL LCD_INIT
	   EI

MAIN_LOOP:	   JMP MAIN_LOOP
	   HLT

PRINT:	   MVI D,01
	   CALL SEND_CMND
	   MVI B,FF
	   CALL DELAY
	   MOV D,C
	   MVI C,1A
	   LXI H,0A00
	   CALL PRINTLOOP
	   MOV C,D
	   MVI E,01
	   CALL CHANGELINE
	   LXI H,8001
	   CALL PRINTLOOP
	   RET

PPI_INIT:	   MVI A,0F	// PORTA,B,C OUTPUT MODE
	   OUT SW_REG
	   XRA A	// CLEAR ACCUMULATOR
	   OUT PORTA	// SET PORTA ZERO
	   OUT PORTC	// SET PORTC ZERO
	   MVI A,03
	   OUT PORTB	// BACKLIGHT ON
	   RET

DELAY:	   DCR B	// ARGUEMENT MUST BE PASSED IN B REG
	   JNZ DELAY
	   RET

LCD_INIT:	   MVI D,38	// DL - 2,FONT 5X7
	   CALL SEND_CMND
	   MVI D,01
	   CALL SEND_CMND
	   MVI B,FF
	   CALL DELAY
	   MVI B,2F
	   CALL DELAY
	   MVI D,0C	// DISPLAY ON,CURSOR OFF,BLINK OFF
	   CALL SEND_CMND
	   MVI D,06	// CURSOR INCREMENT
	   CALL SEND_CMND
	   LXI H,0C00
	   MVI C,04	// NO OF CHARACTERS '4'
	   CALL PRINTLOOP
	   MVI D,C4	// SECOND ROW 4 COLM
	   CALL SEND_CMND
	   MVI C,05
	   CALL PRINTLOOP
	   MVI D,9D	// THIRD ROW
	   CALL SEND_CMND
	   MVI C,05
	   CALL PRINTLOOP
	   MVI D,E2	// FOURTH ROW
	   CALL SEND_CMND
	   MVI C,06
	   CALL PRINTLOOP
	   RET

SEND_CMND:	   MOV A,D	// GET ARGUEMENT FROM D REGISTER
	   OUT PORTA
	   MVI A,02	// RS = 0, EN = 1
	   OUT PORTC
	   XRA A
	   OUT PORTC	// RS = 0, EN = 0
	   MVI B,2F
	   CALL DELAY
	   RET

PRINTANGLE:	   MVI A,3E	// RIGHT ANGLE BRACKET
	   OUT PORTA
	   MVI A,03	// RS = 1, EN = 1
	   OUT PORTC
	   MVI A,01	// RS = 1, EN = 0
	   OUT PORTC
	   MVI B,2D
	   CALL DELAY	// DELAY FOR 30 uSEC
// TAKE ACC AS PARAM
	   RET

CHANGELINE:	   INR E
	   MOV A,E
	   CPI 01
	   CZ FIRSTLINE
	   CPI 02
	   CZ SECONDLINE
	   CPI 03
	   CZ THIRDLINE
	   CPI 04
	   CZ FOURTHLINE
	   CALL PRINTANGLE
	   RET

FIRSTLINE:	   MVI D,80	// CURSOR MOVE TO FIRST LINE
	   CALL SEND_CMND
	   RET

SECONDLINE:	   MVI D,C0	// CURSOR MOVE TO SECOND LINE
	   CALL SEND_CMND
	   RET

THIRDLINE:	   MVI D,94	// CURSOR MOVE TO THIRD LINE
	   CALL SEND_CMND
	   RET

FOURTHLINE:	   MVI D,D4	// CURSOR MOVE TO FOURTH LINE
	   CALL SEND_CMND
	   RET

INCLINE:	   CALL CHANGELINE
	   JMP NEXTPRINT

PRINTLOOP:	   MOV A,M	// FETCH DATA FROM MEMORY
	   CPI 0A
	   JZ INCLINE
	   OUT PORTA
	   MVI A,03	// RS = 1, EN = 1
	   OUT PORTC
	   MVI A,01	// RS = 1, EN = 0
	   OUT PORTC
	   MVI B,2F
	   CALL DELAY	// DELAY FOR 30 uSEC

NEXTPRINT:	   INX H	// INCREMENT MEM POINTER
	   DCR C
	   JNZ PRINTLOOP
	   MVI A,00
	   OUT PORTC
	   RET

RST7_5:	   PUSH B
	   PUSH PSW
	   PUSH D
	   PUSH H
	   LXI H,8001
	   MVI C,00

START_BIT:	   RIM	// CHECK FOR START BIT
	   ANI 80
	   JNZ START_BIT
	   MVI E,00
	   MVI D,07
	   MVI B,1C
	   CALL DELAY	// 150uSEC DELAY

BIT_READ:	   RIM
	   ANI 80
	   JNZ HIGH
	   XRA A	// LOW BIT

HIGH:	   ORA E
	   RRC
	   MOV E,A
	   XRA A	// JUST TO CONSUME EXTRA TIME
	   MVI B,10
	   CALL DELAY
	   DCR D	// BIT COUNTER
	   JNZ BIT_READ
	   RIM	// READS LAST BIT
	   ANI 80
	   ORA E
// ALL BITS RECIEVED
	   MOV E,A
	   CPI 09
	   JZ LOOPEXIT	// STOP RECIEVING IF WE GET '/t'
	   MOV M,E
	   INX H
	   INR C

STOP_BIT:	   RIM	// WAIT TILL STOP BIT RECIEVED
	   ANI 80
	   JZ STOP_BIT
	   JMP START_BIT

LOOPEXIT:	   CALL PRINT
	   MVI A,1B
	   SIM
	   MVI A,0B
	   SIM
	   POP H
	   POP D
	   POP PSW
	   POP B
	   EI
	   RET

BIG_DELAY:	   LXI B,0A2B

BIG_DELAYLOOP:	   DCX B
	   MOV A,B
	   ORA C
	   JNZ BIG_DELAYLOOP
	   RET
# ORG 0A00H
# DB 80H,20H,20H,2AH,2AH,54H,6FH,2DH,44H,6FH,20H,4CH,69H,73H,74H,2AH,2AH,20H,20H,20H,20H,20H
# ORG 0C00H
# DB 38H,30H,38H,35H,42H,41H,53H,45H,44H,53H,4DH,41H,52H,54H,4DH,49H,52H,52H,4FH,52H
