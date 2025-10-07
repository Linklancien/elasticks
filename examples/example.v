import linklancien.elasticks as rdm
import math.vec { vec3 }
import arrays { max, min }
import gg

struct App {
mut:
	ctx   &gg.Context = unsafe { nil }
	smd   rdm.Shear_and_moment_diagram
	mvt   rdm.Deplacements
	stick rdm.Stick_type
}

fn main() {
	d := 2
	re := 1
	e := 2

	mut app := &App{
		stick: rdm.Stick_type{
			lenght:   500
			section:  rdm.Circular.stick(d)
			material: rdm.Material.simple(re, e)
		}
	}
	app.ctx = gg.new_context(
		fullscreen:    false
		width:         100 * 18
		height:        100 * 6
		create_window: true
		window_title:  '-Elastick example-'
		bg_color:      gg.gray
		user_data:     app
		frame_fn:      on_frame
		sample_count:  4
	)

	force1 := rdm.Force{
		point: vec3[f32](app.stick.lenght / 2, 0, 0)
		f:     vec3[f32](0, 10, 10)
	}
	force2 := rdm.Force{
		point: vec3[f32](app.stick.lenght, 0, 0)
		f:     vec3[f32](0, 10, 10)
	}

	app.smd, _, app.mvt = rdm.solve_forces_solicitation(app.stick, [force1, force2])
	println('All Example')
	// println(app.smd)
	println(app.mvt)
	app.ctx.run()
}

fn on_frame(mut app App) {
	app.ctx.begin()
	render_all_graph(app.ctx, app.smd, app.mvt, app.stick)
	app.ctx.end()
}

fn render_all_graph(ctx gg.Context, sdm rdm.Shear_and_moment_diagram, mvt rdm.Deplacements, stick rdm.Stick_type) {
	l := stick.lenght
	dec := 50
	mut x := dec
	mut y := dec / 2
	w := 500
	h := 100
	nb := 2000
	// left
	// n
	abscise := []f32{len: nb + 1, init: l * index / nb}
	mut value := []f32{len: nb + 1, init: sdm.n.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'n en MPa')
	// ty
	y += h + dec
	value = []f32{len: nb + 1, init: sdm.ty.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'ty en MPa')
	// mfz
	y += h + dec
	value = []f32{len: nb + 1, init: sdm.mfz.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'mfz en MPa')
	y += h + dec
	value = []f32{len: nb + 1, init: mvt.uy.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'uy en MPa')

	// change side /////
	x += w + dec
	y = dec / 2
	// right
	// mt
	value = []f32{len: nb + 1, init: sdm.mt.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'mt en MPa')
	// tz
	y += h + dec
	value = []f32{len: nb + 1, init: sdm.tz.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'tz en MPa')
	// mft
	y += h + dec
	value = []f32{len: nb + 1, init: sdm.mfy.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'mfy en MPa')
	y += h + dec
	value = []f32{len: nb + 1, init: mvt.uz.value(l * index / nb)}
	render_graph(ctx, x, y, w, h, abscise, value, 'uz en MPa')
}

fn render_graph(ctx gg.Context, x f32, y f32, w f32, h f32, abscise []f32, value []f32, name string) {
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
	} else if max_value > -min_value {
		max_y = max_value
	} else if max_value < -min_value {
		max_y = min_value
	}
	max_a := max(abscise) or { panic('No max abscise') }

	ctx.draw_rounded_rect_filled(x - 10, y - 10, w + 35, h + 35, 5, gg.dark_gray)
	for k in 0 .. (abscise.len - 1) {
		ctx.draw_line(x + w * abscise[k] / max_a, y1 + (y0 - y1) * value[k] / max_y, x +
			w * abscise[k + 1] / max_a, y1 + (y0 - y1) * value[k + 1] / max_y, gg.red)
	}
	ctx.draw_text_def(int(x), int(y0), '${value[0]}')
	ctx.draw_text_def(int(x + w), int(y1), '${value[abscise.len - 1]}')
	ctx.draw_text_def(int(x + w / 2), int(y + h), name)
}
