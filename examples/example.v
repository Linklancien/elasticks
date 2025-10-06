import linklancien.elasticks as rdm
import math.vec { vec3 }
import arrays { max, min }
import gg

struct App {
mut:
	ctx &gg.Context = unsafe { nil }
	smd rdm.Shear_and_moment_diagram
	l   f32
}

fn main() {
	mut app := &App{}
	app.ctx = gg.new_context(
		fullscreen:    false
		width:         100 * 12
		height:        100 * 6
		create_window: true
		window_title:  '-Elastick example-'
		bg_color:      gg.gray
		user_data:     app
		frame_fn:      on_frame
		sample_count:  4
	)

	app.l = 500
	d := 2
	re := 1
	e := 2
	stick := rdm.Stick_type{
		lenght:   app.l
		section:  rdm.Circular.stick(d)
		material: rdm.Material.simple(re, e)
	}

	force1 := rdm.Force{
		point: vec3[f32](app.l/2, 0, 0)
		f:     vec3[f32](10, 0, 0)
	}
	force2 := rdm.Force{
		point: vec3[f32](app.l, 0, 0)
		f:     vec3[f32](0, -10, -1)
	}

	app.smd, _, _= rdm.solve_forces_solicitation(stick, [force1, force2])
	// print(app.smd)
	app.ctx.run()
}

fn on_frame(mut app App) {
	app.ctx.begin()
	app.render_all_graph()
	app.ctx.end()
}

fn (app App) render_all_graph() {
	dec := 50
	mut x := dec
	mut y := dec/2
	w := 500
	h := 100
	nb := 2000
	// left
	// n
	abscise := []f32{len: nb + 1, init: app.l * index / nb}
	mut value := []f32{len: nb + 1, init: app.smd.n(app.l * index / nb)}
	app.render_graph(x, y, w, h, abscise, value, 'n en MPa')
	// ty
	y += h + dec
	value = []f32{len: nb + 1, init: app.smd.ty(app.l * index / nb)}
	app.render_graph(x, y, w, h, abscise, value, 'ty en MPa')
	// mfz
	y += h + dec
	value = []f32{len: nb + 1, init: app.smd.mfz(app.l * index / nb)}
	app.render_graph(x, y, w, h, abscise, value, 'mfz en MPa')
	// change side
	x += w + dec
	y = dec/2
	// right
	// mt
	value = []f32{len: nb + 1, init: app.smd.mt(app.l * index / nb)}
	app.render_graph(x, y, w, h, abscise, value, 'mt en MPa')
	// tz
	y += h + dec
	value = []f32{len: nb + 1, init: app.smd.tz(app.l * index / nb)}
	app.render_graph(x, y, w, h, abscise, value, 'tz en MPa')
	// mft
	y += h + dec
	value = []f32{len: nb + 1, init: app.smd.mfy(app.l * index / nb)}
	app.render_graph(x, y, w, h, abscise, value, 'mfy en MPa')
}

fn (app App) render_graph(x f32, y f32, w f32, h f32, abscise []f32, value []f32, name string) {
	max_value := max(value) or { panic('No max value') }
	min_value := min(value) or { panic('No min value') }

	croissance := value[value.len - 1] - value[0]
	mut y0 := y
	mut y1 := y
	if croissance > 0 {
		y0 += h
	} else if croissance < 0 {
		y1 += h
	}

	mut max_y := f32(max_value)
	if max_value == min_value {
		max_y = max_value
	}
	else if max_value > -min_value {
		max_y = max_value
	}
	else if max_value < -min_value {
		max_y = min_value
	}
	max_a := max(abscise) or { panic('No max abscise') }

	app.ctx.draw_rounded_rect_filled(x - 10, y - 10, w + 35, h + 35, 5, gg.dark_gray)
	for k in 0 .. (abscise.len - 1) {
		app.ctx.draw_line(x + w * abscise[k] / max_a, y1 + (y0 - y1) * value[k] / max_y,
			x + w * abscise[k + 1] / max_a, y1 + (y0 - y1) * value[k + 1] / max_y, gg.red)
	}
	app.ctx.draw_text_def(int(x), int(y0), '${value[0]}')
	app.ctx.draw_text_def(int(x + w), int(y1), '${value[abscise.len - 1]}')
	app.ctx.draw_text_def(int(x + w / 2), int(y + h), name)
}
