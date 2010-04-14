    global normalize	    ; (float v[3])
    extern printf

    section .text

normalize:
    push    message
    call    printf
    add	    esp, 4
    ret

message:
    db	'hello, world', 10, 0
