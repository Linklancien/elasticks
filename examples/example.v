import linklancien.elasticks as rdm
import math.vec { vec3 }
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
		f:     vec3[f32](0, -10, 0)
	}

	app.smd = rdm.get_smd(stick, force)
	// print(app.smd)
	app.ctx.run()
}

fn on_frame(mut app App) {
	app.ctx.begin()
	dec := 5
	app.ctx.draw_rounded_rect_filled(0, 0, app.l + 2*dec, 100 + 2*dec, 5, gg.gray)
	mut max_y := app.smd.mfz(app.l)
	mut start := f32(100.0)
	if max_y < 0{
		max_y = -max_y
		start = 0.0
	}
	for x in 0 .. int(app.l) {
		app.ctx.draw_line(x + dec, dec + start - 100*app.smd.mfz(x)/max_y, x + 1 + dec, dec + start - 100*app.smd.mfz(x + 1)/max_y, gg.red)
	}
	app.ctx.end()
}
