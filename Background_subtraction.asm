# The purpose of this work is to implement in MIPS-32 assembly language a program capable of reading a small sequence of PGM
# [3] files and creating another PGM file as output containing the background model calculated based on the input set. 
# The program's output should contain an image of the scene's background model, as can be seen in the example images in this text, 
# where one image contains vehicles and another containing only the scene without moving objects.


.data 
	arquivo: .asciiz "C:\\Users\\codms\\Documents\\Org. Comp\\Frames\\pgm_P2\\frame00050.pgm"		# string com nome do arquivo
	sucesso: .asciiz "ok id:"
	erro: .asciiz "erro ao abrir arquivo"
	dados_lidos: .asciiz "\nDadis lidos do cabe�lho: "
	
	# .space N � uma diretiva do montador (assembler)
	buffer_leitura: .space 21 		# reserva um espa�o de leitura na mem�ria
.text

.globl main

main:
	li $v0, 13		# atribui 13 para o syscall (abrir um arquivo) em v0		
	la $a0, arquivo		# carrega o endereco da string "arquivo" para argumento de syscalll
	 # $a1: O modo de abertura (0 = para leitura, 1 = para escrita).
	li $a1, 0		# carrega o valor 0 (modo leitura) no segundo argumento
	syscall
	
	# ap�s o syscall o valor fica em v0
	# Se $v0>0 � o "File Descriptor" (ID do arquivo aberto). v0 pode ser 0?
	
	blt $v0, $zero, erro_de_abertura		# se v0 for negativo, indica erro e salta pra sess�o selecionada
	
	move $s0, $v0		 # Salva o File Descriptor em $s0 para nao perde
	
	# imprime se der certo
	
	li $v0, 4
	la $a0, sucesso
	syscall
	
	# imprime o valor inteiro retornado
	
	li $v0, 1		# syscall 1 para imprimir inteiro
	move $a0, $s0
	syscall
	
	# ler uma parte do arq. (cabe�alho)
	
	li $v0, 14		# carreca o c�digo da syscall 14 (read from file)
	move $a0, $s0		# arg 1: o id (file descriptor)
	la $a1, buffer_leitura	# arg 2: o endereco do buffer de memomria
	li $a2, 20		# arg 3: ler no m�x. 20 bytes
	syscall
	
	# imprimndo string "dados lidos"
	
	li $v0, 4		# syscall string
	la $a0, dados_lidos
	syscall
	
	# imprimindo o conte�do do buffer
	
	li $v0, 4		# syscall string
	la $a0, buffer_leitura
	syscall
	
	j fim_programa		 # Continua para o final do programa
	
erro_de_abertura:
	li $v0, 4
	la $a0, erro
	syscall
	
fim_programa:

	# fecha o arquivo com syscall 16
	li $v0, 16
	move $a0, $s0
	syscall
	
	# fnaliza execu��o com syscall 10
	li $v0, 10
	syscall
	