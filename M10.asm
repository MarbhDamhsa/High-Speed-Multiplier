; CIS-261
;
; @topic W130105 Lab M10
; High-speed Multiplication of 32-bit Integer by Powers of 2 
;

INCLUDE IO.H        ; header file for input/output

.386                ; Tells MASM to use Intel 80386 instruction set.
.MODEL FLAT         ; Flat memory model
option casemap:none ; Treat labels as case-sensitive

.CONST              ; Constant data segment
    PROMPT_4_PAUSE          BYTE "Hit Enter to exit: ", 0
    PROMPT_4_MULTIPLICAND   BYTE "Input multiplicand: ", 0
    ENDL                    BYTE    13, 10, 0
    TXT_BAD_FORMAT          BYTE    "*** Bad format, please retry!", 0
    TXT_BAD_MULTIPLICAND    BYTE    "*** A multiplicand (2^m) should be between 0 and 31", 0
    TXT_LINE                BYTE    "__________________________________________________________________", 0
    
.STACK 100h         ; (default is 1-kilobyte stack)

.DATA               ; Begin initialised data segment
    ; multiplier * ( 2^k + 2^m + 2^n ) = multiplier * 2^k + multiplier * 2^m + multiplier * 2^n
    multiplier      DWORD  7
    k_multiplicand  BYTE   0
    m_multiplicand  BYTE   0
    n_multiplicand  BYTE   0
    product         DWORD  ?

    ; memory to get user input
    buffer            BYTE    12 DUP (?), 0

    ; memory for converting integers to text
    dtoa_buffer     BYTE    11 DUP (?), 0
    
    ; bit output buffer reserving space for 32 bits and 32 spaces
    bit_buffer      BYTE    64 dup(' '), 0

        
.CODE               ; Begin code segment
_main PROC          ; Main entry point into program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the input
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
multiplicand_k_input:
    output  PROMPT_4_MULTIPLICAND
    input   buffer, SIZEOF buffer
    atod    buffer    ; convert input to the value in EAX
    jno     @F
    ; handle the error
    output  TXT_BAD_FORMAT
    output  ENDL
    jmp     multiplicand_k_input
@@:
    ; EAX contains the number of bits to shift
    ; validate this value
    cmp     EAX, 31
    jna     @F                  ; if ( EAX <= 31 ) everything is okay
    ; handle bad input
    output  TXT_BAD_MULTIPLICAND
    output  ENDL
    jmp     multiplicand_k_input
@@:
    mov BYTE PTR [k_multiplicand], al
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Handle the computation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov [product], 0            ; clear up the result
    mov eax, [multiplier]       ; load the multiplier
    mov cl, [k_multiplicand]
    shl eax, cl                 ; multiplier * 2^k
    mov [product], eax          ; accumulate intermediate value

    mov eax, [multiplier]       ; load the multiplier
    mov cl, [m_multiplicand]
    shl eax, cl                 ; multiplier * 2^m
    add [product], eax          ; accumulate intermediate value

    mov eax, [multiplier]       ; load the multiplier
    mov cl, [n_multiplicand]
    shl eax, cl                 ; multiplier * 2^n
    add [product], eax          ; accumulate intermediate value

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Display results
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    dtoa dtoa_buffer, [product] ; convert
    output  dtoa_buffer         ; print numeric result
    output  ENDL                ; print new line
    ; display in binary form

    mov eax, [product]
    call eax_2_bit_buffer       ; convert EAX to binary string
    output  bit_buffer          ; print binary digits
    output  ENDL                ; print new line

    output  PROMPT_4_PAUSE
    input   buffer, SIZEOF buffer
    ret

_main ENDP


; Procedure to calculate positions of white space
; Input is ECX, the position counter
; We want to insert space after every 4th binary digit
; The procedure returns CF (Carry Flag)
; CF=1 indicates the need to insert space
; CF=0 cleared otherwise
is_space_needed PROC
    push eax
    push edx
    push ecx
    mov         eax, ecx
    xor         edx, edx    ; set EDX = 0
    SPACE_OUTPUT_POSITION equ 8
    mov         ecx, SPACE_OUTPUT_POSITION
    div         ecx         ; DX = EAX % ECX, AX = EAX / ECX
    test        edx, edx  
    clc                     ; clear carry flag
    jnz         @F
    ; result of div is zero
    stc                     ; set carry flag
@@:
    pop ecx
    pop edx
    pop eax
    ret
is_space_needed ENDP


; Procedure to convert EAX to bits in bit_buffer
; EAX contains integer to convert
eax_2_bit_buffer PROC
    push eax                ;  preserve registers
    push ecx
    push edx
    push esi
    mov ecx,32              ; number of bits in EAX
    mov esi, OFFSET bit_buffer ; using global variable
next_bit:
    call is_space_needed    ; returns CF if extra space is needed
    jnc @F
    inc esi
@@:
    shl eax, 1              ; shift high bit into Carry flag
    mov BYTE PTR [esi], '0' ; display zero by default
    jnc next_byte           ; if no Carry, advance to next byte
    mov BYTE PTR [esi], '1' ; otherwise display 1
next_byte:
    inc esi                 ; next buffer position
    loop next_bit           ; shift another bit to left
    pop esi                 ; restore registers
    pop edx
    pop ecx
    pop eax
    ret
eax_2_bit_buffer ENDP


END _main       ; Marks the end of the module and sets the program entry point label
