;
;	Decodeur de trame pulsadis EJP et préavis EJP
;	(pic 12C508 ou 509)
;	Alain Gibaud, 20-2-2001
;
; ========================================================
	list r=hex,p=p12c508

	include "p12c508.inc"
GP0	        equ 0
GP1	        equ 1
GP2 	equ 2
GP3	        equ 3
GP4	        equ 4
GP5 	equ 5
TO	        equ 4              
;  masques pour acceder aux pattes
GP0bit	equ 1 << GP0
GP1bit	equ 1 << GP1
GP2bit	equ 1 << GP2
GP3bit	equ 1 << GP3
GP4bit	equ 1 << GP4              
GP5bit	equ 1 << GP5         
; ========================================================
; affectation des pattes
;                                        

; sorties: (actives niv bas)
NORMAL	equ GP0	; LED verte
ALERTE	equ GP1 ; LED orange
EJP	equ GP2 ; LED rouge
; entrees:( actives niv bas)
SIGNAL	equ GP3 ; avec pull-up, en provenance filtre 175 Hz
; GP4-5 sont utilisees par l'horloge
; ========================================================
; variables:
TICKS	equ 0x7 ; compteur de ticks (1 tick = 2/100 s)
SLOT	equ 0x8 ; numero slot dans la trame 
; =======================================================
; Macros pour alleger le code ...
;
; Teste si min <= (var) < max
; branche en "in" si oui, en "out" si non.
;                      
Lminmax	macro var,min,max,outm,in,outp
	movlw	min
	subwf	var,W	; (var) - min
	btfss	        STATUS,C
	goto 	outm ; C=0 => resutat < 0 => var < min
	
	movlw	max
	subwf	var,W ; (var) - max
	btfss	        STATUS,C
	goto in
	goto outp ; C=1 => resutat >= 0 => var >= min
	endm
;
; Attend que le bit "bit" du registre "reg" soit a 1
;
Waitbit1 macro reg,bit
	local	Wait1
Wait1	btfss	reg,bit
	goto Wait1
	endm
;
; Attend que le bit "bit" du registre "reg" soit a 0
;
Waitbit0 macro reg,bit
	local Wait0
Wait0	btfsc	reg,bit
	goto Wait0
	endm
;
; Branche en "label" si (reg) == num, sinon continue
;
Beq	macro label,reg,num
	movlw	num
	subwf	reg,W
	btfsc	STATUS,Z 
	goto 	label
	endm
;
; Branche en "label" si (reg) != num, sinon continue
;
Bne	macro label,reg,num
	movlw	num
	subwf	reg,W
	btfss	STATUS,Z 
	goto 	label
	endm           

;
; Branche en "label" si (reg) < num, sinon continue
;
Blt	macro label,reg,num
	movlw	num
	subwf	reg,W	; reg - W
	btfss	STATUS,C 
	goto 	label ; C=0 =>  reg - W < 0
	endm

;
; Branche en "label" si (reg) >= num, sinon continue
;
Bge	macro label,reg,num
	movlw	num
	subwf	reg,W ; reg - W
	btfsc	STATUS,C 
	goto 	label ; C=1 =>  reg - W >= 0
	endm
; ========================================================
	; CONFIG word  ( en FFF )
	; bits 11:5	don't care
	; bit 4 :	MCLRE enabled = 1, tied to Vdd = 0
	; bit 3 : 	code protection off = 1, on = 0
	; bit 2 : 	no watchdog = 0, watchdog = 1
	; bit 1-0 ; 	EXTRC = 00, INTRC = 10, XT = 01, LP = 00
	
	__CONFIG B'000000001101' ; (horloge a quartz, avec watchdog)  
; ========================================================	
	org 0
	goto debut
;=========================================================
; sous-programmes
; ========================================================
; regarde si le timer est passe a 0
; si oui, le compteur de ticks est incremente
; et on attend le repassage a 1 
; Cette routine DOIT etre appelee tout les 2/100 s ou plus souvent
tickcount
	clrwdt
	movf 	TMR0,W
	btfss	STATUS,Z
	retlw	0
	
	incf	TICKS,F
;	attendre que le timer ait depasse 0
waitnoZ
	clrwdt
	movf 	TMR0,W
	btfsc	STATUS,Z
	goto	waitnoZ
	retlw 0
;	
; les 2 fct qui suivent maintiennent, le compteur de ticks
; (en plus de scruter une patte)
; attente d'un signal (logique negative)
waitsignal
	call 	tickcount
	btfsc	GPIO,SIGNAL
	goto waitsignal
	retlw 0
; attente fin signal
waitnosignal
	call 	tickcount
	btfss	GPIO,SIGNAL
	goto waitnosignal
	retlw 0
; remet a zero le compteur de ticks et le timer et le watchdog
clearticks
	clrwdt
	clrw
	movwf	TICKS
	movwf	TMR0
	; pour eviter un timeout immediat, le timer est charge 
	; a 1, et le 1er tick ne fait que 0.019922s au lieu de 0.2s
	; (ce n'est pas grave dans la mesure ou de toute facon,
	; le temps de traitement entre les different declenchements 
	; de chrono n'est pas nul)
	incf	TMR0,F 
	retlw 0

;
; ==========================================================
; 
debut	
	; reset par Watchdog ?
	btfsc	STATUS,TO
	goto notimeout
	; TO == 0 : OUI
	clrwdt
	goto 	0x1FF	; recalibrage,  0x3FF sur 12C509
	
	; TO == 1 : NON
notimeout		
	movwf 	OSCCAL 	; recalibrer l'horloge
	clrf	TMR0 	; RAZ timer
	; GPWU=1 : disable wake up on pin change
	; GPPU=0 : enable pullups (a voir avec le hard ..)
	; T0CS=0 : timer connected to F/4
	; T0SE=x : dont't care
	; PSA=0  : prescaler assigned to timer
	; PS2-0= : timer prescaler 111= 1/256, 101 = 1/64, 011 = 1/16
	movlw B'10010101' 
	option 
	
	; config des pattes
	movlw	B'00001000' ; GP0-2 en sortie, GP3 entree
	tris 	GPIO
	
	; se mettre en mode normal
	bcf	GPIO,NORMAL
	bsf	GPIO,ALERTE
	bsf	GPIO,EJP
		
	
attendre_trame
	call 	waitnosignal ; attendre ...
	call 	waitsignal   ; ... front montant	
	call	clearticks
	call	waitnosignal
	; 45 tk = 0.9s, 55 tk = 1.1s
	Lminmax	TICKS,D'45',D'55',attendre_trame,pulse1s,attendre_trame
pulse1s

	; attendre 162,5 tk  = 2.75 s + 0.5 s = 3.25 s
	call clearticks
again325
	call tickcount
	Lminmax	TICKS,D'162',D'162',again325,again325,end325
end325

	; on est maintenant au centre du 1er bit
	; il suffit d'echantillonner toutes les 2.5s
	movlw	1
	movwf	SLOT
	
sample	btfsc	GPIO,SIGNAL ; logique negative
	goto	slot40
	
	; signal detecte !!
	Bne	not5,SLOT,D'5' ; slot == 5 ?
	; oui - 5 = passage en alerte
	bsf	GPIO,NORMAL 	; bit a 1 = LED eteinte
	bsf	GPIO,EJP 	; bit a 1 = LED eteinte
	bcf	GPIO,ALERTE	; bit a 0 = LED allumee
	goto 	nextslot
not5
	Bne	not15,SLOT,D'15' ; slot == 15 ?
	; oui
	btfsc	GPIO,ALERTE ; deja en alerte ?
	goto 	endejp
	; oui - 5 & 15 = debut ejp 
	bsf	GPIO,NORMAL 	; bit a 1 = LED eteinte
	bsf	GPIO,ALERTE 	; bit a 1 = LED eteinte
	bcf	GPIO,EJP 	; bit a 0 = LED allumee
	goto 	nextslot
endejp
	; non - 15 seul = fin ejp
	bsf	GPIO,EJP 	; bit a 1 = LED eteinte
	bsf	GPIO,ALERTE 	; bit a 1 = LED eteinte
	bcf	GPIO,NORMAL 	; bit a 0 = LED allumee
	goto 	nextslot
	
not15
slot40
	; slot 40 ?
	Bne	nextslot,SLOT,D'40' ; slot == 40 ?
	; et attendre une nouvelle trame

	goto 	attendre_trame
nextslot
	incf	SLOT,F
	
	; si le signal est a 1, on en profite pour se resynchroniser
	; sur son front descendant, au cas ou l'emetteur ne soit pas
	; bien conforme au protocole.
	btfss	GPIO,SIGNAL
	goto	resynchro
	; attendre 125 ticks = 2.5s
	call clearticks
again125
	call tickcount
	Lminmax	TICKS,D'125',D'126',again125,sample,again125
	
resynchro 
	call waitnosignal
	call clearticks
again100 ; attente 2 s (100 ticks)	
	call tickcount
	Lminmax	TICKS,D'100',D'101',again100,sample,again100

	end


