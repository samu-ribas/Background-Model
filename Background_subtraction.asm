# The purpose of this work is to implement in MIPS-32 assembly language a program capable of reading a small sequence of PGM
# [3] files and creating another PGM file as output containing the background model calculated based on the input set. 
# The program's output should contain an image of the scene's background model, as can be seen in the example images in this text, 
# where one image contains vehicles and another containing only the scene without moving objects.


.data 
	nome_arquivo: .asciiz "frame00050.pgm"		# string com nome do arquivo
	
	# Mensagens para o console
	msg_status: .asciiz "\nProcessado: "
    	msg_erro: .asciiz "ERRO AO ABRIR"
	msg_final: .asciiz "\n\nProcesso concluído.."
    	msg_dimensoes: .asciiz "\nDimensões da imagem (LxA): "
    	msg_max: .asciiz "\nValor Maximo: " 
    	
	buffer_leitura: .space 1000000	# Buffer para ler o cabeçalho do arquivo
		
.text
.globl main

main:
	# ALOCANDO MEMÓRIA PARA A MATRIZ
	la $a0, nome_arquivo	
	li $v0, 13		# syscall 13 abre  arquivo
	 li $a1, 0
	syscall
	move $s0, $v0
	
	li $v0, 14		# lendo o arquivo somente uma pequena parte do cabeçalho
	move $a0, $s0
	la $a1, buffer_leitura
	li $a2, 999999		# le 100000 bytes
	syscall
	
	li $v0, 16		# fecha o arquivo temporariamente
	move $a0, $s0
	syscall
	
	la $a0, buffer_leitura	# extrai a largura do buffer
	
ignora_primeira_linha_inicial:
	lb $t1, 0($a0)		
	addi $a0, $a0, 1	# avança uma palavra de bit
	li $t2, 10		# 10 em ascii é \n
	bne $t1, $t2, ignora_primeira_linha_inicial
	
	jal ler_prox_int
	move $s1, $v0		# salva a largura
	jal ler_prox_int
	move $s2, $v0		# salva a altura
	jal ler_prox_int
	move $s3, $v0		# salva o max
	
	# Imprime as dimensões encontradas
    	li   $v0, 4
    	la   $a0, msg_dimensoes
    	syscall
    	
	li   $v0, 1
    	move $a0, $s1
    	syscall
    	
    	li   $v0, 1
    	move $a0, $s2
    	syscall
    	
    	li   $v0, 4
    	la   $a0, msg_max
    	syscall
    	
   	li   $v0, 1
    	move $a0, $s3
    	syscall
    	
    	# ALOCA E ZERA A MATRIZ
	mult $s1, $s2		# altura * largra
	mflo $t0		# $t0 = total de pixels
	
	li $t1, 4
	mult $t0, $t1
	mflo $a0		# $a0 - ttal  de bytes
	
	li $v0, 9	
	syscall			# aloca memoria
	move $s4, $v0		# aponta para matriz soma

	move $t1, $s4		# ponteiro para navegar pela matriz soma
	move $t2, $t0		# contador de pixels

zerar_loop: # zerando tudo pra não somar lixo 
	beqz $t2, fim_zerar_loop	# se t2 for = 0, pula pra fim_zerar_loop
	sw $zero, 0($t1)		# zerando a matriz
	addi $t1, $t1, 4		# movendo o ponteiro
	addi $t2, $t2, -1		# descrementando o contador de pixel
	j zerar_loop
fim_zerar_loop: 

	# INICIO DO LOOP PRINCIPAL DOS ARQUIVOS
	li $s5, 50            	# $s5 = contador do loop
    	li $s6, 100           	# $s6 = condição de parada, loop vai de 50 até < 100
    	la $s7, nome_arquivo   	# $s7 = ponteiro para a string do nome do arquivo
    	
loop_arquivos:    # --- ATUALIZAR O NOME DO ARQUIVO ---
    	li $t0, 10
    	div $s5, $t0            # divide o contador ($s5) por 10
    	mflo $t1                # $t1 = Quociente (primeiro dígito)
    	mfhi $t2                # $t2 = resto (segundo dígito)
    	
    	addi $t1, $t1, '0'      # converte primeiro dígito para char ASCII
    	addi $t2, $t2, '0'      # converte segundo dígito para char ASCII
	
	# ALTERANDO O NOME DO ARQUIVO, neste caso como estamos usando sb, nao precisa fazer alinhamento de memória
    	sb $t1, 8($s7)         	# salva o primeiro digito na string
    	sb $t2, 9($s7)         	# salva o segundo dígito na string 

	# Imprime status
    	li   $v0, 4
    	la   $a0, msg_status
    	syscall
    
    	li   $v0, 4
    	la   $a0, nome_arquivo
    	syscall
    	
	# --- ABRIR O ARQUIVO ATUAL ---
    	li $v0, 13
    	la $a0, nome_arquivo
    	li $a1, 0
    	syscall
    
    	bltz $v0, erro		# Se der erro, pula para o final deste loop
    	move $s0, $v0           # Salva o File Descriptor id
    	
	# --LER O CABEÇALHO PARA O BUFFER----
	li $v0, 14		# carreca o código da syscall 14 (read from file)
	move $a0, $s0		# arg 1: file descriptor)
	la $a1, buffer_leitura	# arg 2: o endereco do buffer de memomria
	li $a2, 999999		# arg 3: ler no máx. 39 bytes
	syscall
	
	la   $a0, buffer_leitura  # $t0 = ponteiro, prepara o argumento

	# ---IGNORAR A PRIMEIRA LINHA ATÉ \n -----------------------------------------------------
ignorar_primeira_linha:
	lb $t1, 0($a0)		# carrega um caractere
	addi $a0, $a0, 1	# sempre avanca o ponteiro
	li $t2, 10		# 10 em ascii é \n
	bne $t1, $t2, ignorar_primeira_linha	# se nao for newline, continue o loop
	
	# Avança os ponteirs para largura, altura e valor max
	jal ler_prox_int
	jal ler_prox_int
	jal ler_prox_int
	
	# --- LER OS PIXELS DESTE ARQUIVO E SOMAR NA MATRIZ ---
	move $t5, $s4         	# $t1 = ponteiro para a matriz de soma (reinicia do começo)
    	mult $s1, $s2
    	mflo $t0              	# $t0 = contador de pixels para este frame
		
loop_soma_pixels:
	beqz $t0, fim_soma
		
	jal ler_prox_int	# le o rixel do buffer do arquivo atual
	move $t2, $v0		# $t2 = valor do novo pixel
	
	lw $t3, 0($t5)		# carrega o valor de soma atual da matriz
	add $t3, $t3, $t2	# soma o novo ixel ao valor acumulado
	sw $t3, 0($t5)		# salva a nova soma de  volta na matriz
	
	addi $t5, $t5, 4	# avança o ponteiro da matriz
	addi $t0, $t0, -1	# decrementa o contador de pixels
	j loop_soma_pixels
fim_soma:

	# --- FECHAR O ARQUIVO ATUAL ---
     	li $v0, 16
    	move $a0, $s0
    	syscall
    
    	# pula por cima do bloco de mensagem de erro
    	j atualizar_loop
	
# -----------------------------------------------------------------------
erro: 
    	# só é executado se o 'bltz' lá de cima detectar um erro real
   	 li   $v0, 4
    	la   $a0, msg_erro
    	syscall
    
atualizar_loop:
   	# --- ATUALIZAR O LOOP ---
    	addi $s5, $s5, 1
    	blt $s5, $s6, loop_arquivos # Se contador < 100, processa o próximo arquivo

    	li $v0, 4
    	la $a0, msg_final
    	syscall
    	# Se o loop terminou, vai para o fim do programa
    	j saida
#------------------------------------------------------------------------

ler_prox_int: 
	li $v0, 0		# $s1 vai acumular o número (a largura)
	li $t3, 0		# $t3 = flag, onde: 0 = procurando num, 1 = achei o num
	
loop_interno: 
	lb $t1, 0($a0)		# carrega o dígito atual
	beqz $t1, fim_do_loop
	
	# verifica se o caractere atal ainda é dígito. Se não for, o número acabou
	li $t2, '0'		# carrega um byte ( caractere apontado por $t0)
    	blt $t1, $t2, nao_e_digito
    	li $t2, '9'
    	bgt $t1, $t2, nao_e_digito
	
	li $t3, 1		# Seta a flag para 1
	# Converte o caractere para inteiro 
	li   $t2, '0'        	# Carrega o valor ASCII de '0' (que é 48) em um registrador temporário $t2
	sub  $t1, $t1, $t2   	# $t1 = $t1 - $t2
	
	# acumula o número $s1 = ($s1 * 10) + digito
	li $t2, 10
	mult $v0, $t2		# multiplica o número atual por 10
	mflo $v0		# copia o valor que está no registrador LO para o registrador de destino $s1
	add $v0, $v0, $t1	# adiciona o novo dígito
	j prox_char
	
nao_e_digito:
    	beqz $t3, prox_char 	# Se $t3 for 0, significa que ainda nem começou ler o número 
    	j fim_do_loop    	# Se $t3 for 1, significa que estávamos lendo um número e ele acabou de terminar.
	
prox_char:
	addi $a0, $a0, 1	# avança o ponteiro para o próximo caractere
	j loop_interno
	
fim_do_loop:
	jr $ra

saida:
	li $v0, 10		# fnaliza execuçao com syscall 10
	syscall
