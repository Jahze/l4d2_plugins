
test.bin:     file format binary


Disassembly of section .data:

00000000 <.data>:
   0:	89 85 54 ff ff ff    	mov    DWORD PTR [ebp-0xac],eax
   6:	8b 55 20             	mov    edx,DWORD PTR [ebp+0x20]
   9:	8b c4                	mov    eax,esp
   b:	83 fa 04             	cmp    edx,0x4
   e:	7f 02                	jg     0x12
  10:	eb 22                	jmp    0x34
  12:	c7 85 54 ff ff ff 00 	mov    DWORD PTR [ebp-0xac],0x40a00000
  19:	00 a0 40 
  1c:	89 10                	mov    DWORD PTR [eax],edx
  1e:	01 38                	add    DWORD PTR [eax],edi
  20:	83 28 05             	sub    DWORD PTR [eax],0x5
  23:	db 00                	fild   DWORD PTR [eax]
  25:	c7 00 00 00 34 43    	mov    DWORD PTR [eax],0x43340000
  2b:	d9 00                	fld    DWORD PTR [eax]
  2d:	de f1                	fdivp  st(1),st
  2f:	83 ea 05             	sub    edx,0x5
  32:	eb 15                	jmp    0x49
  34:	c7 85 54 ff ff ff 00 	mov    DWORD PTR [ebp-0xac],0x40400000
  3b:	00 40 40 
  3e:	83 ea 02             	sub    edx,0x2
  41:	c7 00 00 00 f0 42    	mov    DWORD PTR [eax],0x42f00000
  47:	d9 00                	fld    DWORD PTR [eax]
  49:	89 10                	mov    DWORD PTR [eax],edx
  4b:	db 00                	fild   DWORD PTR [eax]
  4d:	de c9                	fmulp  st(1),st
  4f:	d9 95 3c ff ff ff    	fst    DWORD PTR [ebp-0xc4]


; load max spread
8d 8d 54 ff ff ff           lea ecx,[ebp-0xac]
f3 0f 11 01                 movss DWORD PTR [ebp-0xac],xmm0

; div by 2
c7 00 02 00 00 00           mov DWORD PTR [eax], 0x2
db 00                       fild [eax]
d9 01                       fld DWORD PTR [ecx]
de f1                       fdivrp
d9 19                       fstp DWORD PTR [ecx]



-------------------------------------------------------------------------

8d 8d 54 ff ff ff     lea    ecx,[ebp-0xac]
f3 0f 11 01           movss  DWORD PTR [ecx],xmm0
8b 55 20              mov    edx,DWORD PTR [ebp+0x20]
8b c4                 mov    eax,esp
83 fa 04              cmp    edx,0x4
7f 02                 jg     0x12
eb 18                 jmp    0x18
89 10                 mov    DWORD PTR [eax],edx
01 38                 add    DWORD PTR [eax],edi
83 28 05              sub    DWORD PTR [eax],0x5
db 00                 fild   DWORD PTR [eax]
c7 00 00 00 34 43     mov    DWORD PTR [eax],0x43340000
d9 00                 fld    DWORD PTR [eax]
de f1                 fdivp  st(1),st
83 ea 05              sub    edx,0x5
eb 2c                 jmp    0x2c
c7 00 02 00 00 00     mov    DWORD PTR [eax], 0x2
db 00                 fild   [eax]
d9 01                 fld    DWORD PTR [ecx]
de f1                 fdivrp
d9 19                 fstp   DWORD PTR [ecx]
83 ea 02              sub    edx,0x2
c7 00 00 00 f0 42     mov    DWORD PTR [eax],0x42f00000
d9 00                 fld    DWORD PTR [eax]
89 10                 mov    DWORD PTR [eax],edx <--
db 00                 fild   DWORD PTR [eax]
de c9                 fmulp  st(1),st
d9 95 3c ff ff ff     fst    DWORD PTR [ebp-0xc4]


\x8d\x8d\x54\xff\xff\xff\xf3\x0f\x11\x01\x8b\x55\x20\x8b\xc4\x83\xfa\x04\x7f\x02\xeb\x18\x89\x10\x01\x38\x83\x28\x05\xdb\x00\xc7\x00\x00\x00\x34\x43\xd9\x00\xde\xf1\x83\xea\x05\xeb\x19\xc7\x00\x02\x00\x00\x00\xdb\x00\xd9\x01\xde\xf1\xd9\x19\x83\xea\x02\xc7\x00\x00\x00\xf0\x42\xd9\x00\x89\x10\xdb\x00\xde\xc9\xd9\x95\x3c\xff\xff\xff\x66\x90