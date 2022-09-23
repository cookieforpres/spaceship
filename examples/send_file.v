module main

import cookieforpres.spaceship

fn handler(mut req spaceship.Request, mut res spaceship.Response) {
    res.add_header('Content-Type', 'application/json')
    res.send_file('index.json')
}

fn main() {
    mut sp := spaceship.new('0.0.0.0', 8080)

    mut route := spaceship.new_route('/', ['GET', 'POST'], handler)
    sp.add_route(route)

    sp.listen() or { panic(err) }
}