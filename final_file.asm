# The purpose of this work is to implement in MIPS-32 assembly language a program capable of reading a small sequence of PGM
# [3] files and creating another PGM file as output containing the background model calculated based on the input set. 
# The program's output should contain an image of the scene's background model, as can be seen in the example images in this text, 
# where one image contains vehicles and another containing only the scene without moving objects.


.data 
	nome_arquivo: .asciiz "frame00050.pgm"		# string com nome do arquivo
	# Mensagens para o console
	msg_status: .asciiz "\nProcessado: "
    	msg_erro_abrir: .asciiz "ERRO AO ABRIR"
	msg_final: .asciiz "\n\nProcesso concluído...Matriz de soma preenchida"
    	msg_dimensoes: .asciiz "\nDimensões da imagem (LxA): "
	newline: .asciiz "\n"
	msg_teste_soma: .asciiz "\n--- Testando Valores da SOMA ---\n"
    	msg_soma_pixel: .asciiz "Soma Pixel["
    	msg_fecha_col:  .asciiz "]: "
	buffer_leitura: .space 8192	# buffer para leitura 8KB
.text
.globl main
main: 
	la $a0, nome_arquivo	
	addi $v0, $zero, 13	# syscall 13 abre  arquivo
	addi $a1, $zero, 0	# Flag de modo (0 para leitura)
	syscall
	blt $v0, $zero, erro_abertura   # Se v0 < 0, houve erro
	add $s0, $v0, $zero
	
	addi $v0, $zero, 14	# lendo o arquivo somente uma pequena parte do cabeçalho
	add $a0, $s0, $zero	# salva o file descriptor
	la $a1, buffer_leitura
	addi $a2, $zero, 100	# le somente o cabecalho para extrair a largura e altura
	syscall
	
	addi $v0, $zero, 16	# fecha o arquivo temporariamente
	add $a0, $s0, $zero
	syscall

	la $a0, buffer_leitura	# carrega o endereço de memória do buffer de leitura (ponteiro para o inicio do buffer)
	
ignora_primeira_linha_inicial:
	lb $t1, 0($a0)		# carrega um único byte da memória onde está a0
	addi $a0, $a0, 1	# avança uma palavra 
	addi $t2, $zero,10		# 10 em ascii é \n 
	bne $t1, $t2, ignora_primeira_linha_inicial # compara o caracter que acabou de ser lido com '\n'
	
	jal ler_prox_int
	nop
	add $s1, $v0, $zero	# salva a largura ($v0 retorna com a largura)
	jal ler_prox_int
	nop
	add $s2, $v0, $zero	# salva a altura ($v0 retorna com a altura)
	
	# Imprime as dimensões encontradas ---------------------------------------------------------------
	addi $sp, $sp, -4
	sw $a0, 0($sp)

    	addi $v0, $zero, 4
    	la $a0, msg_dimensoes
    	syscall
    	
	addi $v0, $zero, 1
    	add $a0, $s1, $zero
    	syscall
    	
    	addi $v0, $zero, 1
    	add $a0, $s2, $zero
    	syscall
    	
    	# ALOCA E ZERA A MATRIZ -----------------------------------------------------
	mul $t0, $s1, $s2		# altura * largra $t0 = total de pixels
	add $t2, $t0, $zero
	sll $a0, $t0, 2
	addi $v0, $zero, 9	
	syscall				# aloca memoria
	add $s7, $v0, $zero		# aponta para matriz soma
	add $t1, $s7, $zero		# ponteiro para navegar pela matriz soma
	
zerar_loop: # zerando a matriz para não somar lixo 
	beq $t2, $zero, fim_zerar_loop	# se t2 for = 0, pula pra fim_zerar_loop
	sw $zero, 0($t1)		# zerando a matriz
	addi $t1, $t1, 4		# movendo o ponteiro
	addi $t2, $t2, -1		# descrementando o contador de pixel
	j zerar_loop
fim_zerar_loop: 
	
	addi $s4, $zero, 50
	addi $s5, $zero, 53
	la $s6, nome_arquivo
	# loop dos arquivos para somar na matriz final
loop_arquivos:
	addi $t0, $zero, 10
	div $s4, $t0
	mflo $t1
	mfhi $t2
	
	addi $t1, $t1, '0'
	addi $t2, $t2, '0'
	
	sb $t1, 8($s6)
	sb $t2, 9($s6)
	
	addi $v0, $zero, 4
	la $a0, msg_status
	syscall
	
	addi $v0, $zero, 4
	la $a0, nome_arquivo
	syscall
	
	addi $v0, $zero, 13
	addi $a1, $zero, 0
	la $a0, nome_arquivo
	syscall
	
	blt $v0, $zero, erro_abertura
	add $s0, $v0, $zero
	
	la $s3, buffer_leitura
	add $t6, $s3, $zero	# $t6 = ponteiro móvel do buffer
	add $t7, $zero, $zero	# $t7 = contador de bytes do buffer

	# PULA O CABEÇALHO (lendo e descartando bytes do ARQUIVO)
	jal ler_prox_int_do_arquivo
    	nop
	jal ler_prox_int_do_arquivo
	nop
	jal ler_prox_int_do_arquivo
	nop

	#mul $t0, $s1, $s2 *****************
	addi $t0, $zero, 3
	add $t5, $s7, $zero
			
loop_soma_pixels:
    	beq $t0, $zero, fim_soma	#condição de parada
 
    	jal ler_prox_int_do_arquivo        # le o pixel do buffer do arquivo atual
    	nop
    	add $t2, $v0, $zero	# $t2 = valor do pixel

    	lw $t3, 0($t5)          # carrega o valor de soma atual da matriz
    	add $t3, $t3, $t2       # soma o novo pixel ao valor acumulado
    	sw $t3, 0($t5)          # salva a nova soma de volta na matriz
    
    	addi $t5, $t5, 4        # avança o ponteiro da matriz
    	addi $t0, $t0, -1       # decrementa o contador de pixels
    	
    	j loop_soma_pixels
fim_soma:
	
	addi $v0, $zero, 16
    	add $a0, $s0, $zero
    	syscall
    	
	addi $s4, $s4, 1	# incrementa o contador do nome do arquivo
	blt $s4, $s5, loop_arquivos
	

	addi $t0, $zero, 3	# t0 = numero de arquivos
	
	mul $t1, $s1, $s2	# t1 = ttal de pixels (contador do loop)
	add $t2, $s7, $zero		# t3 = poteiro para matriz
	
loop_divisao:
	beq $t1, $zero, fim_divisao
	lw $a0, 0($t2)		# carrega o valor da SOMA
	div $a0, $t0		# divide soma / n
	mflo $a1		# $a1 = resultado (media)
	
	sw $a1, 0($t2)		# salva a media na matriz
	
	addi $t2, $t2, 4	# avança o ponteiro
	addi $t1, $t1, -1	# decrementa o contador
	j loop_divisao

	
ler_prox_int_do_arquivo:
	addi $sp, $sp, -4
    	sw $ra, 0($sp)                  # Salva o endereço de retorno
    	
    	addi $v0, $zero, 0		# Inicializa o valor de retorno (acumulador do número)

# --- Loop para ignorar caracteres não-numéricos  --------------------------------------------------------
loop_ignora_espaco:
    	blez $t7, reabastecer_buffer	# Se o buffer estiver vazio, reabasteça-o
	nop

    	lb $t1, 0($t6)			# Lê o próximo caractere do buffer

    	# Verifica se é um dígito entre '0' e '9'
    	blt $t1, '0', nao_e_digito
    	bgt $t1, '9', nao_e_digito

    	# Se chegamos aqui, é um dígito. Fim do loop de ignorar.
    	j loop_monta_inteiro

nao_e_digito:
    	addi $t6, $t6, 1		# Avança o ponteiro no buffer
    	addi $t7, $t7, -1		# Decrementa o contador de bytes válidos
    	j loop_ignora_espaco

# --- Loop para montar o número inteiro a partir dos dígitos -----------------------------------------------
loop_monta_inteiro:
    	blez $t7, reabastecer_buffer	# Se o buffer estiver vazio no meio de um número, reabasteça-o
    	nop

    	lb $t1, 0($t6)			# Lê o próximo caractere

    	# Verifica se ainda é um dígito
    	blt $t1, '0', fim_do_numero
    	bgt $t1, '9', fim_do_numero
 
    	subi $t1, $t1, '0'		# Converte o caractere do dígito para seu valor numérico

    	# Acumula o valor: resultado = resultado * 10 + novo_digito
    	addi $t2, $zero, 10
    	mul $v0, $v0, $t2
	add $v0, $v0, $t1

    	# Avança para o próximo caractere
    	addi $t6, $t6, 1
    	addi $t7, $t7, -1
	j loop_monta_inteiro

# --- Seção para reabastecer o buffer de leitura --------------------------------------------------------
reabastecer_buffer:
    	addi $v0, $zero, 14		# syscall 14: Ler do arquivo
	add $a0, $zero, $s0		# File descriptor
    	add $a1, $zero, $s3		# Destino é o início do buffer
    	addi $a2, $zero, 8192		# Tenta ler 8KB
	syscall
    
    	add $t7, $v0, $zero		# Atualiza o contador com o número de bytes lidos
    	add $t6, $s3, $zero		# Reseta o ponteiro para o início do buffer
    
    	blez $t7, fim_do_arquivo	# Se a leitura retornou 0 ou menos bytes, é o fim do arquivo.
    	nop 

    	j loop_ignora_espaco		# voltar para o início da função.

fim_do_numero:
    	j restaurar_e_retornar

fim_do_arquivo:    			# Se chegamos ao fim do arquivo, o valor em $v0 é o que conseguimos
    	
restaurar_e_retornar:
    	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra                          # Retorna para o chamador
	
