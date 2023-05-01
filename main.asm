; CS 066 
; Brian Luu
INCLUDE Irvine32.inc

.data
    ; define your variables here

    ;Invalid input prompt.
    invalid BYTE "Invalid Input",0

    ;Table driven selection for the operands.
    CaseTable BYTE '+'
            DWORD Addition
    EntrySize = ($ - CaseTable)
            BYTE '-'
            DWORD Subtraction
            BYTE '*'
            DWORD Multiplication
            BYTE '/'
            DWORD Division
            
    NumberOfEntries = ($ - CaseTable) / EntrySize

    inputQueueSize DWORD 0              ;Size up to 4 bytes: (65,535d)
    inputQueue BYTE 100 DUP (?)         ;Making it so that we can store up to 100 places 
    totalSize DWORD 0                   ;Size up to 4 bytes: (65,535d)
    total BYTE 100 DUP (?)              ;Making it so that we can store up to 100 places.

    product1SIZE DWORD 0
    product1 BYTE 100 DUP(?)
    product2SIZE DWORD 0
    product2 BYTE 100 DUP (?)

.code 

;******BUGS*************
; Enter will reset the inputQueueSize
main proc
    ; write your assembly code here

    ;Iteration #2. Only accept #'s
    reloop:
    mov eax, 0                      ;Clears the upper part of eax since readChar only uses al
    mov esi, OFFSET InputQueue      ;Moving the address location of the queue to esi so we can store values in there.
    call readChar                   ;Reads input as characters.
    input:
       call WriteChar               ;Writes the input into the terminal.
       cmp al, '='                  ;If input is = end the program.
       je endOfProgram              
       ;Translation [while(input <= 30h && input >= 39)]
       cmp al, '9'                  ;Checking if the input is within the range of (30h - 39h) upper half.
       ja invalidInput              ;If the input is greater then 39h that means it is not a number or an operand.
       cmp al, '0'                  ;Checking if the input is within the range of (30h - 39h) lower half.
       jb operand                   ;If the input is less than 30h there is a possibility that is it an operand.
       inc inputQueueSize           ;Incrementing the input queue size.

       mov [esi], al                ;Storing the digit into the queue if it's a digit.
       inc esi                      ;Moving to the next byte so we dont overwrite our queue.
       call readChar                ;Grabs a new character          
       jmp input                    ;End of While Loop


    ;Table-driven selection loop.
    operand:
       mov ebx, OFFSET [CaseTable]  ;Moving address of case table to ebx
       mov ecx, NumberOfEntries     ;loop counter
        operandLoop:                    ;Beginning of loop.
           cmp al, [ebx]                ;comparing ebx to the symbol
           jne next                     ;Incrementing to the next symbol.
           mov ecx, esi
           call NEAR PTR [ebx + 1]      ;Calling appropriate function 
           jmp endOfOperandLoop         ;Leaving the loop after calling the function.
        next:
           add ebx, EntrySize           ;Incrementing ebx to the next symbol
           loop operandLoop             ;End of Table-driven selection loop.
        endOfOperandLoop:               ;End of Table-driven selection loop.
           cmp al, '='                  ;If input is = end of program.
           jne reloop                   ;Returning to the beginning after arithmetic to get a new number.
           jmp endOfProgram             ;Jumping past invalidInput to the end of the program.

    

    ;Marker for invalid inputs.    
    invalidInput:
       mov edx, OFFSET invalid      ;moving invalid prompt to edx so we can print it.
       call WriteString             ;printing the edx prompt.


    ;Marker for end of program.
    endOfProgram:
    Invoke ExitProcess,0    
main endp

;Procedure to clear the input queue
;Uses ecx and esi
clearQueue PROC 
    mov ecx, 5                              ;Loop counter clears 5*DWORD of space
    mov esi, OFFSET InputQueue              ;Setting esi to the inputQueue address
        
    Clear:                                  ;Setting DWORD amount of memory at esi to 0 
        mov DWORD PTR [esi], 0 
        add esi, DWORD                      ;Moving to the next DWORD memory location.
    loop Clear

    mov inputQueueSize, 0                   ;Reseting input size

    ret
clearQueue ENDP

;*** Initialize before calling procedure ***
;EDI    OFFSET OF VARIABLE BEGINNING INDEX
;ECX    OFFSET OF VARIABLE ENDING INDEX
;EAX    SIZE OF VARIABLE
;*** Variables used during procedure. ***
;ESI    ADDRESS 
;ECX    LOOP COUNTER
;EDX    DIVISION 
Rotate PROC
    mov esi, ecx                        ;Moving the end index of variable to esi
    
    cmp eax, 1
    jle RotationEnd
    ;cmp DWORD PTR [esi], '9'
    ;jbe RotationEnd

    ;Arithmetic for # of time to rotate memory bytes
    mov ecx, 0                          ;Clearing ecx 
    mov edx, 0                          ;Clearing upper half so we don't get strange values when dividing.
    mov cx, 2                           ;We want to divide by 2 and ignore the remainder else we'll swap back to original values.
    div cx
    mov cx, ax                          ;Storing the amount into cx our loop counter.

    ;Loop that handles the rotation of memory address.
    Rotating:                           ;Swaping bytes
        mov al, [edi]                   ;If odd number we don't need to swap middle.
        xchg al, [esi]                  
        mov [edi], al
        inc edi                         ;Moving -> +1
        dec esi                         ;Moving <- -1 
    loop Rotating
    
    rotationEnd:
    ret
Rotate ENDP

;**********BUG**********
;+ sign without numbers will result in error.
Addition PROC
    ;Rotate both the variables
    mov edi, OFFSET inputQueue                              ;Reversing the order of the memory so we can do arithmetic from front to back instead of back to front.
    mov ecx, OFFSET [inputQueue]
    add ecx, [inputQueueSize]
    dec ecx
    mov eax, [inputQueueSize]
    call Rotate

    mov edi, OFFSET total
    mov ecx, OFFSET [total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    mov eax, DWORD PTR[inputQueueSize]                      ;Updating the size if the input is larger then the already stored total.
    cmp eax, [totalSize]                                    ;if(inputQueue > totalSize)
    jle L158
        mov DWORD PTR [totalSize], eax                      ;total size = inputQueue
    L158:

    call clrscr                                             ;Clearing the screen so we can place the new total at the top left of screen.
    clc                                                     ;Clearing the carry flag.
    mov esi, 0                                              ;Since we're doing arithmetic from left to right we can set our indicies to 0
    mov edi, 0 
    mov eax, 0                                              ;Clearing ax so the ascii arithmetic won't be altered.
    mov ecx, inputQueueSize                                 ;Setting the loop counter to inputQueueSize     //Doesn't matter which one we do becasue if the inputQueue is larger the totalSize would also be set to it.
    Adding:                                             ;Since we reversed the string of numbers we can just do front to back with out worry.
        mov al, total[esi]                                  ;Moving each byte from total into al
        adc al, inputQueue[esi]                             ;Adding that byte with the byte from inputQueue
        aaa                                                 ;Ascii adjustment after addition
        pushf                                               ;Saving flag
        or ax, 3030h                                        ;Changing it back to ascii representation by turning on the 4th and 5th bit
        mov total[edi], al                                  ;Moving the ascii representation of the digit back into the total.
        inc edi                                             ;Getting our next index for total
        inc esi                                             ;Getting our next index for input queue
        popf                                                ;Getting our carry flag back
    loop Adding                                         ;End of the loop.
    

    AdditionCarry:                                          ;Code block for handling carries.
      jnc AdditionNoCarry                                   ;No carry exit loop.
            adc total[edi], 0                               ;If the carry extends another place it wont be of ascii representation
            cmp total[edi], '0'                             ;That's why we check to see if it's an ascii character or not and if it isn't
                                
            jae L192                                        ;We'll turn it into an ascii character and increase the size.
                or total[edi], 30h
                inc totalSize
            L192:

            jmp AdditionCarry                               ;Loop if there is still a carry after arithmetic.
    AdditionNoCarry:

    ;Rotate so it'll print properly.                        ;Rotating the total again else it'll print the number in reverse.
    mov edi, OFFSET total                               
    mov ecx, OFFSET [total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    mov edx, OFFSET total                                   ;Writing the total onto the terminal.
    call WriteString                                        
    call Crlf                                               ;Moving to new line so we can do arithmetic.
    call clearQueue                                         ;Clearing the input queue
    ret
Addition ENDP

Subtraction PROC
    ;Translation if(totalSize > inputQueueSize && total[0] > inputQueue[0]) call SubtractionTotal
    ;            else(totalSize <= InputQueueSize || total[0] < inputQueue) call SubtrationInputQueue

    call clrscr
    mov eax, [totalSize]                                    ;Checking to see which one of the inputs are larger by
    cmp eax, [inputQueueSize]                               ;a.) Checking the size
    jb InputGreater                                         ;b.) Checking the first digit if the size is the same.
   
   mov esi, OFFSET total
   mov edi, OFFSET inputQueue

   mov ecx, totalSize                                       ;Doesn't matter what variable we use to set the loop counter since they're both the same size else the check above would've relocated the program.
   SubtractionLoop:                                         ;Loop to check which number is greater. We can just use the ascii representation since '9' is still greater than '0'
        mov al, [esi]                                       ;Checking index of total
        mov bl, [edi]                                       ;Checking index of inputQueue
        cmp al, bl                                          ;Checking to see which is larger.
        ja TotalGreater                                     ;If larger move to total subtraction proc
        jb InputGreater                                     ;If smaller move to inputQueue subtraction proc
        inc esi                                             ;increment index
        inc edi                                             ;incremnet index
    loop SubtractionLoop                                    ;if the loop is finished and we have not been relocated we know the numbers are the same.
    jmp SameDigits                                          ;We'll move to the code block that'll handle same digit subtraction (line 242)

    InputGreater:                                           ;Code block that calls the Subtraction procedure for when inputQueue is larger.            
        call SubtractionInputQueue                  
        jmp SubtractionEnd                                  ;Jumps to end of program after the procedure is called.
    TotalGreater:                                           ;Code block that calls the Subtraction procedure for when the total is larger.
        call SubtractionTotal                               
        jmp SubtractionEnd                                  ;Jump to end of program after the procedure is called.

    SameDigits:
        mov ecx, 5                                          ;Just being safe and clearing more space then we need to. Loop Counter = 5
        mov esi, OFFSET total                               ;Address to the total.
        TotalToZero:                                        ;Loop
            mov DWORD PTR[esi], 0                           ;Setting total to 0 
            add esi, DWORD                                  ;Moving to the next memory location by DWORD(+4 Bytes)
        loop TotalToZero                                    ;End of Loop

        mov total, '0'                                      ;Setting total to 0 because we just subtracted the total with the same number.
            
        mov edx, OFFSET total                               ;Printing out the string
        call WriteString                    
        call Crlf
        call clearQueue                                     ;Clearing out input queue.

    SubtractionEnd:                                         ;Marker to end of program.
    ret
Subtraction ENDP

SubtractionTotal PROC
   ;Rotating both variables                                 ;Inverting the variables so we can do arithmetic front to back 
    mov edi, OFFSET inputQueue                             
    mov ecx, OFFSET [inputQueue]
    add ecx, [inputQueueSize]
    dec ecx
    mov eax, [inputQueueSize]
    call Rotate

    mov edi, OFFSET total
    mov ecx, OFFSET [total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    clc                                                     ;Clearing the carry flag.
    mov esi, 0                                              ;Index variables
    mov edi, 0                                              ;
    mov eax, 0                                              ;
    mov edx, 0                                              ;
    mov ecx, totalSize                                      ;Loop to the larger variable.
    SubtractingA:                                   ;Start of loop
        mov al, total[esi]                                  ;Moving each byte from total to al
        sbb al, inputQueue[esi]                             ;Subtracting with borrow from inputQueue
        aas                                                 ;Ascii adjustment after subtraction
        pushf                                               ;Saving flags.
        or ax, 3030h                                        ;Converting back into ascii
        mov total[edi], al                                  ;Moving the total back into the total.
        inc edi                                             ;Updating the indicies
        inc esi                                             ;Updating the indicies
        popf                                                ;Getting the carry flag back.
    loop SubtractingA                               ;End of loop
    
    dec edi                                                 ;Decrement edi because it points at the null character currently.
    SubtractionCarryA:                              ;Code block to handle carries and excess zeroes
            cmp total[edi],'0'                              ;If the byte at that location is a zero we'll convert it to a null termination
            jne NoMoreZeroesA                               ;Not a zero we leave loop
            mov total[edi],0                                ;Converting byte to a null termination
            dec totalSize                                   ;Reducing the size
            dec edi                                         ;Updating indicies
            jmp subtractionCarryA                   ;End of while loop
    NoMoreZeroesA:                                          ;Code block that handles carries
        jnc SubtractionNoCarryA                             ;If no carry skip pass the sbb
            sbb total[edi], 0                               ;If carry then subtract from that location.

    SubtractionNoCarryA:                            ;Marker to skip if there is no carry.

                                                            ;Code block to reverse the string "total" again so we can display it.
    mov edi, OFFSET total
    mov ecx, OFFSET [total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    mov edx, OFFSET total                                               ;Writing the total onto the terminal.
    call WriteString                                        
    call Crlf     
    call clearQueue
   ret
SubtractionTOTAL ENDP

SubtractionInputQueue PROC
    ;Rotating both variables                                  ;Inverting the variables so we can do arithmetic front to back 
    mov edi, OFFSET inputQueue                             
    mov ecx, OFFSET [inputQueue]
    add ecx, [inputQueueSize]
    dec ecx
    mov eax, [inputQueueSize]
    call Rotate

    mov edi, OFFSET total
    mov ecx, OFFSET [total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    mov eax, DWORD PTR[inputQueueSize]                      ;Updating the size if the input is larger then the already stored total.
    cmp eax, [totalSize]                                    ;if(inputQueue > totalSize)
    jle L316
        mov DWORD PTR [totalSize], eax                      ;total size = inputQueue
    L316:

    clc                                                     ;Clearing the carry flag.
    mov esi, 0                                              ;Index variables
    mov edi, 0                                              ;
    mov eax, 0                                              ;
    mov edx, 0                                              ;
    mov ecx, totalSize                                      ;Loop to the larger variable.
    SubtractingB:                                   ;Start of loop
        mov al, inputQueue[esi]                             ;Moving each byte from total to al
        sbb al, total[esi]                                  ;Subtracting with borrow from inputQueue
        aas                                                 ;Ascii adjustment after subtraction
        pushf                                               ;Saving flags. 
        or ax, 3030h                                        ;Converting back into ascii
        mov total[edi], al                                  ;Moving the total back into the total.
        inc edi                                             ;Updating the indicies
        inc esi                                             ;Updating the indicies
        popf                                                ;Getting the carry flag back.
    loop SubtractingB                               ;End of loop
    
    dec edi                                                 ;Decrement edi because it points at the null character currently.
    SubtractionCarryB:                              ;Code block to handle carries and excess zeroes
            cmp total[edi],'0'                              ;If the byte at that location is a zero we'll convert it to a null termination
            jne NoMoreZeroesB                               ;Not a zero we leave loop
            mov total[edi],0                                ;Converting byte to a null termination
            dec totalSize                                   ;Reducing the size
            dec edi                                         ;Updating indicies
            jmp subtractionCarryB                   ;End of while loop
    NoMoreZeroesB:                                          ;Code block that handles carries
        jnc SubtractionNoCarryB                             ;If no carry skip pass the sbb
            sbb total[edi], 0                               ;If carry then subtract from that location.

    SubtractionNoCarryB:                            ;Marker to skip if there is no carry.

                                                            ;Code block to reverse the string "total" again so we can display it.
    mov edi, OFFSET total
    mov ecx, OFFSET [total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    mov edx, OFFSET total                                   ;Writing the total onto the terminal.
    call WriteString                                        
    call Crlf     
    call clearQueue
    ret
SubtractionInputQueue ENDP

Multiplication PROC
    call clrscr
    
    cmp inputQueueSize, 1
    jne MultiplyNotZero
    cmp inputQueue, 30h
    jg MultiplyNotZero
    call ClearTotal
    jmp L481

    MultiplyNotZero:


    ;Rotate both the variables
    mov edi, OFFSET inputQueue
    mov ecx, OFFSET [inputQueue]
    add ecx, [inputQueueSize]
    dec ecx
    mov eax, [inputQueueSize]
    call Rotate

    mov edi, OFFSET total
    mov ecx, OFFSET[total]
    add ecx, [totalSize]
    dec ecx
    mov eax, [totalSize]
    call Rotate

    clc 
    mov esi, 0
    mov edi, 0
    mov eax, 0
    mov ebx, 0
    mov edx, 0
    mov ecx, totalSize

    Multiply:
        mov al, total[esi]
        and al, 0CFh
        mov bl, inputQueue[edi]
        and bl, 0CFh
        mul bl
        add al, dl                          ;addin previous carry
        aam
        pushf
        or al, 30h
        push edi
        mov product1[esi], al
        inc product1Size
        pop edi
        mov dl, ah                          ;update the previous cary
        inc esi
        popf
    loop Multiply

    MultiplyCarry:
        cmp dl, 0
        je MultiplyNoCarry
        add product1[esi], dl
        or product1[esi], 30h
        inc product1Size
        jnc MultiplyNoCarry
        mov dl, 1
        inc esi
        jmp MultiplyCarry
    MultiplyNoCarry:

    mov ecx, edi
    push edi
    call AppendZero
    call AddP1P2
    call ClearP1
    pop edi
    mov esi, 0
    mov eax, 0
    mov ebx, 0
    mov edx, 0
    mov ecx, TotalSize
    inc edi

    CMP edi, inputQueueSize
    jne Multiply

    call MoveProductToTotal
    L481:
    mov edx, OFFSET total
    call WriteString
    call Crlf
    call ClearQueue
    call ClearP2

    ret
Multiplication ENDP
    
ClearP1 PROC
    mov ecx, 5                              ;Loop counter clears 5*DWORD of space
    mov esi, OFFSET Product1              ;Setting esi to the inputQueue address
        
    ClearP_1:                                  ;Setting DWORD amount of memory at esi to 0 
        mov DWORD PTR [esi], 0 
        add esi, DWORD                      ;Moving to the next DWORD memory location.
    loop ClearP_1

    mov Product1SIZE, 0                   ;Reseting input size

    ret
ClearP1 ENDP

ClearP2 PROC

    mov ecx, 5                              ;Loop counter clears 5*DWORD of space
    mov esi, OFFSET Product2              ;Setting esi to the inputQueue address
        
    ClearP_2:                                  ;Setting DWORD amount of memory at esi to 0 
        mov DWORD PTR [esi], 0 
        add esi, DWORD                      ;Moving to the next DWORD memory location.
    loop ClearP_2

    mov Product2SIZE, 0                   ;Reseting input size

    ret
ClearP2 ENDP

AddP1P2 PROC
    ;Rotate Both Variables
    mov edi, OFFSET product1
    mov ecx, OFFSET [product1]
    add ecx, [product1Size]
    dec ecx
    mov eax, [product1Size]
    call Rotate
    
    mov edi, OFFSET product2
    mov ecx, OFFSET [product2]
    add ecx, [product2Size]
    dec ecx
    mov eax, [product2Size]
    call Rotate

    mov eax, DWORD PTR [product1Size]
    cmp eax, [product2Size]
    jle L181
        mov DWORD PTR [product2Size], eax
    L181:

    clc
    mov esi, 0
    mov edi, 0 
    mov eax, 0 
    mov ecx, product2Size
    P1P2Adding:
        mov al, product2[esi]
        adc al, product1[esi]
        aaa
        pushf
        or ax, 3030h
        mov product2[edi], al
        inc edi
        inc esi
        popf
    loop P1P2Adding

    ProductAdditionCarry:
        jnc ProductAdditionNocarry
        adc product1[edi], 0
        cmp product2[edi], '0'

        jae L208
            or product2[edi], 31h
            inc product2Size
        L208:

        jmp ProductAdditionCarry
    ProductAdditionNoCarry:

    mov edi, OFFSET product2
    mov ecx, OFFSET [product2]
    add ecx, [product2Size]
    dec ecx
    mov eax, [product2Size]
    call Rotate
    
    mov Product1Size, 0
    ret
AddP1P2 ENDP

AppendZero PROC
    push ecx
    push esi
    mov edi, OFFSET product1
    mov ecx, OFFSET [product1]
    add ecx, [product1Size]
    dec ecx
    mov eax, [product1Size]
    call Rotate
    pop esi
    pop ecx

    cmp ecx, 0
    je noAppend

    AppendLoop:
        mov product1[esi], '0'
        inc product1size
        inc esi
    loop AppendLoop

    noAppend:
    ret
AppendZero ENDP

MoveProductToTotal PROC
    mov edi, OFFSET product2
    mov esi, OFFSET total

    mov ecx, product2Size
    mov totalSize, ecx
    Transfer:
        mov al, [edi]
        xchg [esi], al
        inc edi
        inc esi
    loop Transfer

    ret
MoveProductToTotal ENDP

ClearTotal PROC
   mov ecx, 5
   mov esi, OFFSET total

   Clear_Total:
        mov DWORD PTR[esi], 0
        add esi, DWORD
   loop Clear_Total

   mov TotalSize, 1
   mov Total, '0'

   ret
ClearTotal ENDP

Division PROC
   ret
Division ENDP

end main