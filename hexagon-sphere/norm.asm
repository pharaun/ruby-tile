        .text
.globl normalize
        .type   normalize, @function
normalize:
#NO_APP
#	push   rbp
        pushq   %rbp
#	mov    rbp,rsp
        movq    %rsp, %rbp
#	mov    QWORD PTR [rbp-0x8],rdi
        movq    %rdi, -8(%rbp)
#	mov    rdx,QWORD PTR [rbp-0x8]
        movq    -8(%rbp), %rdx
#	mov    rax,QWORD PTR [rbp-0x8]
        movq    -8(%rbp), %rax 
#APP    
#	movups xmm0,XMMWORD PTR [rax]
        movups (%rax), %xmm0
#	movaps xmm2,xmm0
        movaps %xmm0, %xmm2 
#	mulps  xmm0,xmm0
        mulps %xmm0, %xmm0 
#	movaps xmm1,xmm0
        movaps %xmm0, %xmm1
#	shufps xmm0,xmm1,0x4e
        shufps $0x4e, %xmm1, %xmm0
#	addps  xmm0,xmm1
        addps %xmm1, %xmm0 
#	movaps xmm1,xmm0
        movaps %xmm0, %xmm1
#	shufps xmm1,xmm1,0x11
        shufps $0x11, %xmm1, %xmm1
#	addps  xmm0,xmm1
        addps %xmm1, %xmm0 
#	rsqrtps xmm0,xmm0
        rsqrtps %xmm0, %xmm0
#	mulps  xmm2,xmm0
        mulps %xmm0, %xmm2 
#	movups XMMWORD PTR [rdx],xmm0
        movups %xmm0, (%rdx)
        
#NO_APP
	leave  
	ret  
