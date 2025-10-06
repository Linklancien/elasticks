module elasticks

import math { pow }
import math.vec { Vec3 }

// A: Stick_type
// B: Solve

// A: Stick_type
// a: Section
// b: Material
pub struct Stick_type {
pub:
	lenght   f32
	section  Section
	material Material
}

// a: Section
interface Section {
	name string

	i_g   f32
	i_g_y f32
	i_g_z f32
}

pub struct Circular {
	name string = 'Circular'
	d    f32 // diameter

	i_g   f32
	i_g_y f32
	i_g_z f32
}

pub fn Circular.stick(d f32) Circular {
	i_g := f32(math.pi * pow(d, 4) / 32)
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
	h    f32 // height along the Y axis
	w    f32 // width along the Z axis

	i_g   f32
	i_g_y f32
	i_g_z f32
}

pub fn Rectangular.stick(h f32, w f32) Rectangular {
	// assume that h is the height along the Y axis and w the width along the Z axis
	i_g_y := f32(h * pow(w, 3) / 12)
	i_g_z := f32(w * pow(h, 3) / 12)

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
	re f32 // MPa Elastic resistance
	rg f32 // MPa Sliding resistance (around re/2)
	e  f32 // Young modulus
}

pub fn Material.simple(re f32, e f32) Material {
	return Material{
		re: re
		rg: re / 2
		e:  e
	}
}

pub fn Material.adcanced(re f32, rg f32, e f32) Material {
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

pub struct Polynomials {
	restriction      []f32
	restricted_terms [][]f32
}

fn (pol Polynomials) interval(x f32) int {
	for k in 0 .. pol.restriction.len - 1 {
		if pol.restriction[k] <= x && x <= pol.restriction[k] {
			return k
		}
	}
	return -1
}

pub fn (pol Polynomials) value(x f32) f32 {
	interval := pol.interval(x)
	if interval == -1 {
		return 0
	}

	mut r := f32(0.0)
	for i, term in pol.restricted_terms[interval] {
		r += f32(term * pow(x, i))
	}
	return r
}

fn (pol Polynomials) integrate(x f32) Polynomials {
	restricted_terms := [][]f32{}
	for id, terms in pol.restricted_terms {
		mut new_terms := []f32{len: 1, init: 0}
		for i, term in terms {
			new_terms << term / i
		}
		restricted_terms[id] << new_terms
	}

	return Polynomials{
		restriction:      pol.restriction
		restricted_terms: restricted_terms
	}
}

fn (pol Polynomials) derivate(x f32) Polynomials {
	restricted_terms := [][]f32{}
	for id, terms in pol.restricted_terms {
		mut new_terms := []f32{len: 1, init: 0}
		for i, term in pol.terms {
			if i > 0 {
				terms << term * i
			}
		}
		restricted_terms[id] << new_terms
	}

	return Polynomials{
		restriction:      pol.restriction
		restricted_terms: restricted_terms
	}
}

fn add(p1 Polynomials, p2 Polynomials) Polynomials {
	mut terms := []f32{}
	for term in p1.terms {
		terms << term
	}

	for i, term in p1.terms {
		if i < terms.len {
			terms[i] += term
		} else {
			terms << term
		}
	}
	return Polynomials{
		terms: terms
	}
}

// a:
// 1: shears
// 2: moments
pub struct Shear_and_moment_diagram {
pub:
	// 1:
	n  Polynomials
	ty Polynomials
	tz Polynomials
	// 2:
	mt  Polynomials
	mfy Polynomials
	mfz Polynomials
}

fn (smd1 Shear_and_moment_diagram) + (smd2 Shear_and_moment_diagram) Shear_and_moment_diagram {
	return Shear_and_moment_diagram{
		n:   add(smd1.n, smd2.n)
		ty:  add(smd1.ty, smd2.ty)
		tz:  add(smd1.tz, smd2.tz)
		mt:  add(smd1.mt, smd2.mt)
		mfy: add(smd1.mfy, smd2.mfy)
		mfz: add(smd1.mfz, smd2.mfz)
	}
}

// b: Constraints
pub struct Constraints {
	sigma f32
	taux  f32
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
pub:
	// 1:
	ux Polynomials
	uy Polynomials
	uz Polynomials
	// 2:
	rx Polynomials
	ry Polynomials
	rz Polynomials
}

fn (d1 Deplacements) + (d2 Deplacements) Deplacements {
	return Deplacements{
		ux: add(d1.ux, d2.ux)
		uy: add(d1.uy, d2.uy)
		uz: add(d1.uz, d2.uz)
		rx: add(d1.rx, d2.rx)
		ry: add(d1.ry, d2.ry)
		rz: add(d1.rz, d2.rz)
	}
}

// d: Force
pub struct Force {
pub:
	point Vec3[f32]
	f     Vec3[f32]
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
	cstx := force.f.x
	csty := force.f.y
	cstz := force.f.z

	pos_x := force.point.x

	// Hypothesis of a straight beam
	smd := Shear_and_moment_diagram{
		n:  Polynomials{
			terms: [cstx]
		}
		ty: Polynomials{
			terms: [csty]
		}
		tz: Polynomials{
			terms: [cstz]
		}

		mfy: Polynomials{
			terms: [-pos_x * cstz, cstz]
		}
		mfz: Polynomials{
			terms: [pos_x * cstz, -cstz]
		}
	}
	println(smd)

	return smd
}

fn get_constraints(stick Stick_type, smd Shear_and_moment_diagram) Constraints {
	return Constraints{}
}

fn get_deplacements(stick Stick_type, smd Shear_and_moment_diagram) Deplacements {
	return Deplacements{}
}
