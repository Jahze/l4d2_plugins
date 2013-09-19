; edx = i
89 /r 		mov edx, esi
2b /r 		sub edx, [ebp+arg_14]
ff /1 		dec edx

; in one case set eax = 1
; put 120.0f on top of fpu stack
mov eax, 1
mov [esp], 120.0f
fld [esp]

; in other set eax = 4
; put 360 / (max_bullets - 4) on top of fpu stack
mov eax, 4
mov [esp], edx
add [esp], edi
sub [esp], 3
mov [esp+4], 360.0f
fild [esp]
fld [esp+4]
fdivrp

; at end do (edx - eax) * st(0)
sub edx, eax
fild edx
fmulp


-----------------------------------------------------

	mov [ebp+a0], 0 			; spread = 0.0f
	mov edx, esi
	sub edx, [ebp+arg_14]
	dec edx						; edx = i
	cmp edx, 4					; if edx > 4
	jg ring2
	cmp edx, 0 					; if edx > 0
	jg ring1
	jmp end

ring2:
	mov [ebp+a0], 5.0f			; spread = 5.0f
	mov [esp], edx
	add [esp], edi
	sub [esp], 3 				; esp = max_bullets - 4
	fild [esp]
	mov [esp], 360.0f
	fld [esp]
	fdivrp						; st(0) = 360 / (max_bullets - 4)
	sub edx, 4					; edx = i - 4
	jmp end

ring1:
	mov [ebp+a0], 3.0f			; spread = 3.0f
	sub edx, 1					; edx = i - 1
	mov [esp], 120.0f
	fld [esp]					; st(0) = 120.0f

end:
	fild edx
	fmulp						; st(0) = spread_dir
	sub esp, 4

-----------------------------------------------------

	83 /5 ib	sub esp, 0ch				; keep the stack correct
	31 /r 		xor eax, eax
	8b /r		mov [ebp+a0], eax 			; spread = 0.0f
	8b /r 		mov edx, esi
	2b /r 		sub edx, [ebp+arg_14]		; edx = i + 1
	3c ib 		cmp edx, 4					; if edx > 4
	7f cb 		jg ring2
	eb cb 		jmp ring1

ring2:
	c7 /0 id 	mov [ebp+a0], 5.0f			; spread = 5.0f
	8b /r 		mov [esp], edx
	01 /r 		add [esp], edi
	83 /5 ib 	sub [esp], 4 				; esp = max_bullets - 4
	db /0 		fild [esp]
	c7 /0 id 	mov [esp], 360.0f
	d9 /0 		fld [esp]
	de f1 		fdivrp						; st(0) = 360 / (max_bullets - 4)
	83 /5 ib 	sub edx, 5					; edx = i - 4
	eb cb 		jmp end

ring1:
	c7 /0 id 	mov [ebp+a0], 3.0f			; spread = 3.0f
	83 /5 ib 	sub edx, 2					; edx = i - 1
	c7 /0 id 	mov [esp], 120.0f
	db /0 		fld [esp]					; st(0) = 120.0f

end:
	8b /r 		mov [esp], edx
	db /0 		fild [esp]
	de c9 		fmulp						; st(0) = spread_dir
	90			nop

should be 76 bytes

-----------------------------------------------------

	83 ec 0c					sub esp, 0ch				; keep the stack correct
	31 c0 						xor eax, eax
	89 45 a0					mov [ebp+a0], eax 			; spread = 0.0f
	8b d6 						mov edx, esi
	2b 55 1c					sub edx, [ebp+arg_14]		; edx = i + 1
	8b c4						mov eax, esp				; eax = esp
	83 fa 04					cmp edx, 4					; if edx > 4
	7f 02 						jg ring2
	eb 1f 						jmp ring1

ring2:
	c7 45 a0 00 00 a0 40		mov [ebp+a0], 5.0f			; spread = 5.0f
	89 10 						mov [esp], edx
	01 38 						add [esp], edi
	83 28 04 					sub [esp], 4 				; esp = max_bullets - 4
	db 00 						fild [esp]
	c7 00 00 00 b4 43			mov [esp], 360.0f
	d9 00 						fld [esp]
	de f1 						fdivrp						; st(0) = 360 / (max_bullets - 4)
	83 ea 05 					sub edx, 5					; edx = i - 4
	eb 12 						jmp end

ring1:
	c7 45 a0 00 00 40 40		mov [ebp+a0], 3.0f			; spread = 3.0f
	83 ea 02 					sub edx, 2					; edx = i - 1
	c7 00 00 00 f0 42			mov [esp], 120.0f
	d9 00 						fld [esp]					; st(0) = 120.0f

end:
	89 10 						mov [esp], edx
	db 00 						fild [esp]
	de c9 						fmulp						; st(0) = spread_dir
	90							nop

-----------------------------------------------------

- LOOKS LIKE ebp+arg_14 is not helpful

	83 ec 0c					sub esp, 0ch				; keep the stack correct
	31 c0 						xor eax, eax
	89 45 a0					mov [ebp+a0], eax 			; spread = 0.0f
	8b d6 						mov edx, esi
	8b c4						mov eax, esp				; eax = esp
	83 fa 04					cmp edx, 4					; if edx > 4
	7f 02 						jg ring2
	eb 1f 						jmp ring1

ring2:
	c7 45 a0 00 00 a0 40		mov [ebp+a0], 5.0f			; spread = 5.0f
	89 10 						mov [esp], edx
	01 38 						add [esp], edi
	83 28 04 					sub [esp], 4 				; esp = max_bullets - 4
	db 00 						fild [esp]
	c7 00 00 00 b4 43			mov [esp], 360.0f
	d9 00 						fld [esp]
	de f1 						fdivrp						; st(0) = 360 / (max_bullets - 4)
	83 ea 05 					sub edx, 5					; edx = i - 4
	eb 12 						jmp end

ring1:
	c7 45 a0 00 00 40 40		mov [ebp+a0], 3.0f			; spread = 3.0f
	83 ea 02 					sub edx, 2					; edx = i - 1
	c7 00 00 00 f0 42			mov [esp], 120.0f
	d9 00 						fld [esp]					; st(0) = 120.0f

end:
	89 10 						mov [esp], edx
	db 00 						fild [esp]
	de c9 						fmulp						; st(0) = spread_dir
	0f 1f 40 00					nop
	
-----------------------------------------------------

linux 


	89 85 54 ff ff ff				mov [ebp-ac], eax 			; spread = 0.0f
	8b 55 20 						mov edx, [ebp+20]			; edx = i + 1
	8b c4							mov eax, esp				; eax = esp
	83 fa 05						cmp edx, 5					; if i > 4
	7f 02 							jg ring2
	eb 22 							jmp ring1

ring2:
	c7 85 54 ff ff ff 00 00 a0 40	mov [ebp-ac], 5.0f			; spread = 5.0f
	89 10 							mov [esp], edx
	01 38 							add [esp], edi
	83 28 05 						sub [esp], 5 				; esp = max_bullets - 4
	db 00 							fild [esp]
	c7 00 00 00 b4 43				mov [esp], 360.0f
	d9 00 							fld [esp]
	de f1 							fdivrp						; st(0) = 360 / (max_bullets - 4)
	83 ea 05 						sub edx, 5					; edx = i - 4
	eb 15 							jmp end

ring1:
	c7 85 54 ff ff ff 00 00 40 40	mov [ebp-ac], 3.0f			; spread = 3.0f
	83 ea 02 						sub edx, 2					; edx = i - 1
	c7 00 00 00 f0 42				mov [esp], 120.0f
	d9 00 							fld [esp]					; st(0) = 120.0f

end:
	89 10 							mov [esp], edx
	db 00 							fild [esp]
	de c9 							fmulp						; st(0) = spread_dir
	d9 95 3c ff ff ff				fstp [ebp-c4]

--------

\x89\x85\x54\xff\xff\xff\x8b\x55\x20\x8b\xc4\x83\xfa\x05\x7f\x02\xeb\x22\xc7\x85\x54\xff\xff\xff\x00\x00\xa0\x40\x89\x10\x01\x38\x83\x28\x05\xdb\x00\xc7\x00\x00\x00\xb4\x43\xd9\x00\xde\xf1\x83\xea\x05\xeb\x15\xc7\x85\x54\xff\xff\xff\x00\x00\x40\x40\x83\xea\x02\xc7\x00\x00\x00\xf0\x42\xd9\x00\x89\x10\xdb\x00\xde\xc9\xd9\x95\x3c\xff\xff\xff