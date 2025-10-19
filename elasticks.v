module elasticks

import math { pow }
import math.vec { Vec3 }
import gg
import arrays { max, min }

// A: Stick_type
// B: Solve
// C: Graph using gg

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

	surface f32

	i_g   f32
	i_g_y f32
	i_g_z f32
}

pub struct Circular {
	name string = 'Circular'
	d    f32 // diameter

	surface f32

	i_g   f32
	i_g_y f32
	i_g_z f32
}

pub fn Circular.stick(d f32) Circular {
	i_g := f32(math.pi * pow(d, 4) / 32)
	i_g_a := i_g / 2

	return Circular{
		d:       d
		surface: f32(math.pi * pow(d / 2, 2))
		i_g:     i_g
		i_g_y:   i_g_a
		i_g_z:   i_g_a
	}
}

pub struct Rectangular {
	name string = 'Rectangular'
	h    f32 // height along the Y axis
	w    f32 // width along the Z axis

	surface f32

	i_g   f32
	i_g_y f32
	i_g_z f32
}

pub fn Rectangular.stick(h f32, w f32) Rectangular {
	// assume that h is the height along the Y axis and w the width along the Z axis
	i_g_y := f32(h * pow(w, 3) / 12)
	i_g_z := f32(w * pow(h, 3) / 12)

	return Rectangular{
		h:       h
		w:       w
		surface: h * w
		i_g_y:   i_g_y
		i_g_z:   i_g_z
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
// a: Polynomials
// b: Shear_and_moment_diagram
// c: Constraints
// d: Deplacements
// c: Force

// a: Polynomials
pub struct Polynomials {
	restriction      []f32 = [f32(0.0), 0]
	restricted_terms [][]f32
}

// Intervales
fn (pol Polynomials) get_interval(x f32) []int {
	for k in 0 .. pol.restriction.len - 1 {
		if pol.restriction[k] < x && x < pol.restriction[k + 1] {
			return [k]
		} else if pol.restriction[k] == x {
			if k != 0 {
				return [k - 1, k]
			} else {
				return [0]
			}
		}
	}
	return [-1]
}

fn union_interval(p1 Polynomials, p2 Polynomials) []f32 {
	mut restriction := []f32{}
	mut id1 := 0
	mut id2 := 0
	len1 := p1.restriction.len
	len2 := p2.restriction.len
	for id1 != len1 || id2 != len2 {
		if id1 == len1 {
			restriction << p2.restriction[id2]
			id2 += 1
		} else if id2 == len2 {
			restriction << p1.restriction[id1]
			id1 += 1
		} else if p1.restriction[id1] == p2.restriction[id2] {
			if restriction.len == 0 {
				restriction << p1.restriction[id1]
			} else if restriction[restriction.len - 1] != p1.restriction[id1] {
				restriction << p1.restriction[id1]
			}
			id1 += 1
			id2 += 1
		} else if p1.restriction[id1] > p2.restriction[id2] {
			if restriction.len == 0 {
				restriction << p2.restriction[id2]
			} else if restriction[restriction.len - 1] != p2.restriction[id2] {
				restriction << p2.restriction[id2]
			}
			id2 += 1
		} else if p1.restriction[id1] < p2.restriction[id2] {
			if restriction.len == 0 {
				restriction << p1.restriction[id1]
			} else if restriction[restriction.len - 1] != p1.restriction[id1] {
				restriction << p1.restriction[id1]
			}
			id1 += 1
		} else {
			panic('Case not handle: ${id1}: ${p1.restriction[id1]} & ${id2}: ${p2.restriction[id2]}')
		}
		// debug:
		// println('$id1/$len1, $id2/$len2 :$restriction ${id1 != len1 || id2 != len2}')
	}
	// println('END:')
	// println(restriction)
	return restriction
}

//
pub fn (pol Polynomials) value(x f32) []f32 {
	interval := pol.get_interval(x)
	if interval == [-1] {
		return [f32(0.0)]
	}
	mut values := []f32{}
	for i in interval {
		values << pol_evaluated(x, pol.restricted_terms[i])
	}
	return values
}

fn pol_evaluated(x f32, pol []f32) f32 {
	mut r := f32(0.0)
	for i, term in pol {
		r += f32(term * pow(x, i))
	}
	return r
}

fn (pol Polynomials) integrate(cst f32) Polynomials {
	mut restricted_terms := [][]f32{len: pol.restricted_terms.len, init: []f32{}}
	for id, terms in pol.restricted_terms {
		if id != pol.restricted_terms.len {
			mut new_terms := []f32{len: 1, init: cst}
			for i, term in terms {
				if i != 0 {
					new_terms << term / i
				} else {
					new_terms << term
				}
			}
			restricted_terms[id] << new_terms
		}
	}
	return Polynomials{
		restriction:      pol.restriction
		restricted_terms: restricted_terms
	}
}

fn (pol Polynomials) derivate() Polynomials {
	mut restricted_terms := [][]f32{len: pol.restricted_terms.len, init: []f32{}}
	for id, terms in pol.restricted_terms {
		if id != pol.restricted_terms.len {
			mut new_terms := []f32{}
			for i, term in terms {
				if i > 0 {
					new_terms << term * i
				}
			}
			restricted_terms[id] << new_terms
		}
	}

	return Polynomials{
		restriction:      pol.restriction
		restricted_terms: restricted_terms
	}
}

fn add(p1 Polynomials, p2 Polynomials) Polynomials {
	if p1.restriction == [f32(0.0), 0.0] {
		return p2
	} else if p2.restriction == [f32(0.0), 0.0] {
		return p1
	}
	restriction := union_interval(p1, p2)
	restricted_terms := complex_add(p1, p2, restriction)

	return Polynomials{
		restriction:      restriction
		restricted_terms: restricted_terms
	}
}

fn complex_add(p1 Polynomials, p2 Polynomials, restriction []f32) [][]f32 {
	mut restricted_terms := [][]f32{}

	for k in 0 .. restriction.len - 1 {
		mut terms := []f32{}
		id1 := p1.get_interval(restriction[k])
		if id1 != [-1] {
			for term in p1.restricted_terms[id1[0]] {
				terms << term
			}
		}

		id2 := p2.get_interval(restriction[k])
		if id2 != [-1] {
			for id_term, term in p2.restricted_terms[id2[0]] {
				if id_term >= terms.len {
					terms << term
				} else {
					terms[id_term] += term
				}
			}
		}

		restricted_terms << terms
	}
	return restricted_terms
}

fn (pol Polynomials) scalar_mult(m f32) Polynomials {
	mut restricted_terms := [][]f32{len: pol.restricted_terms.len, init: []f32{}}
	for id, terms in pol.restricted_terms {
		if id != pol.restricted_terms.len {
			mut new_terms := []f32{}
			for term in terms {
				new_terms << term * m
			}
			restricted_terms[id] << new_terms
		}
	}
	return Polynomials{
		restriction:      pol.restriction
		restricted_terms: restricted_terms
	}
}

fn (pol Polynomials) extend(l f32) Polynomials {
	mut restricted_terms := pol.restricted_terms.clone()
	mut restriction := pol.restriction.clone()
	if restriction[restriction.len - 1] < l {
		restricted_terms << [
			pol_evaluated(restriction[restriction.len - 1], restricted_terms[restricted_terms.len - 1]),
		]
		restriction << [l]
	}
	return Polynomials{
		restriction:      restriction
		restricted_terms: restricted_terms
	}
}

fn (pol Polynomials) get_abscise(nb int) []f32 {
	real_nb := nb - 2 * pol.restriction.len + 1
	if pol.restriction == [f32(0.0), 0.0] {
		return []f32{len: nb, init: f32(0)}
	}
	max := pol.restriction[pol.restriction.len - 1]

	mut abscise := []f32{}
	mut desc_id := 0
	for disc in pol.restriction {
		if disc != pol.restriction[0] {
			local_proportion := int(real_nb * (disc / max)) - desc_id
			abscise << []f32{len: local_proportion, init: max * (index + desc_id) / real_nb}
			desc_id += local_proportion
		}
		if disc != max {
			abscise << [disc, disc]
		} else {
			abscise << [disc]
		}
	}

	return abscise
}

fn (pol Polynomials) get_values(nb int) []f32 {
	real_nb := nb - 2 * pol.restriction.len + 1
	if pol.restriction == [f32(0.0), 0.0] {
		return []f32{len: nb, init: f32(0)}
	}
	max := pol.restriction[pol.restriction.len - 1]

	mut values := []f32{}
	mut desc_id := 0
	for disc in pol.restriction {
		if disc != pol.restriction[0] {
			local_proportion := int(real_nb * (disc / max)) - desc_id
			values << []f32{len: local_proportion, init: pol.value(max * (index + desc_id) / real_nb)[0]}
			desc_id += local_proportion
		}
		if disc == max {
			values << [f32(0)]
		} else if disc == pol.restriction[0] {
			val := pol.value(disc)
			values << [f32(0), val[0]]
		} else {
			val := pol.value(disc)
			values << [val[0], val[1]]
		}
	}

	return values
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

// c: Constraints
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

// d: Deplacements
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

// c: Force
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
	res := [f32(0.0), force.point.x]

	// Hypothesis of a straight beam
	smd := Shear_and_moment_diagram{
		n:   Polynomials{
			restriction:      res
			restricted_terms: [[cstx]]
		}
		ty:  Polynomials{
			restriction:      res
			restricted_terms: [[csty]]
		}
		tz:  Polynomials{
			restriction:      res
			restricted_terms: [[cstz]]
		}
		mfy: Polynomials{
			restriction:      res
			restricted_terms: [[-pos_x * cstz, cstz]]
		}
		mfz: Polynomials{
			restriction:      res
			restricted_terms: [[pos_x * csty, -csty]]
		}
	}

	return smd
}

fn get_constraints(stick Stick_type, smd Shear_and_moment_diagram) Constraints {
	return Constraints{}
}

fn get_deplacements(stick Stick_type, smd Shear_and_moment_diagram) Deplacements {
	ux := smd.n.integrate(0).scalar_mult(stick.section.surface / stick.material.e).extend(stick.lenght)
	uy := smd.mfz.integrate(0).integrate(0).scalar_mult(-1 / (stick.material.e * stick.section.i_g_z)).extend(stick.lenght)
	uz := smd.mfy.integrate(0).integrate(0).scalar_mult(1 / (stick.material.e * stick.section.i_g_z)).extend(stick.lenght)
	return Deplacements{
		ux: ux
		uy: uy
		uz: uz
		// 2:
		// rx: Polynomials
		// ry: Polynomials
		// rz: Polynomials
	}
}

// C: Graph using gg
pub fn render_all_graph(ctx gg.Context, smd Shear_and_moment_diagram, mvt Deplacements, stick Stick_type) {
	dec := 50
	mut x := dec
	mut y := dec / 2
	w := 500
	h := 100
	nb := 2000
	// left
	// n
	abscise := smd.n.get_abscise(nb)
	mut value := smd.n.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'n en MPa')
	// ty
	y += h + dec
	value = smd.ty.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'ty en MPa')
	// mfz
	y += h + dec
	value = smd.mfz.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'mfz en MPa')
	y += h + dec
	value = mvt.uy.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'uy en mm')

	// change side /////
	x += w + dec
	y = dec / 2
	// right
	// mt
	value = smd.mt.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'mt en MPa')
	// tz
	y += h + dec
	value = smd.tz.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'tz en MPa')
	// mft
	y += h + dec
	value = smd.mfy.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'mfy en MPa')
	y += h + dec
	value = mvt.uz.get_values(nb)
	render_graph(ctx, x, y, w, h, abscise, value, 'uz en mm')
}

fn render_graph(ctx gg.Context, x f32, y f32, w f32, h f32, abscise []f32, value []f32, name string) {
	max := max(value) or { panic('No max value') }
	min := min(value) or { panic('No min value') }
	max_a := max(abscise) or { panic('No max abscise') }

	f := fn [max, min, y, h] (value f32) f32 {
		return y + h - h * (value - min) / (max - min)
	}

	mut render_max := true
	mut render_min := true

	ctx.draw_rounded_rect_filled(f32(x - 10), f32(y - 10), f32(w + 35), f32(h + 10 + 35),
		5, gg.dark_gray)
	for k in 0 .. (abscise.len - 1) {
		ctx.draw_line(f32(x + w * abscise[k] / max_a), f32(f(value[k])), f32(x + w * abscise[k +
			1] / max_a), f32(f(value[k + 1])), gg.red)
		if k == 0 || k == abscise.len - 2 {
			ctx.draw_text_def(int(x + w * abscise[k] / max_a), int(f(value[k])), 'x: ${abscise[k]}  y: ${value[k]}')
			if value[k] == min {
				render_min = false
			}
			if value[k] == max {
				render_max = false
			}
		} else if value[k] == max && render_max {
			ctx.draw_text_def(int(x + w * abscise[k] / max_a), int(f(value[k])), 'x: ${abscise[k]}  y: ${value[k]}')
			render_max = false
		} else if value[k] == min && render_min {
			ctx.draw_text_def(int(x + w * abscise[k] / max_a), int(f(value[k])), 'x: ${abscise[k]}  y: ${value[k]}')
			render_min = false
		}
	}
	// ctx.draw_text_def(int(x), int(f(value[0])), '${value[0]}')
	// ctx.draw_text_def(int(x + w), int(f(value[abscise.len - 1])), '${value[abscise.len - 1]}')
	ctx.draw_text_def(int(x + w / 2), int(y + h + 10), name)
}
