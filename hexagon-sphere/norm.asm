        .text
.globl normalize
        .type   normalize, @function
normalize:
#NO_APP
        pushq   %rbp
        movq    %rsp, %rbp
#       movq    %rdi, -8(%rbp)
#       movq    -8(%rbp), %rdx
#       movq    -8(%rbp), %rax
        movq    %rdi, -8(%rbp)
        movq    %rsi, -16(%rbp)
        movq    %rdx, -24(%rbp)
        movq    -8(%rbp), %rdi
        movq    -16(%rbp), %r8
        movq    -24(%rbp), %rsi
        movq    -8(%rbp), %rcx
        movq    -16(%rbp), %rdx
        movq    -24(%rbp), %rax


#APP    
##	mov	eax,	vector
##	movaps	xmm0,	[eax]
#       movups	(%rax),	%xmm0
	movups	(%rdi),	%xmm0
	movups	(%r8),	%xmm3
	movups	(%rsi),	%xmm6
	
##	movaps	xmm2,	xmm0
#	movaps	%xmm0,	%xmm2
	movaps	%xmm0,	%xmm2
	movaps	%xmm3,	%xmm5
	movaps	%xmm6,	%xmm7

##	mulps	xmm0,	xmm0
#	mulps	%xmm0,	%xmm0
	mulps	%xmm0,	%xmm0
	mulps	%xmm3,	%xmm3
	mulps	%xmm6,	%xmm6

##	movaps	xmm1,	xmm0
#	movaps	%xmm0,	%xmm1
	movaps	%xmm0,	%xmm1
	movaps	%xmm3,	%xmm4
# Defer vector 3

##	shufps	xmm0,	xmm0,	_MM_SHUFFLE (2, 1, 0, 3)
#	shufps	$0x4e,	%xmm0,	%xmm0
	shufps	$0x4e,	%xmm0,	%xmm0
	shufps	$0x4e,	%xmm3,	%xmm3
# Defer vector 3

##	addps	xmm1,	xmm0
#	addps	%xmm0,	%xmm1
	addps	%xmm0,	%xmm1
	addps	%xmm3,	%xmm4
# Defer vector 3

##	movaps	xmm0,	xmm1
#	movaps	%xmm1,	%xmm0
	movaps	%xmm1,	%xmm0
	movaps	%xmm4,	%xmm3
# Defer vector 3

##	shufps	xmm1,	xmm1,	_MM_SHUFFLE (1, 0, 3, 2)
#	shufps	$0x11,	%xmm1,	%xmm1
	shufps	$0x11,	%xmm1,	%xmm1
	shufps	$0x11,	%xmm4,	%xmm4
# Defer vector 3

##	addps	xmm0,	xmm1
#	addps	%xmm1,	%xmm0
	addps	%xmm1,	%xmm0
	addps	%xmm4,	%xmm3
# Deferred Vector 3 stuff here
	movaps	%xmm6,	%xmm4

##	rsqrtps	xmm0,	xmm0
#	rsqrtps	%xmm0,	%xmm0
	rsqrtps	%xmm0,	%xmm0
	rsqrtps	%xmm3,	%xmm3
# Deferred Vector 3 stuff here
	shufps	$0x4e,	%xmm6,	%xmm6

##	mulps	xmm0,	xmm2
#	mulps	%xmm2,	%xmm0
	mulps	%xmm2,	%xmm0
	mulps	%xmm5,	%xmm3
# Deferred Vector 3 stuff here
	addps	%xmm6,	%xmm4

##	movaps	[eax],	xmm0	
#       movups %xmm0, (%rdx)
	movups	%xmm0,	(%rcx)
	movups	%xmm3,	(%rdx)
# Deferred Vector 3 stuff here
	movaps	%xmm4,	%xmm6
	shufps	$0x11,	%xmm4, %xmm4
	addps	%xmm4,	%xmm6
	rsqrtps	%xmm6,	%xmm6
	mulps	%xmm7,	%xmm6
	movups	%xmm6,	(%rax)

#NO_APP
	leave  
	ret  
