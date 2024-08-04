#!/usr/bin/tclsh
package require Tk

oo::class create tapa {
	variable indice data id alturas
	constructor {d r a} {
		set indice 0
		set data $d
		set id $r
		set alturas $a
	}
	method avanzar {} {
		my variable indice data
		set indice [expr ($indice + 1) % [llength $data]]
	}
	method mover {lienzo} {
		my variable indice data id alturas
		# Obtener altura actual
		lassign [$lienzo coords $id] x1 y1 x2 y2
		set y [expr int($y2)]
		# Obtener altura objetivo
		set lienzo_altura [$lienzo cget -height]
		set objetivo [expr $lienzo_altura  - $lienzo_altura / $alturas * [ lindex $data $indice ] ]
		if { $y == $objetivo} {
			my avanzar
			my mover $lienzo
		} elseif { $y < $objetivo} {	
			$lienzo move $id 0 1
		} elseif { $y > $objetivo} {
			$lienzo move $id 0 -1
		}
	}
	method getInfo {} {
		my variable indice data
		return indice data
	}
}

oo::class create juego {
	variable lienzo info_lienzo info_tapas
	constructor { } {
		set info_lienzo { ancho 300 alto 300 }
		set info_tapas {
			ancho 50 alto 10 alturas 5 separacion 15
			velocidad 10 tiempo_lanzamiento 1000
			offset 30
		}
		set lienzo .lienzo
		canvas $lienzo -width [dict get $info_lienzo ancho] -height [dict get $info_lienzo alto] -background white
		pack $lienzo
	}
	method cargarNivel {data} {
		my variable lienzo tapas 
		my variable info_lienzo info_tapas
		set tapas [list] ;# Crea o limpia la lista
		for {set i 0} {$i < [llength $data]} {incr i} {
			set x1 [expr [dict get $info_tapas offset] +  $i * ([dict get $info_tapas ancho] + [dict get $info_tapas separacion])]
			set x2 [expr $x1 + [dict get $info_tapas ancho]]
			set y1 [expr [dict get $info_lienzo alto] - [dict get $info_tapas alto]] 
			set y2 [dict get $info_lienzo alto]
			
			set t [tapa new [lindex $data $i] [$lienzo create rect $x1 $y1 $x2 $y2 -fill black] [dict get $info_tapas alturas]]
			lappend tapas $t
		}
	}
	method actualiza {} {
		my variable tapas lienzo iniciarNivel
		foreach t $tapas {
			$t mover $lienzo
		}
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
	after 15 main $j
}
main j
