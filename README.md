# Spaceship

## Installation

```bash
v up
v install cookieforpres.spaceship
```

## Example

```v
module main

import cookieforpres.spaceship

fn handler(mut req spaceship.Request, mut res spaceship.Response) {
    res.set_body('Welcome to Spaceship 🚀. Get ready for blast off!')
}

fn main() {
    mut sp := spaceship.new('0.0.0.0', 8080)

    mut route := spaceship.new_route('/', ['GET', 'POST'], handler)
    sp.add_route(route)

    sp.listen() or { panic(err) }
}
```

## Upcoming Features / Already Implemented

* [X] sending files (e.g. images, html file, json file, etc.)
* [X] having a static folder for css and js files
* [ ] middleware

if you have any suggestions or want to contribute, please feel free to open an issue or make a pull request on [GitHub](https://github.com/cookieforpres/spaceship)
