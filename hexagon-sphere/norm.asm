        .text
.globl normalize
        .type   normalize, @function
normalize:
#NO_APP
        pushq   %rbp
        movq    %rsp, %rbp
        movq    %rdi, -8(%rbp)
        movq    -8(%rbp), %rdx
        movq    -8(%rbp), %rax 

#APP    
#	mov	eax,	vector
#	movaps	xmm0,	[eax]
        movups	(%rax),	%xmm0
	
#	movaps	xmm2,	xmm0
	movaps	%xmm0,	%xmm2

#	mulps	xmm0,	xmm0
	mulps	%xmm0,	%xmm0

#	movaps	xmm1,	xmm0
	movaps	%xmm0,	%xmm1

#	shufps	xmm0,	xmm0,	_MM_SHUFFLE (2, 1, 0, 3)
	shufps	$0x4e,	%xmm0,	%xmm0

#	addps	xmm1,	xmm0
	addps	%xmm0,	%xmm1

#	movaps	xmm0,	xmm1
	movaps	%xmm1,	%xmm0

#	shufps	xmm1,	xmm1,	_MM_SHUFFLE (1, 0, 3, 2)
	shufps	$0x11,	%xmm1,	%xmm1

#	addps	xmm0,	xmm1
	addps	%xmm1,	%xmm0

#	rsqrtps	xmm0,	xmm0
	rsqrtps	%xmm0,	%xmm0

#	mulps	xmm0,	xmm2
	mulps	%xmm2,	%xmm0

#	movaps	[eax],	xmm0	
        movups %xmm0, (%rdx)

#	movups xmm0,XMMWORD PTR [rax]
#       movups (%rax), %xmm0
#	movaps xmm2,xmm0
#       movaps %xmm0, %xmm2 
#	mulps  xmm0,xmm0
#       mulps %xmm0, %xmm0 
#	movaps xmm1,xmm0
#       movaps %xmm0, %xmm1
#	shufps xmm0,xmm1,0x4e
#       shufps $0x4e, %xmm1, %xmm0
#	addps  xmm0,xmm1
#       addps %xmm1, %xmm0 
#	movaps xmm1,xmm0
#       movaps %xmm0, %xmm1
#	shufps xmm1,xmm1,0x11
#       shufps $0x11, %xmm1, %xmm1
#	addps  xmm0,xmm1
#       addps %xmm1, %xmm0 
#	rsqrtps xmm0,xmm0
#       rsqrtps %xmm0, %xmm0
#	mulps  xmm2,xmm0
#       mulps %xmm0, %xmm2 
#	movups XMMWORD PTR [rdx],xmm0
#       movups %xmm0, (%rdx)
        
#NO_APP
	leave  
	ret  
