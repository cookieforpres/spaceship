module main

import cookieforpres.spaceship
import json

fn handler(mut req spaceship.Request, mut res spaceship.Response) {
    res.add_header('Content-Type', 'application/json')

    json_data := json.encode({'message': 'Welcome to Spaceship 🚀. Get ready for blast off!'})
    res.set_body(json_data)
}

fn main() {
    mut sp := spaceship.new('0.0.0.0', 8080)

    mut route := spaceship.new_route('/', ['GET', 'POST'], handler)
    sp.add_route(route)

    sp.listen() or { panic(err) }
}