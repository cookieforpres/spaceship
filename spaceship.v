module spaceship

import net
import time
import os

pub struct DefaultResponse {
pub mut:
	status_code int
	status_code_name string
	message string
}

pub struct Spaceship {
pub mut:
	host string
	port int

	routes []&Route
	default_responses []&DefaultResponse

	static_files []&StaticFile
	static_path string
	
	config SpaceshipConfig
}

pub struct Request {
pub mut:
	method string
	path string
	body string
	headers map[string]string
	start_time time.Time
	conn net.TcpConn
}

pub enum StaticFileType {
	css
	js
	image
	other
}

pub struct StaticFile {
pub mut:
	file_path string
	file_type StaticFileType
}

pub enum ErrorMessage {
	no_error
	not_found
	method_not_allowed
	internal_server_error
}

pub fn (mut sp Spaceship) static_folder(path string) ? {
	mut path_ := path
	for {
		if !path_.ends_with('/') {
			break
		}

		path_ = path_.trim_right('/')
	}

	if !os.is_dir(path_) {
		eprintln('[\x1b[31;1merror\x1b[0m] $path_ is not a directory or does not exist')
		exit(1)
	}

	mut files := []&StaticFile{}
	mut pfiles := &files

	os.walk(path_, fn [mut pfiles] (f string) {
		if f.ends_with('.css') {
			mut file := &StaticFile{file_path: f, file_type: StaticFileType.css}
			pfiles << file
		} else if f.ends_with('.js') {
			mut file := &StaticFile{file_path: f, file_type: StaticFileType.js}
			pfiles << file
		} else if f.ends_with('.png') {
			mut file := &StaticFile{file_path: f, file_type: StaticFileType.image}
			pfiles << file
		} else {
			mut file := &StaticFile{file_path: f, file_type: StaticFileType.other}
			pfiles << file
		}
	})

	sp.static_files = files
	sp.static_path = path_
}

fn get_path(str string) string {
	return str.split(' ')[1]
}

fn get_method(str string) string {
	return str.split(' ')[0]
}

fn get_body(str string) string {
	parts := str.split('\r\n\r\n')
	if parts.len > 1 {
		return parts[1]
	} else {
		return ''
	}
}

fn get_headers(strs []string) map[string]string {
	mut headers := map[string]string{}
	for str in strs {
		parts := str.split(':')
		if parts.len == 2 {
			headers[parts[0]] = parts[1]
		}
	}
	return headers
}

fn log_request(mut sp Spaceship, host string, status_code int, method string, path string, response_time string) {
	if !sp.config.show_favicon_request && path.contains('favicon.ico') {
		return
	} else {
		if status_code >= 200 && status_code < 300 {
			println('[\x1b[35;1mrequest\x1b[0m] $host - $method \x1b[32;1m$status_code\x1b[0m $path - $response_time')
		} else if status_code >= 300 && status_code < 400 {
			println('[\x1b[35;1mrequest\x1b[0m] $host - $method \x1b[33;1m$status_code\x1b[0m $path - $response_time')
		} else if status_code >= 400 && status_code < 500 {
			println('[\x1b[35;1mrequest\x1b[0m] $host - $method \x1b[33;1m$status_code\x1b[0m $path - $response_time')
		} else {
			println('[\x1b[35;1mrequest\x1b[0m] $host - $method \x1b[31;1m$status_code\x1b[0m $path - $response_time')
		}
	}
}

fn run_response(mut sp Spaceship, mut conn net.TcpConn, mut request Request, mut response Response) ? {
	if response.status_code == 0 {
		response.set_status_code(200)
	}

	mut resp := 'HTTP/1.1 $response.status_code $response.status_code_name\r\n'
	for key, value in response.headers {
		resp += '$key: $value\r\n'
	}

	for cookie in response.cookies {
		formated_cookie := response.format_cookie(cookie)
		resp += 'Set-Cookie: $formated_cookie\r\n'
	}

	resp += '\r\n'
	resp += response.body

	
	conn.write_string(resp) ?

	diff := time.since(request.start_time)

	if sp.config.verbose {
		log_request(mut sp, conn.peer_ip() ?, response.status_code, request.method, request.path, '$diff')
	}
}

fn (mut sp Spaceship) handle_connection(mut conn net.TcpConn) ? {
	mut message := ''
	for {
		mut line := conn.read_line()
		bytes := line.bytes()

		if bytes.len < 2 {
			break
		}

		if bytes[0] == `\r` && bytes[1] == `\n` {
			break
		}

		message += line
	}

	start := time.now()

	if message.len == 0 {
		conn.close() ?
		return
	}

	message_parts := message.split('\r\n')

	method := get_method(message_parts[0])
	path := get_path(message_parts[0])
	headers := get_headers(message_parts[1..])
	body := get_body(message)
	
	mut request := Request{method: method, path: path, body: body, headers: headers, start_time: start, conn: conn}
	mut response := new_response()

	mut error_message := ErrorMessage.no_error
	mut found := false
	for route in sp.routes {	
		if route.path == request.path {
			if method in route.methods {
				route.handler(mut request, mut response)
				found = true
				break
			} else if route.methods.len == 0 {
				route.handler(mut request, mut response)
				found = true
				break
			} else {
				error_message = ErrorMessage.method_not_allowed
				break
			} 
		}

		if sp.static_path != '' {
			sp.static_folder(sp.static_path) ?
		}

		for file in sp.static_files {
			static_path := file.file_path.substr(sp.static_path.len, file.file_path.len)

			if path == static_path {
				match file.file_type {
					.css {
						response.set_status_code(200)
						response.add_header('Content-Type', 'text/css')

						contents := os.read_file(file.file_path) or {
							eprintln('[\x1b[31;1merror\x1b[0m] $err')
							exit(1)
						}

						response.set_body(contents)
						found = true
						break
					}
					.js {
						response.set_status_code(200)
						response.add_header('Content-Type', 'text/javascript')

						contents := os.read_file(file.file_path) or {
							eprintln('[\x1b[31;1merror\x1b[0m] $err')
							exit(1)
						}

						response.set_body(contents)
						found = true
						break
					}
					.image {
						response.set_status_code(200)
						response.add_header('Content-Type', 'image/png')
						
						contents := os.read_file(file.file_path) or {
							eprintln('[\x1b[31;1merror\x1b[0m] $err')
							exit(1)
						}

						response.set_body(contents)
						found = true
						break
					}
					.other {
						response.set_status_code(200)
						response.add_header('Content-Type', 'text/plain')
						
						contents := os.read_file(file.file_path) or {
							eprintln('[\x1b[31;1merror\x1b[0m] $err')
							exit(1)
						}

						response.set_body(contents)
						found = true
						break
					}
				}
			}
		}
	}

	if !found && error_message != ErrorMessage.method_not_allowed {
		error_message = ErrorMessage.not_found
	}

	if !sp.config.show_server_header {
		response.remove_header('Server')
	}

	match error_message {
		.method_not_allowed {
			for dr in sp.default_responses {
				if dr.status_code == 405 {
					response.set_status_code(dr.status_code)
					response.set_body(dr.message)
					break
				}
			}

			run_response(mut sp, mut conn, mut request, mut response) ?
			conn.close() ?
		} 
		.not_found {
			for dr in sp.default_responses {
				if dr.status_code == 404 {
					response.set_status_code(dr.status_code)
					response.set_body(dr.message)
					break
				}
			}

			run_response(mut sp, mut conn, mut request, mut response) ?
			conn.close() ?
		}
		else {
			run_response(mut sp, mut conn, mut request, mut response) ?
			conn.close() ?
		}
	}
}	

pub fn new(host string, port int) Spaceship {
	mut default_responses := []&DefaultResponse{}
	default_responses << &DefaultResponse{
		status_code: 404,
		status_code_name: 'Not Found',
		message: 'Not Found',
	}

	default_responses << &DefaultResponse{
		status_code: 500,
		status_code_name: 'Internal Server Error',
		message: 'Internal Server Error',
	}

	default_responses << &DefaultResponse{
		status_code: 405,
		status_code_name: 'Method Not Allowed',
		message: 'Method Not Allowed',
	}

	return Spaceship{
		host: host, 
		port: port, 
		default_responses: default_responses,
		static_path: '',
		config: SpaceshipConfig {
			verbose: true
			show_favicon_request: true
			show_server_header: true
		}
	}
}

pub fn (mut sp Spaceship) listen() ? {
	mut ln := net.listen_tcp(net.AddrFamily.ip, '$sp.host:$sp.port') or {
		eprintln('[\x1b[31;1merror\x1b[0m] $err')
		return
	}

	if sp.config.verbose {
		print('\x1b[2J\x1b[1;1H')
		println('[\x1b[32;1mspaceship\x1b[0m] ready for take off 🚀 (http://$sp.host:$sp.port/)\n')
	}

	for {
		mut conn := ln.accept() or {
			eprintln('[\x1b[31;1merror\x1b[0m] $err')
			continue
		}

		go sp.handle_connection(mut conn)
	} 
}