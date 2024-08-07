#!/usr/bin/tclsh
package require Tk

oo::class create personaje {
	variable indice wid
	constructor {w} {
		set indice 2
		set wid $w
	}
	method getId {} {
		return my variable $wid
	}
	method getIndice {} {
		return my variable $indice
	}
	method setIndice {nuevo_indice} {
		my variable indice
		set indice $nuevo_indice
	}
}

oo::class create tapa {
	variable indice data wid alturas
	constructor {d w a} {
		set indice 0
		set data $d
		set wid $w
		set alturas $a
	}
	method avanzar {} {
		my variable indice data
		set indice [expr ($indice + 1) % [llength $data]]
	}
	method mover {lienzo} {
		my variable indice data wid alturas
		# Obtener altura objetivo
		set lienzo_altura [$lienzo cget -height]
		set objetivo [expr $lienzo_altura  - $lienzo_altura / $alturas * [ lindex $data $indice ] ]
		# Obtener altura actual
		set y [my getAltura $lienzo]
		# Evaluar y mover
		if { $y == $objetivo} {
			my avanzar
			my mover $lienzo
		} elseif { $y < $objetivo} {	
			$lienzo move $wid 0 1
		} elseif { $y > $objetivo} {
			$lienzo move $wid 0 -1
		}
	}
	method getAltura {lienzo} {
		lassign [my getRectangulo $lienzo] x1 y1 x2 y2
		return [expr int($y2)]
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
	variable lienzo personaje info_lienzo info_tapas info_personaje
	constructor { } {
		set info_lienzo { ancho 300 alto 300 }
		set info_tapas {
			ancho 50 alto 10 alturas 5 separacion 15
			velocidad 10 tiempo_lanzamiento 1000
			offset 30
		}
		set info_personaje { ancho 10 alto 10 }
		set lienzo .lienzo
		canvas $lienzo -width [dict get $info_lienzo ancho] -height [dict get $info_lienzo alto] -background white
		# Observar la sintaxis
		bind . <KeyPress> [list [self] mando %k]
		set personaje [ \
			personaje new [$lienzo create rect 0 0 [dict get $info_personaje ancho] [dict get $info_personaje alto] -fill blue] \
		]
	}
	method mando {k} {
		my variable personaje tapas
			if { $k == 113 } { 
				if {[expr [$personaje getIndice] - 1] >= 0} {
					$personaje setIndice [expr [$personaje getIndice] - 1]
				}
			} elseif { $k == 114 } { 
				if {[expr [$personaje getIndice] + 1] < [llength $tapas]} {
					$personaje setIndice [expr [$personaje getIndice] + 1]
				}
			}
	}
	method cargarNivel {data} {
		my variable lienzo tapas personaje
		my variable info_lienzo info_tapas info_personaje
		set tapas [list] ;# Crea o limpia la lista
		for {set i 0} {$i < [llength $data]} {incr i} {
			set x1 [expr [dict get $info_tapas offset] +  $i * ([dict get $info_tapas ancho] + [dict get $info_tapas separacion])]
			set x2 [expr $x1 + [dict get $info_tapas ancho]]
			set y1 [expr [dict get $info_lienzo alto] - [dict get $info_tapas alto]] 
			set y2 [dict get $info_lienzo alto]
			set nueva_tapa [tapa new [lindex $data $i] [$lienzo create rect $x1 $y1 $x2 $y2 -fill black] [dict get $info_tapas alturas]]
			lappend tapas $nueva_tapa
		}
		pack $lienzo
	}
	method actualiza {} {
		my variable personaje tapas lienzo info_personaje
		foreach t $tapas { $t mover $lienzo }
		lassign [[lindex $tapas [$personaje getIndice]] getCentro $lienzo] px py
		$lienzo moveto [$personaje getId] [expr $px - [dict get $info_personaje ancho] / 2] [expr $py - [dict get $info_personaje alto]]
	}
}

set tapas1 {
	{2 0 2 3}
	{1 0 2 1}
	{4 1 3 2}
	{3 2}
}

juego create j
j cargarNivel $tapas1

proc main {j} {
	$j actualiza
	after 10 main $j
}
main j
