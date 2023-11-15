module main

// Note: This program, requires that the shared library was already compiled.
// To do so, run `v -d no_backtrace -o library -shared modules/library/library.v`
// before running this program.
import os
import time
import dl
import dl.loader

type FNAdder = fn (int, int) int

fn main() {
	library_file_path := os.join_path(os.dir(@FILE), dl.get_libname('library'))

	//mut lines := []

	for {
		time.sleep(2 * time.second)
		lines := os.read_lines('lib.id') or { [''] }
		id := lines[0] or { '' }

		// blue green with diferent ports for proxy_pass and nginx -s reload is a better option
		mut dl_loader := loader.get_or_create_dynamic_lib_loader(
			key: 'library'
			env_path: os.dir(@FILE)
			paths: [library_file_path + '.' + id]
		)!

		f2 := FNAdder(dl_loader.get_sym('add_1')!)
		eprintln('f2: ${ptr_str(f2)}')
		res2 := f2(1, 2)
		eprintln('res2: ${res2}')

		dl_loader.unregister()
	}

	for {
		time.sleep(2 * time.second)
		handle := dl.open_opt(library_file_path, dl.rtld_now)!
		eprintln('handle: ${ptr_str(handle)}')
		f := FNAdder(dl.sym_opt(handle, 'add_1')!)
		eprintln('f: ${ptr_str(f)}')
		res := f(1, 2)
		eprintln('res: ${res}')
		dl.close(handle)
	}
}
