# The purpose of this work is to implement in MIPS-32 assembly language a program capable of reading a small sequence of PGM
# [3] files and creating another PGM file as output containing the background model calculated based on the input set. 
# The program's output should contain an image of the scene's background model, as can be seen in the example images in this text, 
# where one image contains vehicles and another containing only the scene without moving objects.


.data 
	arquivo: .asciiz "C:\\Users\\codms\\Documents\\Org. Comp\\Frames\\pgm_P2\\frame00050.pgm"		# string com nome do arquivo
	sucesso: .asciiz "ok id:"
	erro: .asciiz "erro ao abrir arquivo"
	dados_lidos: .asciiz "\nDadis lidos do cabeçlho: "
	msg_largura: .asciiz "\nLargura extraida:"
	
	# .space N é uma diretiva do montador (assembler)
	buffer_leitura: .space 21 		# reserva um espaço de leitura na memória
.text

.globl main

main:
	li $v0, 13		# atribui 13 para o syscall (abrir um arquivo) em v0		
	la $a0, arquivo		# carrega o endereco da string "arquivo" para argumento de syscalll
	 # $a1: O modo de abertura (0 = para leitura, 1 = para escrita).
	li $a1, 0		# carrega o valor 0 (modo leitura) no segundo argumento
	syscall
	
	# após o syscall o valor fica em v0
	# Se $v0>0 é o "File Descriptor" (ID do arquivo aberto). v0 pode ser 0?
	
	blt $v0, $zero, erro_de_abertura		# se v0 for negativo, indica erro e salta pra sessão selecionada
	
	move $s0, $v0		 # Salva o File Descriptor em $s0 para nao perde
	
	# imprime se der certo
	
	li $v0, 4
	la $a0, sucesso
	syscall
	
	# imprime o valor inteiro retornado
	
	li $v0, 1		# syscall 1 para imprimir inteiro
	move $a0, $s0
	syscall
	
	# ler uma parte do arq. (cabeçalho)
	
	li $v0, 14		# carreca o código da syscall 14 (read from file)
	move $a0, $s0		# arg 1: o id (file descriptor)
	la $a1, buffer_leitura	# arg 2: o endereco do buffer de memomria
	li $a2, 20		# arg 3: ler no máx. 20 bytes
	syscall
	
	# imprimndo string "dados lidos"
	
	li $v0, 4		# syscall string
	la $a0, dados_lidos
	syscall
	
	# imprimindo o conteúdo do buffer
	
	li $v0, 4		# syscall string
	la $a0, buffer_leitura
	syscall
	
	la $t0, buffer_leitura
	
	# 3 - fazer o emparelhamento do cabeçalho para obter a largura
	
	la $t0, buffer_leitura		#$t0 é o ponteiro. Aponta para o caractere atual que estamos lendo
	li $s1, 0			# $s1 vai acumular nosso número( a largura)
	

	# primeiro pular tudo que nao for digitos
pular_nao_digitos
	lb $t1, 0($t0)			# carrega um byte ( caractere apontado por $t0)
	blt $t1, '0', proximo_char	
	bgt $t1, '9', proximo_char
	j loop_leitura_numero
	
	
proximo_char:
	addi $t0, $t0, 1
	j pular_nao_digitos
	
loop_leitura_numero:
	lb $t1, 0($t0)
	
	blt $t1, '0', fim_numero
	bgl $t1, '9', fim_numero

	addi $t1, $t1, -'0'
	li $t2, 10
	mult $s1, $t2
	mflo $s1
	add $s1, $s1, $t1
	
	addi $t0, $t0, 1
	
	j loop_leitura_numero
	
fim_numero:
	li $v0, 1
	la $a0, msg_largura
	syscall
	
	li $v0, 1
	move $a0, $s1
	syscall
			
erro_de_abertura:
	li $v0, 4
	la $a0, erro
	syscall
	
fim_programa:

	# fecha o arquivo com syscall 16
	li $v0, 16
	move $a0, $s0
	syscall
	
	# fnaliza execução com syscall 10
	li $v0, 10
	syscall
	
