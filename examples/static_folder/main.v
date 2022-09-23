module main

import cookieforpres.spaceship

fn handler(mut req spaceship.Request, mut res spaceship.Response) {
    res.add_header('Content-Type', 'text/html')
    res.send_file('index.html')
}

fn main() {
    mut sp := spaceship.new('0.0.0.0', 8080)
    sp.static_folder('static/') ?

    mut route := spaceship.new_route('/', ['GET', 'POST'], handler)
    sp.add_route(route)

    sp.listen() or { panic(err) }
}