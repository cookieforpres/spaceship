module spaceship

pub struct SpaceshipConfig {
pub mut:
	verbose bool
	show_favicon_request bool
	show_server_header bool
}

pub fn (mut sp Spaceship) edit_config(id string, toggle bool) {
	match id {
		'verbose' { sp.config.verbose = toggle }
		'show_favicon_request' { sp.config.show_favicon_request = toggle }
		'show_server_header' { sp.config.show_server_header = toggle }
		else {}
	}
}