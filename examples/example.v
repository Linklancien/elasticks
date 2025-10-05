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
		width:         100 * 8
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

	force := rdm.Force{
		point: vec3[f32](app.l, 0, 0)
		f:     vec3[f32](1, -10, 0)
	}

	app.smd = rdm.get_smd(stick, force)
	// print(app.smd)
	app.ctx.run()
}

fn on_frame(mut app App) {
	app.ctx.begin()
	app.render_all_graph()
	app.ctx.end()
}

fn (app App) render_all_graph() {
	dec := 5
	x1 := dec
	mut y1 := dec
	w := 500
	h := 100
	nb := 2000
	//
	abscise := []f32{len: nb + 1, init: app.l * index / nb}
	value := []f32{len: nb + 1, init: app.smd.mfz(app.l * index / nb)}

	app.render_graph(x1, y1, w, h, abscise, value)
}

fn (app App) render_graph(x1 f32, y1 f32, w f32, h f32, abscise []f32, value []f32) {
	mut max_y := max(value) or { panic('No max value') }
	if max_y == 0.0 {
		max_y = -min(value) or { panic('No min value') }
	}
	max_a := max(abscise) or { panic('No max abscise') }
	println(max_a)
	for k in 0 .. (abscise.len - 1) {
		app.ctx.draw_line(x1 + w * abscise[k] / max_a, y1 - h * value[k] / max_y, x1 +
			w * abscise[k + 1] / max_a, y1 - h * value[k + 1] / max_y, gg.red)
	}
	app.ctx.draw_text_def(int(x1), int(y1), '${value[0]}')
	app.ctx.draw_text_def(int(x1 + w), int(y1 + h), '${value[abscise.len - 1]}')
}
