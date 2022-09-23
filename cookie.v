module spaceship

pub struct Cookie {
pub mut:
	name string
	value string
	path string
	domain string
	expires string
	http_only bool
	secure bool
	max_age int
	same_site string
}

pub fn new_cookie() Cookie {
	return Cookie{}
}

pub fn (mut resp Response) add_cookie(cookie Cookie) {
	resp.cookies << &cookie
}

fn (mut resp Response) format_cookie(cookie Cookie) string {
	mut coo := '$cookie.name=$cookie.value; '
	if cookie.path != '' {
		coo += 'Path=$cookie.path; '
	}

	if cookie.domain != '' {
		coo += 'Domain=$cookie.domain; '
	}

	if cookie.expires != '' {
		coo += 'Expires=$cookie.expires; '
	}

	if cookie.http_only {
		coo += 'HttpOnly; '
	}

	if cookie.secure {
		coo += 'Secure; '
	}

	if cookie.max_age != 0 {
		coo += 'Max-Age=$cookie.max_age; '
	}

	if cookie.same_site != '' {
		coo += 'SameSite=$cookie.same_site; '
	}

	return coo
}