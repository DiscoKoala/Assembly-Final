;// CSCI 2525-H01
;// Final Project: Encryption/Decryption
;// Created by Wesley Johnson, Julian Williams-Goldberg, and Miles Dixon


INCLUDE Irvine32.inc

;// ----------------------------------------------------------------------------
;// PROCEDURE PROTOTYPES

DisplayMenu PROTO,
	UserOpt:BYTE

EnterPhrase PROTO,
	UserPhr:PTR BYTE

EnterKey PROTO C,
	EKey:PTR BYTE

EncryptPhrase PROTO,
	UserPhr:PTR BYTE,
	EKey:PTR BYTE,
	PhraseLen:WORD

DecryptPhrase PROTO,
	UserPhr:PTR BYTE,
	DKey:PTR BYTE

UpperCase PROTO,
	UserPhr:PTR BYTE

AlphaNum PROTO,
	UserPhr:PTR BYTE,
	TempStr:PTR BYTE,
	PhraseLen:WORD
;// ----------------------------------------------------------------------------


;// constants
maxStrLen = 151d
newLine EQU<0ah, 0dh>
AlphaMod = 1Ah
NumMod = 0Ah

.data
	UserPhrase BYTE maxStrLen DUP(0h)
	tempString BYTE maxStrLen DUP(0h)
	Key BYTE maxStrLen DUP(0h)
	UserOption BYTE 0h
	PhraseLength BYTE ?
	KeyLength BYTE ?
	error BYTE "Invalid option...", newline, 0

.code
main PROC
	;// Get user input, validate input, send to proc selector PickProc
	call clearRegs
	start:
	call clrscr
	mov ebx, offset userOption
	INVOKE displayMenu, UserOption 
	cmp userOption, 1d
	jb invalid
	cmp userOption, 4d
	jb driver
	cmp userOption, 4d
	je done
invalid:
	;//if invalid, show error msg, send to top
	push edx
	mov edx, offset error
	call WriteString
	call WaitMsg
	pop edx
driver:
	call PickProc
	jmp start

done:
 	exit
main ENDP

;// ----------------------------------------------------------------------------
;// PICK PROC - send user to correct option, invoke proper functions
PickProc PROC
	
	cmp userOption, 1d
	je option1

	cmp userOption, 2d
	je option2

	cmp userOption, 3d
	je option3

	jmp leaveFunc

	option1:
		;//ask user for phrase and key
		;//covert phrase to uppercase, remove non-alpha characters

		INVOKE EnterPhrase, ADDR UserPhrase
		INVOKE EnterKey, ADDR Key
		INVOKE AlphaNum, ADDR UserPhrase, ADDR TempString, PhraseLength
		INVOKE UpperCase, ADDR UserPhrase
		jmp leaveFunc

	option2:
		INVOKE EncryptPhrase, ADDR Userphrase, ADDR Key, PhraseLength
		jmp leaveFunc

	option3:
		INVOKE DecryptPhrase, addr userphrase, addr key

	leaveFunc:
		ret
PickProc ENDP

;// ----------------------------------------------------------------------------
;// DISPLAY MENU - displays options, gets user input

DisplayMenu PROC USES eax edx,
	UserOpt:BYTE

.data
	MainMenu BYTE "----------Main Menu----------", newline,
	"1. Enter a phrase ", newline,
	"2. Encrypt the phrase ", newline,
	"3. Decrypt the phrase ", newline,
	"4. Exit ", newline,
	"Please make a selection => ", 0h

.code
	mov edx, OFFSET MainMenu 
	call WriteString
	call ReadDec
	mov [ebx], al
	ret
DisplayMenu ENDP

;// ----------------------------------------------------------------------------
;// ENTER PHRASE - prompt phrase entrance, get user input

EnterPhrase PROC USES eax edx ecx,
	UserPhr:PTR BYTE

	.data
	PhrasePrompt BYTE "Enter phrase to be encrypted/decrypted ===> ", 0h

	.code
	call Crlf
	push edx
	mov edx, OFFSET PhrasePrompt
	call WriteString
	pop edx

	mov edx, UserPhr
	mov ecx, maxStrLen
	call ReadString
	mov PhraseLength, al

	ret
EnterPhrase ENDP

;// ----------------------------------------------------------------------------
;// ENTER KEY - prompt key entrance, get user input 
EnterKey PROC C USES eax edx ecx, 
	EKey:PTR BYTE
	
	.data
	KeyPrompt BYTE "Enter encryption/decryption key ===> ", 0h
	
	.code
	push edx
	mov edx, OFFSET KeyPrompt
	call WriteString
	pop edx

	mov edx, EKey
	mov ecx, maxStrLen
	call ReadString
	mov KeyLength, al

	ret
EnterKey ENDP

;// ----------------------------------------------------------------------------
;// ENCRYPT PHRASE

EncryptPhrase PROC USES eax ebx ecx edx esi edi,
	UserPhr:PTR BYTE,
	EKey:PTR BYTE,
	PhraseLen:WORD

	.data
	Remainder BYTE ?
	Alphabet BYTE "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	Numbers BYTE "0123456789"
	output BYTE "Encrypted Phrase:   ", newline, 0

	.code
	mov esi, UserPhr
	mov edi, EKey
	mov ebx, 0
	;mov ecx, DWORD PTR PhraseLen

	L1:
		mov eax, 0
		mov bl, byte ptr[esi]				;// Move phrase character to ebx register

		cmp bl, 0h
		je Break

		cmp bl , 20h
		je cont

		mov al, byte ptr[edi]

		cmp al, 0h							;// Check if index is above or equal to KeyLength
		je Reset					

		cmp bl, 30h
		jae DigitMod

		DigitMod:
			cmp bl, 39h						;// Check if character is a letter
			ja LetterMod
			mov ebx, 0
			mov edx, 0
			
			mov bx, NumMod					;// Move divisor (1h)  to ebx
			div bl							;// Divide key character by 1h
			
			mov al, byte ptr[esi]
			sub al, ah						;// Subtract remainder from value
			cmp al, 30h						;// within range?

			jb AdjustNum
			afterAdjustNum:
			mov BYTE PTR[esi], al			;// add to array

			jmp cont

		LetterMod:
			mov ebx, 0
			mov edx, 0
			mov eax, 0
			mov al, byte ptr[edi]
			mov bx, AlphaMod
			div bx
			mov Remainder, al
			mov bl, byte ptr[esi]
			sub bl, Remainder
			cmp bl, 41h

			jb AdjustLetter
			afterAdjustLet:
			mov BYTE PTR[esi], bl			;// Replace unencrypted char with encrypted char in UserPhrase
			
			jmp cont

		Reset:								;// If key index is above or equal to key length, reset counter to 0
			mov edi, EKey
			loop L1

		AdjustNum:							;// Adjust ASCII value if out of range
			add al, 0Ah
			jmp afterAdjustNum

		AdjustLetter:						;// Adjust ASCII value if out of range 
			add bl, 1Ah
			jmp afterAdjustLet

		cont:
			inc esi
			inc edi
			
			cmp ecx, 0
			ja L1
	Break:
	call crlf
	mov edx, offset output
	call writeString
	call crlf
	mov edx, UserPhr
	call writeString
	call crlf

	
	call waitmsg
	ret
EncryptPhrase ENDP

;// ----------------------------------------------------------------------------
;// DECRYPT PHRASE

DecryptPhrase PROC USES eax ebx ecx edx esi edi,
	UserPhr:PTR BYTE,
	DKey:PTR BYTE


.data
	dRemainder BYTE ?
	dAlphabet BYTE "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	dNumbers BYTE "0123456789"
	doutput BYTE "Decrypted Phrase:   ", newline, 0

.code
	mov esi, UserPhr
	mov edi, DKey
	mov ebx, 0

	L1:
		mov eax, 0
		mov bl, byte ptr[esi]				;// Move phrase character to ebx register

		cmp bl, 0h
		je Break

		cmp bl , 20h
		je cont

		mov al, byte ptr[edi]

		cmp al, 0h							;// Check if index is above or equal to KeyLength
		je Reset

		cmp bl, 30h
		jae DigitMod

		DigitMod:
			cmp bl, 39h						;// Check if character is a letter
			ja LetterMod
			mov ebx, 0
			mov edx, 0
			

			mov bx, NumMod					;// Move divisor (1h)  to ebx
			div bl							;// Divide key character by 1h
			
			mov al, byte ptr[esi]
			;sub al, ah
			sub al, 0ah
			add al, ah
			cmp al, 30h
			jb AdjustNum

			afterAdjustNum:
			mov BYTE PTR[esi], al	
			jmp cont

		LetterMod:
			mov ebx, 0
			mov edx, 0
			mov eax, 0
			mov al, byte ptr[edi]
			mov bx, AlphaMod
			div bl
			mov dRemainder, al
			mov bl, byte ptr[esi]
			add bl, dRemainder
			
			cmp bl, 5Ah
			ja AdjustLetter
			afterAdjustLet:
			mov BYTE PTR[esi], bl			;// Replace unencrypted char with encrypted char in UserPhrase
			jmp cont

		Reset:								;// If key index is above or equal to key length, reset counter to 0
			mov edi, DKey
			loop L1

		AdjustNum:							;// Adjust ASCII value if out of range
			add al, 0Ah
			jmp afterAdjustNum

		AdjustLetter:						;// Adjust ASCII value if out of range
			sub bl, 1Ah
			jmp afterAdjustLet

		cont:
			
			inc esi
			inc edi

			cmp ecx, 0
			ja L1
	Break:
	call crlf
	mov edx, offset doutput
	call writeString
	call crlf
	mov edx, UserPhr
	call writeString
	call crlf

	
	call waitmsg

	ret
DecryptPhrase ENDP

;// ----------------------------------------------------------------------------
;// CLEAR REGS - zero regs

clearRegs PROC

	mov EAX, 0h
	mov EBX, 0h
	mov ECX, 0h
	mov EDX, 0h
	mov ESI, 0h
	mov EDI, 0h

	ret
clearRegs ENDP

;//-----------------------------------------------------------------------------
;// UPPER CASE - Convert characters to uppercase

UpperCase PROC USES esi ebx,
	UserPhr:PTR BYTE
	mov esi, UserPhr

	L1:
		mov bl, [esi]

		cmp bl, 0
		je Break

		cmp bl, 61h
		jb cont
    
		cmp bl, 7Ah
		ja cont
		
		xor byte ptr [esi], 20h

	cont:
		inc esi
		loop L1

	Break:
	ret
UpperCase ENDP

;// ----------------------------------------------------------------------------
;// ALPHA NUMS - remove non-alphanumeric chars from string

AlphaNum PROC USES esi eax ebx ecx edi,
	UserPhr:PTR BYTE,
	TempStr:PTR BYTE,
	PhraseLen:WORD

  mov esi, UserPhr
  mov eax, 0
  mov ebx, 0
  mov edi, TempStr


	opt3Loop:
		mov bl,  byte ptr[esi]

		cmp bl, 0h
		je Break

		;// If below 30h, its non-numerical
		cmp bl, 30h
		jb cont

		;// If above or equal to 30h, check if number
		cmp bl, 30h
		jae numRange

		;// If number, add to tempString
		numRange:
			cmp bl, 39h
			jbe cont1

			cmp bl, 40h
			je cont

			cmp bl, 40h
			ja capitalRange

		capitalRange:
			;// If above or equal to 41h, add character
			cmp bl, 5Ah
			jbe cont1

			cmp bl, 60h
			jbe cont

			;// If above or equal to 61h, check if lowercase
			cmp bl, 61h
			jae lowerRange

		lowerRange:
			;// If below or equal to 7Ah, add character
			cmp bl, 7Ah
			jbe cont1

			cmp bl, 7Ah
			ja cont

		cont1:
			mov byte ptr[edi], bl
			inc edi
		cont:
			inc esi

	loop opt3Loop

	Break:
	call CopyString
	ret
AlphaNum ENDP

;// ----------------------------------------------------------------------------
;// COPY STRING - fill duplicate size array with original contents

CopyString PROC USES esi ecx eax

	mov ecx, LENGTHOF UserPhrase
	mov al, 0
	mov esi, 0

	copy:
		mov al, tempString[esi]
		mov tempString[esi], 0h
		mov UserPhrase[esi], al
		inc esi
		loop copy

	ret
CopyString ENDP

;// ----------------------------------------------------------------------------

END main