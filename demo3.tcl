#!/usr/bin/tclsh
package require Tk

oo::class create personaje {
	variable indice wid
	constructor {w} {
		set indice 0
		set wid $w
	}
	method getId {} {return my variable $wid}
	method getIndice {} {return my variable $indice}
	method setIndice {nuevo_indice} {
		my variable indice
		set indice $nuevo_indice
	}
	method compruebaMuerte {lienzo maxheight} {
		my variable wid
		lassign [$lienzo coords $wid] x1 y1 x2 y2
		if {$y1 <= 0 || $y2 >= $maxheight } {
			my morir $lienzo
			return true
		}
		return false
	}
	method morir {lienzo} {
		my variable wid
		$lienzo itemconfigure $wid -fill red
	}
}

oo::class create tapa {
	variable indice data wid alturas suspension pisada reloj indicador
	constructor {d c w lienzo barra a} {
		set indice 0
		set pisada 0
		set suspension 100
		set data $d
		set wid $w
		set alturas $a
		set reloj [reloj new $barra $suspension [lindex [my getCentro $lienzo] 0]]
		set indicador [indicador new $barra $alturas [lindex [my getCentro $lienzo] 0] [lindex $data 1]]
	}
	method pisar {} {
		my variable pisada suspension
		set pisada 1
		set suspension 0
	}
	method liberar {} {
		my variable pisada
		set pisada 0
	}
	method avanzar {} {
		my variable indice data
		set pisada 0
		set indice [expr ($indice + 1) % [llength $data]]
	}
	method mover {lienzo barra} {
		my variable indice data wid alturas suspension pisada indicador
		# Obtener altura objetivo
		set lienzo_altura [$lienzo cget -height]
		set objetivo [expr $lienzo_altura  - $lienzo_altura / $alturas * ([ lindex $data $indice ] - $pisada) ]
		# Obtener altura actual
		set y [my getAltura $lienzo]
		# Evaluar y mover
		if { $y == $objetivo} {
			set tapax [lindex [my getCentro $lienzo] 0]
			if { $suspension > 0} {
				if {$suspension == 100} {
					$indicador crear $barra [lindex $data [expr ($indice + 1) % [llength $data]]]
				}
				set suspension [ expr $suspension - 1 ]
				$reloj dibujar $barra $tapax
				$reloj restar $barra $tapax
			} else {
				set suspension 100
				$indicador borrar $barra
				$reloj reiniciar $barra $tapax
				my avanzar
				my mover $lienzo $barra
			}
		} elseif { $y < $objetivo} {	
			$lienzo move $wid 0 2
		} elseif { $y > $objetivo} {
			$lienzo move $wid 0 -1
		}
	}
	method getAltura {lienzo} {
		lassign [my getRectangulo $lienzo] x1 y1 x2 y2
		return [expr int($y1)]
	}
	method getCentro {lienzo} {
		lassign [my getRectangulo $lienzo] x1 y1 x2 y2
		return [list [expr $x1 + ( $x2 - $x1 ) / 2] $y1] ;#[expr $y1 + ( $y2 - $y1 ) / 2]]
	}
	method getRectangulo {lienzo} {
		my variable wid
		return [$lienzo coords $wid]
	}
}

oo::class create juego {
	variable lienzo barra personaje info_lienzo info_tapas info_personaje
	constructor { } {
		set info_lienzo { ancho 420 alto 200 }
		set info_barra { alto 50 }
		set info_tapas {
			ancho 50 alto 10 alturas 5 separacion 30
			velocidad 10 tiempo_lanzamiento 1000
			offset 30
		}
		set info_personaje { ancho 20 alto 20 }
		set lienzo .lienzo
		set barra .barra
		canvas $lienzo -width [dict get $info_lienzo ancho] -height [dict get $info_lienzo alto] -background white
		canvas $barra -width [dict get $info_lienzo ancho] -height [dict get $info_barra alto] -background white
		# Observar la sintaxis
		bind . <KeyPress> [list [self] mando %k]
		set personaje [ \
			personaje new [$lienzo create rect 0 0 [dict get $info_personaje ancho] [dict get $info_personaje alto] -fill yellow] \
		]
	}
	method cargarNivel {data} {
		my variable lienzo barra tapas personaje
		my variable info_lienzo info_tapas info_personaje
		set tapas [list] ;# Crea o limpia la lista
		set lienzo_altura [dict get $info_lienzo alto]
		set alturas [dict get $info_tapas alturas]
		for {set i 0} {$i < [llength $data]} {incr i} {
			set x1 [expr [dict get $info_tapas offset] +  $i * ([dict get $info_tapas ancho] + [dict get $info_tapas separacion])]
			set x2 [expr $x1 + [dict get $info_tapas ancho]]
			set y1 [expr $lienzo_altura  - $lienzo_altura / $alturas * [lindex [lindex $data $i] 0]]
			set y2 [expr $y1 + [dict get $info_tapas alto]]
			set nueva_tapa [\
				tapa new [lindex $data $i]\
				[list $x1 $y1 $x2 $y2] \
				[$lienzo create rect $x1 $y1 $x2 $y2 -fill black]\
				$lienzo\
				$barra\
				[dict get $info_tapas alturas]\
			]
			lappend tapas $nueva_tapa
		}
		pack $lienzo
		pack $barra
	}
	method mando {k} {
		my variable personaje tapas
			if { $k == 113 } { 
				if {[expr [$personaje getIndice] - 1] >= 0} {
					[lindex $tapas [$personaje getIndice]] liberar
					$personaje setIndice [expr [$personaje getIndice] - 1]
					[lindex $tapas [$personaje getIndice]] pisar
				}
			} elseif { $k == 114 } { 
				if {[expr [$personaje getIndice] + 1] < [llength $tapas]} {
					[lindex $tapas [$personaje getIndice]] liberar
					$personaje setIndice [expr [$personaje getIndice] + 1]
					[lindex $tapas [$personaje getIndice]] pisar
				}
			}
	}
	method actualiza {} {
		my variable personaje tapas lienzo barra info_personaje info_lienzo
		foreach t $tapas { $t mover $lienzo $barra }
		#¿Por qué no funciona con data tapas de 2 x N?
		lassign [[lindex $tapas [$personaje getIndice]] getCentro $lienzo] px py
		$lienzo moveto [$personaje getId] [expr $px - [dict get $info_personaje ancho] / 2] [expr $py - [dict get $info_personaje alto]]
		return [$personaje compruebaMuerte $lienzo [dict get $info_lienzo alto]]
	}
}

oo::class create reloj {
	variable capacidad resto
	variable ancho alto margin_top
	variable wid_fondo wid_frente
	constructor {lienzo cap centrox} {
		set ancho 40
		set alto 10
		set margin_top 10
		set capacidad $cap
		set resto $capacidad
		set wid_fondo [$lienzo create rect [expr $centrox - $ancho / 2] $margin_top [expr $centrox + $ancho / 2] [expr $margin_top + $alto] -fill orange -outline white]
		set wid_frente [$lienzo create rect [expr $centrox - $ancho / 2] $margin_top [expr $centrox + $ancho / 2] [expr $margin_top + $alto] -fill white -outline white]
	}
	method restar {barra x} {
		my variable resto capacidad
		set resto [expr $resto - 1]
		if {$resto <= 0} {
			my reiniciar $barra $x
		}
	}
	method reiniciar {barra x} {
		my variable resto ancho alto margin_top capacidad uid
		set resto $capacidad
	}
	method dibujar {barra x} {
		my variable ancho alto margin_top resto capacidad wid_frente
		set restopxs [expr $resto * $ancho / $capacidad]
		$barra coords $wid_frente [expr ($x - $ancho / 2) + $restopxs] $margin_top [expr $x + $ancho / 2] [expr $margin_top + $alto]
	}
}

oo::class create indicador {
	variable nivel capacidad
	variable ancho alto margin_top
	variable centrox
	variable wid_fondo wid_frente
	constructor {lienzo cap cenx niv} {
		set ancho 40
		set alto 5
		set margin_top 25
		set centrox $cenx
		set capacidad $cap
	}
	method crear {lienzo niv} {
		my variable wid_frente wid_fondo centrox ancho alto margin_top
		set p [expr $niv * $ancho / $capacidad]
		set wid_fondo [$lienzo create rect [expr $centrox - $ancho / 2] $margin_top [expr $centrox + $ancho / 2] [expr $margin_top + $alto] -fill white]
		set wid_frente [$lienzo create rect [expr $centrox - $ancho / 2] $margin_top [expr $centrox - $ancho / 2 + $p] [expr $margin_top + $alto] -fill cyan]
	}
	method borrar {lienzo} {
		my variable wid_frente wid_fondo
		$lienzo delete $wid_fondo $wid_frente 
	}
}

set tapas1 {
	{3 4 3 2}
	{4 2 4 1}
	{2 5 1 3}
	{1 3 4 2}
	{3 4}
}

juego create j
j cargarNivel $tapas1

proc main {j} {
	if ![$j actualiza] {
		after 15 main $j
	} else {
		puts "Perdiste, chango"
	}
}
main j
