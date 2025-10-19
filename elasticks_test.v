module elasticks

import math.vec { vec3 }


// POLY TEST
fn test_get_abscise() {
	polys := [
		Polynomials{},
		Polynomials{
			restriction:      [f32(0), 100]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 50, 100]
			restricted_terms: [[f32(10)], [f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 50, 100, 150]
			restricted_terms: [[f32(10)], [f32(20)], [f32(30)]]
		},
	]
	for pol in polys {
		nb := 500
		abscise := pol.get_abscise(nb)

		assert nb == abscise.len, 'not the same len as the one expected ${pol.restriction} ${abscise}'
	}
}

fn test_get_values() {
	polys := [
		Polynomials{},
		Polynomials{
			restriction:      [f32(0), 100]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 50, 100]
			restricted_terms: [[f32(10)], [f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 50, 100, 150]
			restricted_terms: [[f32(10)], [f32(20)], [f32(30)]]
		},
	]
	for pol in polys {
		nb := 500
		values := pol.get_values(nb)

		assert nb == values.len, 'not the same len as the one expected ${pol.restriction} ${values}'
	}
}

fn test_polynomials_add() {
	p1 := Polynomials{
		restriction:      [f32(0), 10]
		restricted_terms: [[f32(10)]]
	}

	sum := add(p1, p1)
	assert sum.restricted_terms == [[f32(20)]], "error, addition doesn't work proprely ${sum}"

	p2 := Polynomials{
		restriction:      [f32(0), 10]
		restricted_terms: [[f32(0), 1]]
	}

	sum12 := add(p1, p2)
	sum21 := add(p2, p1)
	assert sum12.restricted_terms == sum21.restricted_terms, 'sum is not reversible, ${sum12.restricted_terms} != ${sum21.restricted_terms}'

	p3 := Polynomials{
		restriction:      [f32(0), 5]
		restricted_terms: [[f32(0), 1]]
	}

	p4 := Polynomials{
		restriction:      [f32(5), 10]
		restricted_terms: [[f32(2), 1]]
	}
	println('Complex')
	sum34 := add(p3, p4)
	sum43 := add(p4, p3)
	assert sum34 == sum43, 'complex sum is not reversible ${sum34}, ${sum43}'
	assert sum34.restriction == [f32(0), 5, 10], 'wrong complex restriction ${sum34}'
	assert sum34.restricted_terms == [[f32(0), 1], [f32(2), 1]], 'wrong complex restricted_terms ${sum34}'

	p5 := Polynomials{
		restriction:      [f32(0), 5]
		restricted_terms: [[f32(2), 1]]
	}
	p6 := Polynomials{
		restriction:      [f32(0), 10]
		restricted_terms: [[f32(0)]]
	}

	sum56 := add(p5, p6)

	assert sum56.restriction.len == 3, 'sum56 $sum56'
	assert sum56.restricted_terms.len == 2, 'sum56 $sum56'
	assert sum56.restricted_terms[1] == [f32(0)], 'sum56 $sum56'
}

fn test_polynomials_value() {
	p1 := Polynomials{
		restriction:      [f32(0), 10]
		restricted_terms: [[f32(10)]]
	}

	value := p1.value(5)
	assert value[0] == f32(10), "error, value doesn't work proprely ${p1}"

	p2 := Polynomials{
		restriction:      [f32(0), 6]
		restricted_terms: [[f32(0), 1]]
	}

	assert p2.value(0)[0] == 0.0, "error, value doesn't work proprely"
	assert p2.value(1)[0] == 1.0, "error, value doesn't work proprely"
	assert p2.value(5)[0] == 5.0, "error, value doesn't work proprely"
	assert p2.value(5.5)[0] == 5.5, "error, value doesn't work proprely"
}

fn test_scalar_mult(){
	polys := [
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20), f32(30)]]
		},
	]
	for p in polys[1..] {
		pol := p.scalar_mult(20)

		assert p.restriction.len == pol.restriction.len, 'failed $pol.restriction'
		assert p.restricted_terms.len == pol.restricted_terms.len, 'failed $pol.restricted_terms'
	}
}

fn test_extend(){
	polys := [
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20), f32(30)]]
		},
	]
	for p in polys[1..] {
		pol := p.extend(20)

		assert pol.restriction.len == 3, 'failed $pol.restriction'
		assert pol.restricted_terms.len == 2, 'failed $pol.restricted_terms'
		assert pol.restricted_terms[1].len == 1, 'failed ${pol.restricted_terms[1]}'
	}
}

fn test_integrate() {
	polys := [
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20), f32(30)]]
		},
	]
	for p in polys[1..] {
		cst := 0
		pol := p.integrate(cst)

		assert pol.restricted_terms[0].len == p.restricted_terms[0].len + 1, 'failed $pol.restricted_terms'
		assert pol.restricted_terms[0][0] == cst, 'failed ${pol.restricted_terms[0]}'
	}
}

fn test_derivate() {
	polys := [
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20), f32(30)]]
		},
	]
	for p in polys[1..] {
		pol := p.derivate()

		assert pol.restricted_terms[0].len == p.restricted_terms[0].len - 1, 'failed $pol.restricted_terms'
	}
}

fn test_integrate_scalar_mult_extend() {
	polys := [
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20)]]
		},
		Polynomials{
			restriction:      [f32(0), 10]
			restricted_terms: [[f32(10), f32(20), f32(30)]]
		},
	]
	for p in polys[1..] {
		pol := p.integrate(0).scalar_mult(1).extend(20)

		assert pol.restricted_terms.len == p.restricted_terms.len + 1, 'failed $pol.restricted_terms'
		assert pol.restricted_terms[pol.restricted_terms.len - 1].len == 1, 'failed $pol.restricted_terms'
	}

	// Special case:
	p1 := elasticks.Polynomials{
		restriction: [f32(0.0), 250.0]
		restricted_terms: [[f32(2500.0), -10.0]]
	}
	p2 := elasticks.Polynomials{
		restriction: [f32(0.0), 500.0]
		restricted_terms: [[f32(0.0), 0.0]]
	}

	pol1 := p1.integrate(0).scalar_mult(1).extend(500)

	assert pol1.restricted_terms.len == p1.restricted_terms.len + 1, 'pol1 failed $pol1.restricted_terms'
	assert pol1.restricted_terms[pol1.restricted_terms.len - 1].len == 1, 'pol1 failed $pol1.restricted_terms' // extended by 0 may be not optimal

	pol2 := p2.integrate(0).scalar_mult(1).extend(500)

	add_pol := add(pol1, pol2)

	assert add_pol.restriction.len == 3, 'add_pol failed $add_pol'
	assert add_pol.restricted_terms.len == 2, 'add_pol failed $add_pol'
	assert add_pol.restricted_terms[1].len == 1, 'add_pol failed $pol1, $pol2, $add_pol'
}

// RDM TEST

fn test_get_smd() {
	l := 2_000
	d := 2
	re := 1
	e := 2
	stick := Stick_type{
		lenght:   l
		section:  Circular.stick(d)
		material: Material.simple(re, e)
	}

	force := Force{
		point: vec3[f32](l, 0, 0)
		f:     vec3[f32](0, 10, 0)
	}

	smd := get_smd(stick, force)
	// assert 1 == 0
}
