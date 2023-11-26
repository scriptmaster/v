import os
import os.cmdline
import net
// import encoding.base64
import encoding.base32
import log

fn main() {
	println('Usage: net_udp_server_and_client [-l] [-p 5000]')
	println('     -l      - act as a server and listen')
	println('     -c      - act as a client and send packets')
	println('     -p XXXX - custom port number')
	println('------------------------------------------')

	is_server := '-l' in os.args
	is_client := '-c' in os.args

	port := cmdline.option(os.args, '-p', '40003').int()
	mut buf := []u8{len: 100}

	if is_server {
		println('UDP echo server, listening for udp packets on port: ${port}')
		mut c := net.listen_udp('0.0.0.0:${port}')!

		for {
			read, addr := c.read(mut buf) or { continue }
			println('received ${read} bytes from ${addr}')
			c.write_to(addr, buf[..read]) or {
				println('Server: connection dropped')
				continue
			}
		}
	} else if is_client {
		println('UDP client, sending packets to port: ${port}.\nType `exit` to exit.')
		//mut c := net.dial_udp('127.0.0.1:${port}')!
		mut c := net.dial_udp('s.multicraft.world:${port}')!
		for {
			mut line := os.input('client > ')
			match line {
				'' {
					line = '\n'
				}
				'exit' {
					println('goodbye.')
					exit(0)
				}
				else {}
			}
			c.write_string(line)!
			read, _ := c.read(mut buf)!
			println('server : ' + buf[0..read].bytestr())
		}
	} else {
		chatterbox() or {
			println('chatterbox session completed')
		}
	}
}

fn chatterbox()! {
	println('Chatterbox');

	mut l := log.Log{}
	l.set_level(.info)

	// Make a new file called info.log in the current folder
	l.set_full_logpath('./logs/chatterbox.log')
	//l.log_to_console_too()

	lport := 40003
	mut listener := net.listen_udp('127.0.0.1:${lport}') or {
		println('Could not start the listener')
		return
	}

	server := "s.multicraft.world"
	sport := 40003
	//mut c := net.dial_udp('127.0.0.1:${40003}')!
	mut sender := net.dial_udp('${server}:${sport}') or {
		println('Could not connect to sender')
		return
	}

	mut buf := []u8{len: 1000}
	//mut cbuf := []u8{len: 1000}

	// sender.write(base64.decode("T0V0AwAAAAP/3AEAAA==")) or {
	// 	println('Could not write to sender')
	// 	return
	// }

	// read1, _ := sender.read(mut buf) or {
	// 	println('Error reading from sender')
	// 	return
	// }
	// println('remote-server: ${read1}')
	// println('remote-server: ${base64.encode(buf[..read1])}')
	// // // // // ...
	//mut s := []u8{len: 1000}
	mut str := ''
	//mut bstr := ''

	for {
		//read, addr := s.read(mut buf) or { (0, '') }
		read, addr := listener.read(mut buf) or { 0, &net.Addr{} }
		if read > 0 {
			//println('received ${read} bytes from ${addr}')
			//println('received: ' + base64.encode(buf[..read]))
			//println('received: ' + buf[..read].bytestr())

			str = buf[..read].bytestr()
			if read > 20 {
				//println(base32.encode_to_string(buf[..read]))
				//l.info('read:'+base32.encode_to_string(buf[..read]))
				// 	l.info('read: ${read}:' + str)
				// 	//l.info('r: ${read}:' + str[9..])
				// 	//65:OEt4r��2siri can u translate this
			}

			if str.contains('s\0i\0r\0i\0') {
				println('siri: ${read}:' + str)
				//l.info('siri: ${read}:' + str)
				// bstr = base64.encode(buf[..read])
				// l.info('siri: ' + bstr)
				// l.info('encoded:'+(buf[..read]))
			}

			sender.write(buf[..read]) or {
				//sender.write_to(addr, buf[..read]) or {
				println('connection dropped')
				// continue
			}

			// sender.write_to(addr, buf[..read]) or {
			// 	println('connection dropped')
			// 	// continue
			// }
		} else {
			println("Nothing sent by client")
		}

		// for {
			sread, _ := sender.read(mut buf) or {
				println('Error reading from sender')
				continue
			}

			// if sread == 0 { break }

			//println('remote-server: ${sread}' + buf[0..sread].bytestr())
			//println('remote-server: ${sread}')
			//println('remote-server: ${base64.encode(buf[..sread])}')

			listener.write_to(addr, buf[..sread]) or {
				// listener.write(buf[..sread]) or {
				println('Could not write reply to client ${sread}')
			}
		// }

		// //
		//mut line := os.input('continue?')
		//println(line)

		// // // // 
		/*
			c.write_string(line)!
			read, _ := c.read(mut buf)!
			println('server : ' + buf[0..read].bytestr())
		*/
	}

}
