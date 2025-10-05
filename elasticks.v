module elasticks

import math { pow }
import math.vec { vec3 }

// A: Stick_type
// B: Solve

// A: Stick_type
// a: Section
// b: Material
pub struct Stick_type {
pub:
	lenght   f64
	section  Section
	material Material
}

// a: Section
interface Section {
	name string

	i_g   f64
	i_g_y f64
	i_g_z f64
}

pub struct Circular {
	name string = 'Circular'
	d    f64 // diameter

	i_g   f64
	i_g_y f64
	i_g_z f64
}

pub fn Circular.stick(d f64) Circular {
	i_g := math.pi * pow(d, 4) / 32
	i_g_a := i_g / 2

	return Circular{
		d:     d
		i_g:   i_g
		i_g_y: i_g_a
		i_g_z: i_g_a
	}
}

pub struct Rectangular {
	name string = 'Rectangular'
	h    f64 // height along the Y axis
	w    f64 // width along the Z axis

	i_g   f64
	i_g_y f64
	i_g_z f64
}

pub fn Rectangular.stick(h f64, w f64) Rectangular {
	// assume that h is the height along the Y axis and w the width along the Z axis
	i_g_y := h * pow(w, 3) / 12
	i_g_z := w * pow(h, 3) / 12

	return Rectangular{
		h:     h
		w:     w
		i_g_y: i_g_y
		i_g_z: i_g_z
	}
}

// b: Material

// HYPOTHESIS:
// Continus
// Homogeneity
// Isotropic
pub struct Material {
	re f64 // MPa Elastic resistance
	rg f64 // MPa Sliding resistance (around re/2)
	e  f64 // Young modulus
}

pub fn Material.simple(re f64, e f64) Material {
	return Material{
		re: re
		rg: re / 2
		e:  e
	}
}

pub fn Material.adcanced(re f64, rg f64, e f64) Material {
	return Material{
		re: re
		rg: rg
		e:  e
	}
}

// B: Solve
// a: Shear_and_moment_diagram
// b: Constraints
// c: Deplacements
// d: Force

pub type X_function = fn (x f64) f64

fn x_zero(x f64) f64 {
	return 0
}

fn x_const(x f64, cst f64) f64 {
	return cst
}

fn (f1 X_function) + (f2 X_function) X_function {
	if f1 == x_zero {
		return f2
	}
	if f2 == x_zero {
		return f1
	}
	return fn [f1, f2] (x f64) f64 {
		return f1(x) + f2(x)
	}
}

// a:
// 1: shears
// 2: moments
pub struct Shear_and_moment_diagram {
	// 1:
	n  X_function = x_zero
	ty X_function = x_zero
	tz X_function = x_zero
	// 2:
	mt  X_function = x_zero
	mfy X_function = x_zero
	mfz X_function = x_zero
}

fn (smd1 Shear_and_moment_diagram) + (smd2 Shear_and_moment_diagram) Shear_and_moment_diagram {
	return Shear_and_moment_diagram{
		n:   smd1.n + smd2.n
		ty:  smd1.ty + smd2.ty
		tz:  smd1.tz + smd2.tz
		mt:  smd1.mt + smd2.mt
		mfy: smd1.mfy + smd2.mfy
		mfz: smd1.mfz + smd2.mfz
	}
}

// b: Constraints
pub struct Constraints {
	sigma f64
	taux  f64
}

fn (c1 Constraints) + (c2 Constraints) Constraints {
	sigma := c1.sigma + c2.sigma
	taux := c1.taux + c2.taux
	return Constraints{
		sigma: sigma
		taux:  taux
	}
}

// c: Deplacements
// 1: translations
// 2: rotation
pub struct Deplacements {
	// 1:
	ux X_function = x_zero
	uy X_function = x_zero
	uz X_function = x_zero
	// 2:
	rx X_function = x_zero
	ry X_function = x_zero
	rz X_function = x_zero
}

fn (d1 Deplacements) + (d2 Deplacements) Deplacements {
	return Deplacements{
		ux: d1.ux + d2.ux
		uy: d1.uy + d2.uy
		uz: d1.uz + d2.uz
		rx: d1.rx + d2.rx
		ry: d1.ry + d2.ry
		rz: d1.rz + d2.rz
	}
}

// d: Force
pub struct Force {
pub:
	// point vec3[f64]
	// f     vec3[f64]
}

pub fn solve_forces_solicitation(stick Stick_type, forces []Force) (Shear_and_moment_diagram, Constraints, Deplacements) {
	mut total_smd := Shear_and_moment_diagram{}
	mut total_constraints := Constraints{}
	mut total_deplacements := Deplacements{}
	for force in forces {
		new_smd, new_constraints, new_deplacements := solve_one(stick, force)
		total_smd += new_smd
		total_constraints += new_constraints
		total_deplacements += new_deplacements
	}
	return total_smd, total_constraints, total_deplacements
}

fn solve_one(stick Stick_type, force Force) (Shear_and_moment_diagram, Constraints, Deplacements) {
	smd := get_smd(stick, force)
	constraints := get_constraints(stick, smd)
	deplacements := get_deplacements(stick, smd)

	return smd, constraints, deplacements
}

pub fn get_smd(stick Stick_type, force Force) Shear_and_moment_diagram {
	// cstx := force.f.x
	// csty := force.f.y
	// cstz := force.f.z

	// Hypothesis of a straight beam
	smd := Shear_and_moment_diagram{
		// ux: fn [cstx] (x f64) f64 {
		// 	return x_const(x, cstx)
		// }
		// uy: fn [csty] (x f64) f64 {
		// 	return x_const(x, csty)
		// }
		// uz: fn [cstz] (x f64) f64 {
		// 	return x_const(x, cstz)
		// }

		// mfy: fn [cstz] (x f64) f64 {
		// 	return x * cstz
		// }
		// mfz: fn [csty] (x f64) f64 {
		// 	return -x * csty
		// }
	}

	return smd
}

fn get_constraints(stick Stick_type, smd Shear_and_moment_diagram) Constraints {
	return Constraints{}
}

fn get_deplacements(stick Stick_type, smd Shear_and_moment_diagram) Deplacements {
	return Deplacements{}
}
