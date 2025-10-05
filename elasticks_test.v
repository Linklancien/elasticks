import elasticks as rdm
import math.vec {vec3}

fn test_get_smd() {
	l := 2_000
	d := 2
	re := 1
	e := 2
	stick := rdm.Stick_type{
		lenght:   l
		section:  rdm.Circular.stick(d)
		material: rdm.Material.simple(re, e)
	}

	force := rdm.force{
		point: vec3[f32](l, 0, 0)
		f:     vec3[f32](0, 10, 0)
	}

	smd := rdm.get_smd(stick, force)
	print(smd)
}
