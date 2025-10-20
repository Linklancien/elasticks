import linklancien.elasticks as rdm
import math.vec { vec3 }
import gg

struct App {
mut:
	ctx   &gg.Context = unsafe { nil }
	smd   rdm.Shear_and_moment_diagram
	mvt   rdm.Deplacements
	stick rdm.Stick_type
}

fn main() {
	d := 10
	re := 1
	e := 2

	mut app := &App{
		stick: rdm.Stick_type{
			lenght:   500
			section:  rdm.Circular.stick(d)
			material: rdm.Material.simple(re, e)
		}
	}
	println(app.stick)
	app.ctx = gg.new_context(
		fullscreen:    false
		width:         100 * 17
		height:        100 * 7
		create_window: true
		window_title:  '-Elastick example-'
		bg_color:      gg.gray
		user_data:     app
		frame_fn:      on_frame
		sample_count:  4
	)

	force1 := rdm.Force{
		point: vec3[f32](app.stick.lenght/2, 0, 0)
		f:     vec3[f32](0, 10, 0)
	}
	force2 := rdm.Force{
		point: vec3[f32](app.stick.lenght, 0, 0)
		f:     vec3[f32](0, 0, 0)
	}
	forces := [force1, force2]

	app.smd, _, app.mvt = rdm.solve_forces_solicitation(app.stick, forces)
	println('All Example')
	println(app.smd.mfz)
	println(app.mvt.uy)
	app.ctx.run()
}

fn on_frame(mut app App) {
	nb := 2000
	app.ctx.begin()
	// rdm.render_all_graph(app.ctx, app.smd, app.mvt, app.stick, nb)
	abscise := app.mvt.uy.get_abscise(nb)
	value := app.mvt.uy.get_values(nb)
	rdm.render_graph(app.ctx, 20, 20, 1200, 600, abscise, value, 'uy en mm')
	app.ctx.end()
}
