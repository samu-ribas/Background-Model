# The purpose of this work is to implement in MIPS-32 assembly language a program capable of reading a small sequence of PGM
# [3] files and creating another PGM file as output containing the background model calculated based on the input set. 
# The program's output should contain an image of the scene's background model, as can be seen in the example images in this text, 
# where one image contains vehicles and another containing only the scene without moving objects.


.data 
	nome_arquivo: .asciiz "frame00050.pgm"		# string com nome do arquivo
	nome_arquivo_saida: .asciiz "modelo_de_fundo.pgm"
	
	# Mensagens para o console
	msg_status: .asciiz "\nProcessado: "
    	msg_erro: .asciiz "ERRO AO ABRIR"
	msg_final: .asciiz "\n\nProcesso conclu�do...Matriz de soma preenchida"
    	msg_dimensoes: .asciiz "\nDimens�es da imagem (LxA): "
    	msg_max: .asciiz "\nValor Maximo: " 
    	msg_teste_soma: .asciiz "\n--- Testando Valores da Soma ---\n"
        msg_pixel: .asciiz "Pixel -"
        msg_teste_media: .asciiz "\n--- Testando Valores da M�dia ---\n"
    	
    	# Mensagem para o cabe�alho da matriz da m�dia
    	str_p2: .asciiz "P2\n"
    	str_espaco: .asciiz " "
    	str_newline: .asciiz "\n"
    	
	buffer_leitura: .space 1000000	# buffer para ler o cabe�alho do arquivo
	buffer_escrita: .space 20 	# buffer para escrita no arquivo da matriz da m�dia
		
.text
.globl main

main:
	# ALOCANDO MEM�RIA PARA A MATRIZ
	la $a0, nome_arquivo	
	li $v0, 13		# syscall 13 abre  arquivo
	 li $a1, 0
	syscall
	move $s0, $v0
	
	li $v0, 14		# lendo o arquivo somente uma pequena parte do cabe�alho
	move $a0, $s0		# salva o file descriptor
	la $a1, buffer_leitura
	li $a2, 999999		# le 100000 bytes
	syscall
	
	li $v0, 16		# fecha o arquivo temporariamente
	move $a0, $s0		# salva o novamente o file descriptor antes de fechar pois se n�o $a0 ficar� com lixo, para poder fechar o arquivo
	syscall
	
	la $a0, buffer_leitura	# carrega o endere�o de mem�ria do buffer de leitura (ponteiro para o inicio do buffer)
	
ignora_primeira_linha_inicial:
	lb $t1, 0($a0)		# carrega um �nico byte da mem�ria onde est� a0
	addi $a0, $a0, 1	# avan�a uma palavra 
	li $t2, 10		# 10 em ascii � \n
	bne $t1, $t2, ignora_primeira_linha_inicial # compara o caracter que acabou de ser lido com '\n'
	
	jal ler_prox_int
	move $s1, $v0		# salva a largura
	jal ler_prox_int
	move $s2, $v0		# salva a altura
	jal ler_prox_int
	move $s3, $v0		# salva o max
	
	# Imprime as dimens�es encontradas
    	li $v0, 4
    	la $a0, msg_dimensoes
    	syscall
    	
	li $v0, 1
    	move $a0, $s1
    	syscall
    	
    	li $v0, 1
    	move $a0, $s2
    	syscall
    	
    	li $v0, 4
    	la $a0, msg_max
    	syscall
    	
   	li $v0, 1
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

zerar_loop: # zerando tudo pra n�o somar lixo 
	beqz $t2, fim_zerar_loop	# se t2 for = 0, pula pra fim_zerar_loop
	sw $zero, 0($t1)		# zerando a matriz
	addi $t1, $t1, 4		# movendo o ponteiro
	addi $t2, $t2, -1		# descrementando o contador de pixel
	j zerar_loop
fim_zerar_loop: 

	# INICIO DO LOOP PRINCIPAL DOS ARQUIVOS
	li $s5, 50            	# $s5 = contador do loop
    	li $s6, 100           	# $s6 = condi��o de parada, loop vai de 50 at� < 100
    	la $s7, nome_arquivo   	# $s7 = ponteiro para a string do nome do arquivo
    	
loop_arquivos: # --- ATUALIZAR O NOME DO ARQUIVO --------------------------------
    	li $t0, 10
    	div $s5, $t0            # divide o contador ($s5) por 10
    	mflo $t1                # $t1 = Quociente (primeiro d�gito)
    	mfhi $t2                # $t2 = resto (segundo d�gito)
    	
    	addi $t1, $t1, '0'      # converte primeiro d�gito para char ASCII 
    	addi $t2, $t2, '0'      # converte segundo d�gito para char ASCII
	
	# ALTERANDO O NOME DO ARQUIVO, neste caso como estamos usando sb, nao precisa fazer alinhamento de mem�ria
    	sb $t1, 8($s7)         	# salva o primeiro digito na string
    	sb $t2, 9($s7)         	# salva o segundo d�gito na string 

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
    	
	# --LER O CABE�ALHO PARA O BUFFER----
	li $v0, 14		# carreca o c�digo da syscall 14 (read from file)
	move $a0, $s0		# arg 1: file descriptor)
	la $a1, buffer_leitura	# arg 2: o endereco do buffer de memomria
	li $a2, 999999		# arg 3: ler no m�x. 39 bytes
	syscall
	
	la   $a0, buffer_leitura  # $t0 = ponteiro, prepara o argumento

	# ---IGNORAR A PRIMEIRA LINHA AT� \n -----------------------------------------------------
ignorar_primeira_linha:
	lb $t1, 0($a0)		# carrega um caractere
	addi $a0, $a0, 1	# sempre avanca o ponteiro
	li $t2, 10		# 10 em ascii � \n
	bne $t1, $t2, ignorar_primeira_linha	# se nao for newline, continue o loop
	
	# Avan�a os ponteirs para largura, altura e valor max
	jal ler_prox_int
	jal ler_prox_int
	jal ler_prox_int
	
	# --- LER OS PIXELS DESTE ARQUIVO E SOMAR NA MATRIZ ---
	move $t5, $s4         	# $t1 = ponteiro para a matriz de soma (reinicia do come�o)
    	mult $s1, $s2
    	mflo $t0              	# $t0 = contador de pixels para este frame
		
loop_soma_pixels:
	beqz $t0, fim_soma
		
	jal ler_prox_int	# le o pixel do buffer do arquivo atual
	move $t2, $v0		# $t2 = valor do novo pixel
	
	lw $t3, 0($t5)		# carrega o valor de soma atual da matriz
	add $t3, $t3, $t2	# soma o novo pixel ao valor acumulado
	sw $t3, 0($t5)		# salva a nova soma de  volta na matriz
	
	addi $t5, $t5, 4	# avan�a o ponteiro da matriz
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
    	# s� � executado se o 'bltz' l� de cima detectar um erro
   	 li   $v0, 4
    	la   $a0, msg_erro
    	syscall
    
atualizar_loop:
   	# --- ATUALIZAR O LOOP ---
    	addi $s5, $s5, 1
    	blt $s5, $s6, loop_arquivos # Se contador < 100, processa o pr�ximo arquivo

    	li $v0, 4
    	la $a0, msg_final
    	syscall
    	
    	# --- CALCULAR A M�DIA DOS PIXELS ---
    	li $t0, 50              # $t0 = N�mero de frames processados (100 - 50)
    
    	mult $s1, $s2           # re-calcula o total de pixels (largura * altura)
    	mflo $t1                # $t1 = Contador de pixels
    
    	move $t2, $s4           # $t2 = Ponteiro para navegar pela matriz de soma(inicia no come�o)

loop_media:
    	beqz $t1, fim_loop_media # Se o contador de pixels for 0, termina
    
    	lw $t3, 0($t2)          # carrega o valor da soma do pixel atual
    	div $t3, $t0            # divide a soma pelo n�mero de frames
    	mflo $t3                # pega o resultado da divis�o (a m�dia)
    
    	sw $t3, 0($t2)          # salva a m�dia de volta na matriz
    
    	addi $t2, $t2, 4        # avan�a o ponteiro da matriz
    	addi $t1, $t1, -1       # decrementa o contador de pixels
    	j loop_media
fim_loop_media:
	
	li $v0, 4
    	la $a0, msg_teste_media
    	syscall
    
    	move $t0, $s4       # $t0 = ponteiro para o in�cio da matriz (agora com as m�dias)
    	li $t1, 0           # $t1 = contador do loop de teste (de 0 a 4)
    	li $t2, 5           # $t2 = condi��o de parada do teste
    
loop_teste_media:
    	beq $t1, $t2, fim_teste_media
    
    	# Imprime "Pixel[n]: "
    	li $v0, 4
    	la $a0, msg_pixel
    	syscall
    	li $v0, 1
    	move $a0, $t1
    	syscall

    
    	# Imprime o valor da M�DIA do pixel atual
    	lw $a0, 0($t0)      # Carrega o valor da M�DIA da matriz
    	li $v0, 1
    	syscall
    
    	# Imprime uma nova linha
    	li $v0, 4
    	la $a0, str_newline
   	 syscall
    
    	# Atualiza os ponteiros/contadores do teste
    	addi $t0, $t0, 4    # Avan�a o ponteiro na matriz
    	addi $t1, $t1, 1    # Incrementa o contador do teste
    	j loop_teste_media
    
fim_teste_media:
# --- FIM DO C�DIGO DE TESTE ---
	
	# INICIO DA ESCRITA DO ARQUIVO DE SA�DA
	li $v0, 13		# abre o arquivo
	la $a0, nome_arquivo_saida	# cria o arquivo na pasta 
	la $a1, 1		# flag 1 para escrita
	syscall
	move $s5, $v0		# salva o file descriptor do novo arquivo
	
	# escreve cabea�alho no novo arquivo
	li $v0, 15		# syscall para escrever em um arquivo 
    	move $a0, $s5
    	la $a1, str_p2
    	li $a2, 3		# tamanho da string p2
    	syscall
    	
    	#escreve a largura
    	move $a0, $s1		# $s1 = largura
    	la $a1, buffer_escrita 	# $a1 = buffer
    	jal int_para_string
    	
	# agora chama nossa nova fun��o para escrever
    	move $a0, $s5		
    	la $a1, buffer_escrita
    	jal escrever_string_do_buffer
    	
    	#escreve um espa�o
    	li $v0, 15
    	move $a0, $s5
    	la $a1, str_espaco
    	li $a2, 1
    	syscall
    	
    	# escreve a altura
    	move $a0, $s2
    	la $a1, buffer_escrita
    	jal int_para_string
    	
    	move $a0, $s5
    	la $a1, buffer_escrita
    	jal escrever_string_do_buffer
    	
    	# escreve newline
    	li $v0, 15
    	move $a0, $s5
    	la $a1, str_newline
    	li $a2, 1
    	syscall
    	
    	# escreve o valor m�ximo
    	move $a0, $s3
    	la $a1, buffer_escrita
    	jal int_para_string
    	
    	move $a0, $s5
    	la $a1, buffer_escrita
    	jal escrever_string_do_buffer
    	
    	# escreve newline no final do cabe�alho
    	li $v0, 15
    	move $a0, $s5
    	la $a1, str_newline
    	li $a2, 1
    	syscall
    	
    	# escrever os dados dos pixels
    	mult $s1, $s2
    	mflo $t1		# contador de pixels
    	move $t2, $s4		# percorredor da matriz
    	
loop_escrita_pixels:
	beqz $t1, fim_escrita_pixels	# caso base, numero de pixels =0
	
	lw $a0, 0($t2)		# carrega o valor do pixels para a0
	la $a1, buffer_escrita
	jal int_para_string	# converte pixel para string
	
	# CHAMA A FUN��O AUXILIAR PARA ESCREVER O PIXEL
    	move $a0, $s5
    	la $a1, buffer_escrita
    	jal escrever_string_do_buffer
	
	# escreve o separador dos pixels ( nova linhas )
	li $v0 , 15
	move $a0, $s5
	la $a1, str_newline
	li $a2, 1
	syscall
	
	addi $t2, $t2, 4	# avan�a o ponteiro que percorre a matriz
	addi $t1, $t1, -1	# decrementa o contador
	j loop_escrita_pixels
	
fim_escrita_pixels:
	# fecha o arquivo de saida
	li $v0, 16
	move $a0, $s5
	syscall
	
saida:
	li $v0, 10		# fnaliza execu�ao com syscall 10
	syscall
	   	
	   	   	   	
#---------------------------------------------------------------------------------------

ler_prox_int: 
	addi $sp, $sp, -12
    	sw $t1, 0($sp)
    	sw $t2, 4($sp)
    	sw $t3, 8($sp)
    	
	li $v0, 0		# $s1 vai acumular o n�mero (a largura)
	li $t3, 0		# $t3 = flag, onde: 0 = procurando num, 1 = achei o num
	
loop_interno: 
	lb $t1, 0($a0)		# carrega o d�gito atual
	beqz $t1, fim_do_loop
	
	# verifica se o caractere atual ainda � d�gito. Se n�o for, o n�mero acabou
	li $t2, '0'		# carrega um byte ( caractere apontado por $t0)
    	blt $t1, $t2, nao_e_digito
    	li $t2, '9'
    	bgt $t1, $t2, nao_e_digito
	
	li $t3, 1		# Seta a flag para 1
	# Converte o caractere para inteiro 
	li   $t2, '0'        	# Carrega o valor ASCII de '0' (que � 48) em um registrador tempor�rio $t2
	sub  $t1, $t1, $t2   	# $t1 = $t1 - $t2
	
	# acumula o n�mero $s1 = ($s1 * 10) + digito
	li $t2, 10
	mult $v0, $t2		# multiplica o n�mero atual por 10
	mflo $v0		# copia o valor que est� no registrador LO para o registrador de destino $s1
	add $v0, $v0, $t1	# adiciona o novo d�gito
	j prox_char
	
nao_e_digito:
    	beqz $t3, prox_char 	# Se $t3 for 0, significa que ainda nem come�ou ler o n�mero 
    	j fim_do_loop    	# Se $t3 for 1, significa que est�vamos lendo um n�mero e ele acabou de terminar.
	
prox_char:
	addi $a0, $a0, 1	# avan�a o ponteiro para o pr�ximo caractere
	j loop_interno
	
fim_do_loop:
   	lw $t1, 0($sp)
    	lw $t2, 4($sp)
    	lw $t3, 8($sp)
    	addi $sp, $sp, 12
	jr $ra


int_para_string: # -----------------------------------------------------------------
	# converte um inteiro para string ASCII
	# argumentos : $a0 = inteiro para conveter
	# $a1 = ponteiro para o buffer onde a string sera armazenada
	
	li $t0, 10		# divisor para extrair os c�digo
	li $t1, 0		# contador de digitos
	
loop_extracao:
	div $a0, $t0		# divide o n�mero por 10
	mflo $a0		# quociente
	mfhi $t2		# resto
	
	addi $sp, $sp, -4	# abre espa�o na pilha
	addi $t2, $t2, '0' 	# converte o d�gito para seu caractere ASCII
	sw $t2, 0($sp)		# salva o caractere na pilha
	addi $t1, $t1, 1	# incrementa o contador de digitos
	
	bnez $a0, loop_extracao	# se o n�mero ainda n�ao for zero continua
	
loop_pop:
	beqz $t1, fim_loop_pop	# se o contador for zero, termina
	lw $t2, 0($sp)		# carrega o caractere
	sb $t2, 0($a1)		# salva o caractere no buffer
	addi $sp, $sp, 4	# move o ponteira da pilha para o �ltimo d�gito
	
	addi $a1, $a1, 1	# avan�a o ponteiro do buffer
	addi $t1, $t1, -1	# decrementa o contador de d�gito
	j loop_pop
fim_loop_pop:

	li $t2, 0		# caractere nulo para terminar string
	sb $t2, 0($a1)		# adiciona o terminador nulo
	
	jr $ra
	# -------------------------------------------------------------------------

escrever_string_do_buffer: # calcula o tamanho de uma string em um buffer e a escreve em um arquivo.
    	# Argumentos:
	# $a0 = File Descriptor do arquivo de sa�da
	# $a1 = Endere�o do buffer contendo a string terminada em nulo
    	
    	# Salva registradores que vamos modificar
    	addi $sp, $sp, -8
    	sw $t0, 0($sp)
    	sw $t1, 4($sp)

    	# Calcula o tamanho da string (strlen)
    	move $t0, $a1           # $t0 � nosso ponteiro para percorrer a string
    	li $t1, 0               # $t1 ser� o contador de tamanho
    	
strlen_loop_func:
    	lb $t2, 0($t0)          # carrega um byte
    	beqz $t2, strlen_fim_func # Se for nulo, fim da string
    	addi $t1, $t1, 1        # incrementa o tamanho
    	addi $t0, $t0, 1        # avan�a o ponteiro
    	j strlen_loop_func
strlen_fim_func:

    	# Prepara e executa a syscall de escrita
    	li $v0, 15              # syscall para escrever em arquivo
    	# $a0 j� cont�m o file descriptor (passado como argumento)
    	# $a1 j� cont�m o endere�o do buffer (passado como argumento)
    	move $a2, $t1           # $a2 recebe o tamanho exato que calculamos
    	syscall

    	# Restaura os registradores e retorna
    	lw $t0, 0($sp)
    	lw $t1, 4($sp)
    	addi $sp, $sp, 8
    	jr $ra