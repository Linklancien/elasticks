module elasticks

import math.vec { vec3 }

fn test_polynomials_add() {
	p1 := Polynomials{
		restricted_terms: [[f32(10)]]
	}

	sum := add(p1, p1)
	assert sum.restricted_terms == [[f32(20)]], "error, addition doesn't work proprely"

	p2 := Polynomials{
		restricted_terms: [[f32(0), 1]]
	}

	sum12 := add(p1, p2)
	sum21 := add(p2, p1)
	assert sum12.restricted_terms == sum21.restricted_terms, 'sum is not reversable, ${sum12.restricted_terms} != ${sum21.restricted_terms}'
}

fn test_polynomials_value() {
	p1 := Polynomials{
		restricted_terms: [[f32(10)]]
	}

	value := p1.value(10)
	assert value == f32(10), "error, addition doesn't work proprely"

	p2 := Polynomials{
		restricted_terms: [[f32(0), 1]]
	}

	assert p2.value(0) == 0.0, "error, addition doesn't work proprely"
	assert p2.value(1) == 1.0, "error, addition doesn't work proprely"
	assert p2.value(5) == 5.0, "error, addition doesn't work proprely"
	assert p2.value(5.5) == 5.5, "error, addition doesn't work proprely"
}

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
