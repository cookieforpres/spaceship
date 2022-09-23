module spaceship

import os

pub struct Response {
mut:
	status_code_name string

pub mut:
	status_code int
	headers map[string]string
	cookies []&Cookie
	body string
}

pub struct Route {
pub mut:
	path string
	methods []string
	handler fn(mut req Request, mut res Response)
}

pub fn new_response() Response {
	mut res := Response{}
	res.add_header('Content-Type', 'text/plain;charset=UTF-8')
	res.add_header('Server', 'spaceship')

	return res
}

pub fn (mut sp Spaceship) add_route(route Route)  {
	sp.routes << &route
}

pub fn (mut resp Response) set_status_code(status_code int) {
	codes := get_status_codes()
	for key, value in codes {
		if key == status_code {
			resp.status_code_name = value
		}
	}

	resp.status_code = status_code
}

pub fn (mut resp Response) add_header(key string, value string) {
	if key == 'Content-Type' {
		if value.contains('charset=') {
			resp.headers[key] = value
		} else {
			resp.headers[key] = value + ';charset=UTF-8'
		}
	} else {
		resp.headers[key] = value
	}
}

pub fn (mut resp Response) remove_header(key string) {
	resp.headers.delete(key)
}

pub fn (mut resp Response) set_body(body string) {
	resp.body = body
}

pub fn (mut resp Response) send_file(path string) {
	data := os.read_file(path) or {
		eprintln('[\x1b[31;1merror\x1b[0m] $err')
		exit(1)
	}

	resp.set_body(data)
}

pub fn new_route(path string, methods []string, handler fn(mut req Request, mut res Response)) Route {
	if methods.len == 0 {
		return Route {
			path: path,
			methods:  ['GET', 'POST', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'PATCH'],
			handler: handler
		}
	} else {
		return Route {
			path: path,
			methods: methods,
			handler: handler
		}
	}
}