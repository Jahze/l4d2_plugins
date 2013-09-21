
test.bin:     file format binary
Disassembly of section .data:
00000000 <.data>:
   0:	8d 8d 54 ff ff ff    	lea    ecx,[ebp-0xac]
   6:	f3 0f 11 01          	movss  DWORD PTR [ecx],xmm0
   a:	8b 55 20             	mov    edx,DWORD PTR [ebp+0x20]
   d:	8b c4                	mov    eax,esp
   f:	83 fa 04             	cmp    edx,0x4
  12:	7f 02                	jg     0x16
  14:	eb 18                	jmp    0x2e
  16:	89 10                	mov    DWORD PTR [eax],edx
  18:	01 38                	add    DWORD PTR [eax],edi
  1a:	83 28 05             	sub    DWORD PTR [eax],0x5
  1d:	db 00                	fild   DWORD PTR [eax]
  1f:	c7 00 00 00 34 43    	mov    DWORD PTR [eax],0x43340000
  25:	d9 00                	fld    DWORD PTR [eax]
  27:	de f1                	fdivp  st(1),st
  29:	83 ea 05             	sub    edx,0x5
  2c:	eb 19                	jmp    0x47
  2e:	c7 00 02 00 00 00    	mov    DWORD PTR [eax],0x2
  34:	db 00                	fild   DWORD PTR [eax]
  36:	d9 01                	fld    DWORD PTR [ecx]
  38:	de f1                	fdivp  st(1),st
  3a:	d9 19                	fstp   DWORD PTR [ecx]
  3c:	83 ea 02             	sub    edx,0x2
  3f:	c7 00 00 00 f0 42    	mov    DWORD PTR [eax],0x42f00000
  45:	d9 00                	fld    DWORD PTR [eax]
  47:	89 10                	mov    DWORD PTR [eax],edx
  49:	db 00                	fild   DWORD PTR [eax]
  4b:	de c9                	fmulp  st(1),st
  4d:	d9 95 3c ff ff ff    	fst    DWORD PTR [ebp-0xc4]
  53:	90                   	nop
  54:	90                   	nop
need to add 90.0f before 4d: d9 95 3c ff ff ff     fst    DWORD PTR [ebp-0xc4]
c7 00 00 00 b4 42   mov DWORD PTR [eax], 0x42b40000
d9 00               fld DWORD PTR [eax]
de c1               faddp
10 bytes ... 2 left :(
need to reclaim 8 bytes
2 byte shorter:
c6 c0 90  mov al, 90
0f b6 00  movzx [eax], al
da 00     fiadd [eax]
CHANGE
  49: db 00                 fild   DWORD PTR [eax]
  4b: de c9                 fmulp  st(1),st
  da 08       fimul DWORD PTR [eax]
CHANGE
  36: d9 01                 fld    DWORD PTR [ecx]
  38: de f1                 fdivp  st(1),st
  d8 39       fdivr DWORD PTR [ecx]
CHANGE
  25: d9 00                 fld    DWORD PTR [eax]
  27: de f1                 fdivp  st(1),st
  d8 38       fdivr DWORD PTR [eax]
  -------------------------
8d 8d 54 ff ff ff     lea    ecx,[ebp-0xac]
f3 0f 11 01           movss  DWORD PTR [ecx],xmm0
8b 55 20              mov    edx,DWORD PTR [ebp+0x20]
8b c4                 mov    eax,esp
83 fa 04              cmp    edx,0x4
7f 02                 jg     0x16
eb 16                 jmp    0x2c
89 10                 mov    DWORD PTR [eax],edx
01 38                 add    DWORD PTR [eax],edi
83 28 05              sub    DWORD PTR [eax],0x5
db 00                 fild   DWORD PTR [eax]
c7 00 00 00 34 43     mov    DWORD PTR [eax],0x43340000
d8 38                 fdivr  DWORD PTR [eax]
83 ea 05              sub    edx,0x5
eb 17                 jmp    0x45
c7 00 02 00 00 00     mov    DWORD PTR [eax],0x2
db 00                 fild   DWORD PTR [eax]
d8 39                 fdivr  DWORD PTR [ecx]
d9 19                 fstp   DWORD PTR [ecx]
83 ea 02              sub    edx,0x2
c7 00 00 00 70 42     mov    DWORD PTR [eax],0x42700000
d9 00                 fld    DWORD PTR [eax]
89 10                 mov    DWORD PTR [eax],edx
da 08                 fimul  DWORD PTR [eax]
d9 95 3c ff ff ff     fst    DWORD PTR [ebp-0xc4]
90                    nop
90                    nop
90                    nop
90                    nop
90                    nop
90                    nop
90                    nop
90                    nop

6a 90   push 90
8f 00   pop eax
da 00   fiadd [eax]
"8d\x8d\x54\xff\xff\xff\xf3\x0f\x11\x01\x8b\x55\x20\x8b\xc4\x83\xfa\x04\x7f\x02\xeb\x16\x89\x10\x01\x38\x83\x28\x05\xdb\x00\xc7\x00\x00\x00\x34\x43\xd8\x38\x83\xea\x05\xeb\x17\xc7\x00\x02\x00\x00\x00\xdb\x00\xd8\x39\xd9\x19\x83\xea\x02\xc7\x00\x00\x00\x70\x42\xd9\x00\x89\x10\xda\x08\xd9\x95\x3c\xff\xff\xff\x90\x90\x90\x90\x90\x90\x90\x90"