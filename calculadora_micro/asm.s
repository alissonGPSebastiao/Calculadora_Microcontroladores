//Alisson Gabriel Portela Sebastião - 2028778       
       
       PUBLIC  __iar_program_start
        PUBLIC  __vector_table

        SECTION .text:CODE:REORDER(1)
        
  
        REQUIRE __vector_table
        
        THUMB
        
__iar_program_start
        
; System Control definitions
SYSCTL_BASE             EQU     0x400FE000
SYSCTL_RCGCGPIO         EQU     0x0608
SYSCTL_PRGPIO		EQU     0x0A08
SYSCTL_RCGCUART         EQU     0x0618
SYSCTL_PRUART           EQU     0x0A18
; System Control bit definitions
PORTA_BIT               EQU     000000000000001b ; bit  0 = Port A
PORTF_BIT               EQU     000000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     000000100000000b ; bit  8 = Port J
PORTN_BIT               EQU     001000000000000b ; bit 12 = Port N
UART0_BIT               EQU     00000001b        ; bit  0 = UART 0

; NVIC definitions
NVIC_BASE               EQU     0xE000E000
NVIC_EN1                EQU     0x0104
VIC_DIS1                EQU     0x0184
NVIC_PEND1              EQU     0x0204
NVIC_UNPEND1            EQU     0x0284
NVIC_ACTIVE1            EQU     0x0304
NVIC_PRI12              EQU     0x0430

; GPIO Port definitions
GPIO_PORTA_BASE         EQU     0x40058000
GPIO_PORTF_BASE    	EQU     0x4005D000
GPIO_PORTJ_BASE    	EQU     0x40060000
GPIO_PORTN_BASE    	EQU     0x40064000
GPIO_DIR                EQU     0x0400
GPIO_IS                 EQU     0x0404
GPIO_IBE                EQU     0x0408
GPIO_IEV                EQU     0x040C
GPIO_IM                 EQU     0x0410
GPIO_RIS                EQU     0x0414
GPIO_MIS                EQU     0x0418
GPIO_ICR                EQU     0x041C
GPIO_AFSEL              EQU     0x0420
GPIO_PUR                EQU     0x0510
GPIO_DEN                EQU     0x051C
GPIO_PCTL               EQU     0x052C

; UART definitions
UART_PORT0_BASE         EQU     0x4000C000
UART_FR                 EQU     0x0018
UART_IBRD               EQU     0x0024
UART_FBRD               EQU     0x0028
UART_LCRH               EQU     0x002C
UART_CTL                EQU     0x0030
UART_CC                 EQU     0x0FC8
;UART bit definitions
TXFE_BIT                EQU     10000000b ; TX FIFO full
RXFF_BIT                EQU     01000000b ; RX FIFO empty
BUSY_BIT                EQU     00001000b ; Busy


; PROGRAMA PRINCIPAL

        
main:   MOV R2, #(UART0_BIT)
	BL UART_enable ; habilita clock ao port 0 de UART

        MOV R2, #(PORTA_BIT)
	BL GPIO_enable ; habilita clock ao port A de GPIO
        
	LDR R0, =GPIO_PORTA_BASE
        MOV R1, #00000011b ; bits 0 e 1 como especiais
        BL GPIO_special

	MOV R1, #0xFF ; máscara das funções especiais no port A (bits 1 e 0)
        MOV R2, #0x11  ; funções especiais RX e TX no port A (UART)
        BL GPIO_select

	LDR R0, =UART_PORT0_BASE
        BL UART_config ; configura periférico UART0
        
        ;; R0 auxiliará em algumas sub-rotinas 
        ;; R1 servirá para receber e transmitir os dados
        ;; R2 não será utilizado
        ;; R3 auxiliará em algumas sub-rotinas
        ;; R4 auxiliará para passar de hexadecimal para decimal
        ;; R5 servirá para saber se o caractere é ou não uma operação matemática
        ;; R6 auxiliará para fazer a transformação de R4
        ;; R7 servirá para manter a operação matemática que será realizada
        ;; R8 servirá para retornar o resultado da operação matematica
        ;; R9 será o primeiro número digitado pelo usuário
        ;; R10 será o segundo número digitado pelo usuário e também como auxiliar para retornar o LR
        ;; R11 servirá de contador para saber quantos algarismos do número já foram (deve ser no máximo 4 algarismos) e também como auxiliar para retornar o LR
        ;; R12 servirá como número 10 para multiplicar (deslocar à esquerda) ou dividir (deslocar à direita)

        PUSH {R9}                       ; coloca um valor zero na pilha para poder usar no primeiro caractere
        MOV R8, #-1                     ; coloca um valor de -1 no R8, que contém o resultado, para saber que ele ainda não foi mexido
loop:
        BL Verifica_UART_RX               ; verifica se há RX
        LDR R1, [R0]                    ; lê do registrador de dados da UART0 (recebe) R1 armazena o valor de tabela ASC do caractere
      
        BL Verifica_operacao         ; verifica se há sinais de +, -, * ou /, se tiver, entrará em outras sub-rotinas
        BL Verifica_igual            ; verifica se há um sinal de =, se tiver, entrará em outras sub-rotinas
        

        CMP R5, #1
        BEQ Operacao                ; se o R5 for igual a 1 então está sendo uma operação matemática, então pula para o Is_Operation
verified:       

        ADD R11, R11, #1                ; adiciona 1 no contador para saber quantos algarismos tem o número
        BL Limitador            ; verifica se já foram 4 digitos //// R11 for 5 e R5 for 0, volta pra tras
        BL Transforma_Hexa_To_Decimal    ; transforma de hexa para decimal       
        BL Gerenciador             ; faz a operação R4 = R4 + R6
        BL Mover_esquerda                 ; move um dígito decimal a esquerda
        PUSH {R4}                       ; coloca R4 na pilha      
                               
Operacao:                           ; quando for uma operação matemática pular pra cá    
        MOV R5, #0                      ; zera a indicação de que é uma operação matemática

retorna:           
        BL Verifica_UART_TX             ; verifica se há TX
        STR R1, [R0]                    ; escreve no registrador de dados da UART0 (transmite)
        
        BL Verifica_fim                 ; verifica se chegou no fim, ou seja, coloca os algarismos na pilha
        BL Fim_calculo                  ; faz a operação final de tirar da pilha e colocar no R1
        
        CMP R8, #0                      ; verifica se R8 = 0, ou seja, quando chegar no zero da pilha, coloca R8 = -1, o que significa que acabou de transmitir 
        BEQ retorna                        ; se ainda não foi, significa que a pilha ainda está cheia e ele volta até que o R8 seja -1

        CMP R1, #0                      ; verifica se R1 = 0, ou seja, que o último valor da pilha, que é 0, foi para o R1, significando que acabou a transmissão
        IT EQ                           ; se o R1 = 0, então Z = 1 
        BLEQ Pula_linha                  ; faz o "\r" e o "\n"
        
        B loop
        



; Verifica_operacao: verifica se o caractere de entrada foi algum sinal de operação diferente do igual(=)
Verifica_operacao:
        CMP R1, #'+'           
        BEQ Guarda_op        

        CMP R1, #'-'           
        BEQ Guarda_op       

        CMP R1, #'*'          
        BEQ Guarda_op      

        CMP R1, #'/'           
        BEQ Guarda_op       
        
        BX LR
        
; Guarda_op: armazena qual operação deverá ser feita
Guarda_op:
        MOV R10, LR                   
        MOV R5, #1                     
        MOV R7, R1                     
        BL Mover_direita               
        BL Guarda_1          
        MOV R11, #0                    
        PUSH {R11}                     
        MOV LR, R10                    
        BX LR
       
; Verifica_igual:  verifica se o caractere de entrada é o igual 
Verifica_igual:
        CMP R1, #'='                      
        BEQ calcula
        BX LR

; calcula: faz a operação matemática e coloca em R8
calcula:
        MOV R11, LR
        MOV R5, #1                         
        BL Mover_direita
        BL Guarda_2             
        BL Seleciona               
        BL Limpa_op                 
        MOV LR, R11
        POP {R11}
        MOV R11, #0                        
        PUSH {R11}
        BX LR
 
; Seleciona_Operation: direciona para fazer a operação matemática, seja ela +,-,* ou /       
Seleciona:
        
        CMP R7, #'+'                       
        BEQ soma                  

        CMP R7, #'-'                       
        BEQ subtrai          

        CMP R7, #'*'                       
        BEQ multiplica       

        CMP R7, #'/'                       
        BEQ divide          
        
        BX LR
     
; Soma: direciona para fazer a soma
soma:
        PUSH {LR}
        ADD R8, R9, R10          
        POP {LR}
        BX LR
        
; subtrai: direciona para fazer a subtração
subtrai:
        PUSH {LR}
        SUB R8, R9, R10          
        POP {LR}
        BX LR

; multiplica: direciona para fazer a multiplicação
multiplica:
        PUSH {LR}
        MUL R8, R9, R10          
        POP {LR}
        BX LR

; divide: direciona para fazer a divisão
divide:
        PUSH {LR}
        SDIV R8, R9, R10         
        POP {LR}
        BX LR

; Tranforma_Hexa_To_Decimal: transforma o valor que veio da tabela ASC (em hexadecimal) em decimal
Transforma_Hexa_To_Decimal:
        PUSH {R0}
        MOV R0, #0x30                           
        SUB R4, R1, R0           
        POP {R0}
        BX LR
             
; Gerenciador: coordena operações importantes para colocar valores da tabela ASC nos registradores     
Gerenciador:
        POP {R6}                  
        ADD R4, R4, R6          
        BX LR

; Mover_esquerda: move um dígito decimal a esquerda
Mover_esquerda:
        PUSH {R0}
        MOV R12, #10              
        MOV R0, R12              
        MULS R4, R4, R0           
        POP {R0}
        BX LR
        
; Mover_direita: move um dígito decimal a direita
Mover_direita:
        SDIV R4, R4, R12             
        BX LR
        
; Guarda_1: armazena o primeiro número em R9  
Guarda_1:
        MOV R11, LR               
        MOV R9, R4                
        BL Limpa_pilha            
        BL Limpa_registrador        
        MOV LR, R11
        BX LR
        
; Guarda_2: armazena o segundo número em R10
Guarda_2:
        PUSH {LR}
        MOV R10, R4               
        BL Limpa_registrador        
        POP {LR}
        BX LR
        
; Limpa_pilha: limpa a pilha depois que foi feita a operação matemática
Limpa_pilha:
        POP {R12}                 
        MOV R12, #0               
        BX LR
      
; Limpa_registrador: limpa os valores de R4 e R6 para poder usá-los na formação do segundo número     
Limpa_registrador:
        PUSH {LR}
        MOV R4, #0                
        MOV R6, #0                
        POP {LR}
        BX LR

;Limpa_op: limpa a operação matemática
Limpa_op:
        MOV R7, #0                
        BX LR
        
; Limitador: limita o número de caracteres na entrada em 4 dígitos        
Limitador:
        CMP R11, #5
        BEQ salto
        BX LR
        
salto:
        PUSH {R1}
        MOV R1, #1
        SUB R11, R11, R1
        POP {R1}
        CMP R5, #0
        BEQ loop
        BX LR
        
        
; Verifica_fim: verifica se chegou no final, ou seja, verifica se o último valor de R1 é o "=", se for
; então devemos converter o resultado final de acordo com a tabela ASC    
Verifica_fim:
        MOV R3, LR
        BL Foi_sinal         
jump:
        MOV LR, R3
        BX LR

; Foi_sinal: Foi o sinal de igual
Foi_sinal:
        CMP R1, #'='              
        BEQ Converte_To_ASC        
        BX LR
        
; Converte_To_ASC: converte para tabela ASC e coloca na pilha 
Converte_To_ASC:
        MOV R7, #10                               
        PUSH {R8}                                 
        SDIV R8, R8, R7                           
        MOV R6, R8                                
        MUL R9, R8, R7                            
        POP {R8}                                  
        SUB R1, R8, R9                            
        MOV R7, #0x30                             
        ADD R1, R1, R7                            
        PUSH {R1}                                 
        MOV R8, R6                                
        CMP R8, #0                                
        BEQ jump                                  
        BL Converte_To_ASC                         
        
; Fima_calculo: Faz a operação final de tirar da pilha se R8 já for 0       
Fim_calculo:
        CMP R8, #0
        BEQ coloca_R1
        BX LR
        
; coloca_R1: Coloca o conteúdo da pilha em R1       
coloca_R1:
        POP {R1}
        CMP R1, #0                                
        BEQ coloca_menos1
        BX LR
        
; coloca_menos1: Coloca o valor de -1 no R8
coloca_menos1:
        MOV R8, #-1                               
        PUSH {R1}                                 
        BX LR

; Pula_linha: pula uma linha e volta para o começo dela
Pula_linha:
        PUSH {LR}
        PUSH {R1}
        MOV R1, #'\r'                              
        BL Verifica_UART_TX                          
        STR R1, [R0]
        POP {R1}        
        PUSH {R1}
        MOV R1, #'\n'                              
        BL Verifica_UART_TX                          
        STR R1, [R0]
        POP {R1}
        POP {LR}
        BX LR
 
 //Subrotinas e Mascaras de GPIO

; GPIO_special: habilita funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como funções especiais
; Destrói: R2
GPIO_special:
	LDR R2, [R0, #GPIO_AFSEL]
	ORR R2, R1 ; configura bits especiais
	STR R2, [R0, #GPIO_AFSEL]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_select: seleciona funcões especiais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem alterados
; R2 = padrão de bits (1) a serem selecionados como funções especiais
; Destrói: R3
GPIO_select:
	LDR R3, [R0, #GPIO_PCTL]
        BIC R3, R1
	ORR R3, R2 ; seleciona bits especiais
	STR R3, [R0, #GPIO_PCTL]

        BX LR
;----------

; GPIO_enable: habilita clock para os ports de GPIO selecionados em R2
; R2 = padrão de bits de habilitação dos ports
; Destrói: R0 e R1
GPIO_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCGPIO]
	ORR R1, R2 ; habilita ports selecionados
	STR R1, [R0, #SYSCTL_RCGCGPIO]

waitg	LDR R1, [R0, #SYSCTL_PRGPIO]
	TEQ R1, R2 ; clock dos ports habilitados?
	BNE waitg

        BX LR

; GPIO_digital_output: habilita saídas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como saídas digitais
; Destrói: R2
GPIO_digital_output:
	LDR R2, [R0, #GPIO_DIR]
	ORR R2, R1 ; configura bits de saída
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

        BX LR

; GPIO_write: escreve nas saídas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits a serem escritos
GPIO_write:
        STR R2, [R0, R1, LSL #2] ; escreve bits com máscara de acesso
        BX LR

; GPIO_digital_input: habilita entradas digitais no port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = padrão de bits (1) a serem habilitados como entradas digitais
; Destrói: R2
GPIO_digital_input:
	LDR R2, [R0, #GPIO_DIR]
	BIC R2, R1 ; configura bits de entrada
	STR R2, [R0, #GPIO_DIR]

	LDR R2, [R0, #GPIO_DEN]
	ORR R2, R1 ; habilita função digital
	STR R2, [R0, #GPIO_DEN]

	LDR R2, [R0, #GPIO_PUR]
	ORR R2, R1 ; habilita resitor de pull-up
	STR R2, [R0, #GPIO_PUR]

        BX LR

; GPIO_read: lê as entradas do port de GPIO desejado
; R0 = endereço base do port desejado
; R1 = máscara de bits a serem acessados
; R2 = bits lidos
GPIO_read:
        LDR R2, [R0, R1, LSL #2] ; lê bits com máscara de acesso
        BX LR

//Subrotinas e mascaras de UART

; UART_enable: habilita clock para as UARTs selecionadas em R2
; R2 = padrão de bits de habilitação das UARTs
; Destrói: R0 e R1
UART_enable:
        LDR R0, =SYSCTL_BASE
	LDR R1, [R0, #SYSCTL_RCGCUART]
	ORR R1, R2 ; habilita UARTs selecionados
	STR R1, [R0, #SYSCTL_RCGCUART]

waitu	LDR R1, [R0, #SYSCTL_PRUART]
	TEQ R1, R2 ; clock das UARTs habilitados?
	BNE waitu

        BX LR
        
; UART_config: configura a UART desejada
; R0 = endereço base da UART desejada
; Destrói: R1
UART_config:
        LDR R1, [R0, #UART_CTL]
        BIC R1, #0x01 ; desabilita UART 
        STR R1, [R0, #UART_CTL]

        ; clock = 16MHz, baud rate = 9600 bps
        MOV R1, #104
        STR R1, [R0, #UART_IBRD]
        MOV R1, #11
        STR R1, [R0, #UART_FBRD]
        
        ;8 bits, 1 stop bit, odd parity, FIFOs disabled, no interrupts
        MOV R1, #01100010b
        STR R1, [R0, #UART_LCRH]
        
        ; clock source = system clock
        MOV R1, #0x00
        STR R1, [R0, #UART_CC]
        
        LDR R1, [R0, #UART_CTL]
        ORR R1, #0x01 ; habilita UART 
        STR R1, [R0, #UART_CTL]

        BX LR

; Verifica_UART_RX: verifica se há algo querendo ser transmitido ao emulador do terminal (transmissão RX)
Verifica_UART_RX:
        LDR R2, [R0, #UART_FR] 
        TST R2, #RXFF_BIT 
        BEQ Verifica_UART_RX
        BX LR

; Verifica_UART_TX: verifica se há algo querendo ser transmitido ao Kit (transmissão TX)
Verifica_UART_TX:
        LDR R2, [R0, #UART_FR] 
        TST R2, #TXFE_BIT 
        BEQ Verifica_UART_TX
        BX LR       


//Subrotinas e Mascaras aicionais
; SW_delay: atraso de tempo por software
; R0 = valor do atraso
; Destrói: R0
SW_delay:
        CBZ R0, out_delay
        SUB R0, R0, #1
        B SW_delay        
out_delay:
        BX LR

; LED_write: escreve um valor binário nos LEDs D1 a D4 do kit
; R0 = valor a ser escrito nos LEDs (bit 3 a bit 0)
; Destrói: R1, R2, R3 e R4
LED_write:
        AND R3, R0, #0010b
        LSR R3, R3, #1
        AND R4, R0, #0001b
        ORR R3, R3, R4, LSL #1 ; LEDs D1 e D2
        LDR R1, =GPIO_PORTN_BASE
        MOV R2, #000000011b ; máscara PN1|PN0
        STR R3, [R1, R2, LSL #2]

        AND R3, R0, #1000b
        LSR R3, R3, #3
        AND R4, R0, #0100b
        ORR R3, R3, R4, LSL #2 ; LEDs D3 e D4
        LDR R1, =GPIO_PORTF_BASE
        MOV R2, #00010001b ; máscara PF4|PF0
        STR R3, [R1, R2, LSL #2]
        
        BX LR






        ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
