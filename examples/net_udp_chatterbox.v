import time
import log
import net
import encoding.hex
// import encoding.base64
// import encoding.base32
import arrays

struct MsgAndAddr {
	msg string
	addr net.Addr
}

struct MsgChannel {
mut:
	ch chan MsgAndAddr
	conn net.UdpConn
	//n i64
}

struct ClientUpstream {
mut:
	client net.Addr
	upstream net.UdpConn
	pr_id [2]u8
	seq_inc [2]u8
}

// 0x4f457403
const minetest_protocol = hex.decode('4f457403') or { []u8{} }

fn main() {
	run_tests()
	chatterbox_v2()
}

fn run_tests() {
	println( s_to_wide_u8("ChatterBox").hex() )
	println( s_to_wide_u8("ChatterBox").bytestr() )
}

fn s_to_wide_s(s string) string { return s_to_wide_u8(s).bytestr() }

fn s_to_wide_u8(s string) []u8 {
	mut ns := []u8{cap: 2*s.len}
	for i:=0; i<s.len; i++ {
		ns << s[i]
		ns << 0
	}
	return ns
}

fn chatterbox_v2() {
	println('Chatterbox v2');

	mut l := log.Log{}
	l.set_level(.info)
	l.set_full_logpath('./logs/chatterbox.log')
	// l.log_to_console_too()

	// log.set_level(.info)
	log.set_logger(l) 
	// log.set_full_logpath('./logs/chatterbox.log')

	mut channels := []MsgChannel{}
	mut threads := []thread{} // no documentation on thread type/struct

	// spawn: listener
	mut lc := &MsgChannel{}
	lc.conn = create_listener() or {
		println('Could not start the listener')
		return
	}

	channels << lc
	threads << go client(mut lc)

	server_started := time.now()
	log.info("Server started on: $server_started" )

	for {
		time.sleep(60_000_000_000)
		println("Server up for: ${time.now() - server_started}" )
	}

}


fn create_listener()!&net.UdpConn {
	lport := 40003
	mut lnr := net.listen_udp('127.0.0.1:${lport}')!
	return lnr
}

fn client(mut m MsgChannel) {
	mut buf := []u8{len: 1000}
	mut s := ''

	mut str_addrs := []string{}
	mut addrs := []net.Addr{}
	mut upstreams := map[string]ClientUpstream

	mut first_n_msgs := 200

	for {
		//read, addr := s.read(mut buf) or { (0, '') }
		read, addr := m.conn.read(mut buf) or { 0, &net.Addr{} }
		if read > 5 {
			str_addr := addr.str()
			if !str_addrs.contains(str_addr) {
				str_addrs << str_addr
				addrs << addr
				println("New Client: $str_addr, creating upstream")

				mut up := create_upstream(addr) or {
					println("Cannot create upstream for $addr")
					&net.UdpConn{}
				}
				mut cu := &ClientUpstream{
					client: addr,
					upstream: up
				}
				// mut conn := m.conn
				upstreams[str_addr] = cu
				// now start write back to client.addr from upstream via m.conn
				go upstream(mut m, mut cu)
			}
			s = buf[..read].bytestr()
			// 
			if first_n_msgs > 0 {
				first_n_msgs--
				//println("clnt: ${buf[4..20]}")
			}
			// ... 
			if str_addr in upstreams {
				// https://github.com/minetest/minetest/blob/master/doc/protocol.txt
				// 0x 4f 45 74 03 // pr_id // 
				// if buf[..4].hex() == minetest_protocol || s.contains( s_to_wide_s('hi')  ) {
				if s.contains( s_to_wide_s('/m ChatterBox')  ) {
					// if s.contains( s_to_wide_s('>>')  ) {
					//log.info("client: $s")
					println("client: $s")
					println("client::bytes: ${s.bytes()}")
					//println("client::hex: ${hex.decode(s)}")
					// you could do translations here before sending to upstream
					// } else if upstreams[str_addr].pr_id[1] == 0 {
					// 	println("Setting pr_id: ${buf[4..6]}")
					// 	upstreams[str_addr].pr_id[0] = u8(buf[4])
					// 	upstreams[str_addr].pr_id[1] = u8(buf[5])
					// 	println('pr_id: ${upstreams[str_addr].pr_id}')
					// 	println("for pr_id: ${buf[..10]}")

					msg := 'hi'
					wide_msg := s_to_wide_u8(msg)
					b1 := arrays.concat(buf[..14], ...[u8(msg.len), u8(0)])
					b2 := arrays.concat(b1, ...wide_msg[..wide_msg.len])

					println("b2: $b2")
					upstreams[str_addr].upstream.write(b2) or {
						log.info("upstreams could not be written (client: $str_addr)")
					}
				} else {
					//log.info("client $str_addr sent: $read")
					upstreams[str_addr].upstream.write(buf[..read]) or {
						log.info("upstreams could not be written (client: $str_addr)")
					}
				}
			} else {
				log.info("uh oh.. no upstream for $str_addr")
			}
		}
	}
	// ...
}



fn create_upstream(client net.Addr)!&net.UdpConn {
	server := "s.multicraft.world"
	sport := 40003

	mut sender := net.dial_udp('${server}:${sport}')!

	return sender
}

fn upstream(mut m MsgChannel, mut cu ClientUpstream) {
	mut buf := []u8{len: 1000}
	mut s := ''

	mut first_n_msgs := 200

	for {
		sread, _ := cu.upstream.read(mut buf) or {
			println('Error reading from upstream')
			continue
		}

		if sread > 5 {
			if first_n_msgs > 0 {
				first_n_msgs--
				// println("server: ${buf[..100]}")
				//println("srvr: ${buf[4..20]}")
			}
			// println("srvr: ${buf[4..11]}")
			if cu.pr_id[1] == 0 {
				if buf[5] == 1 && buf[4] == 0 {
					cu.pr_id[0] = u8(buf[12])
					cu.pr_id[1] = u8(buf[13])
				} else {
					cu.pr_id[0] = u8(buf[4])
					cu.pr_id[1] = u8(buf[5])
				}
				println('pr_id: ${cu.pr_id}')
				println('buf[..6]: ${buf[..6]}')
			}
			//log.info("Server replied with $sread bytes")
			//println("Server replied with ")
			m.conn.write_to(cu.client, buf[..sread]) or {
				println('Could not write reply to client ${sread}')
			}
			s = buf[..sread].bytestr()
			// if s.contains('C\0h\0a\0t\0t\0e\0r\0B\0o\0x\0') {
			if s.contains(s_to_wide_s("ChatterBox")) {
				//println("Server: ChatterBox::: s:$s")
				//println("ChatterBox::$sread: b:${buf[..sread]}")
				//has joined the server
			}
			if s.contains(s_to_wide_s('chat_anticurse')) {
				//if s.contains('h\0a\0s\0 \0j\0o\0i\0n\0e\0d\0 \0t\0h\0e\0 \0s\0e\0r\0v\0e\0r\0') {
				//println("chat_anticurse ::: s:$s")
				//println("chat_anticurse ::$sread: b:${buf[..sread]}")
				// println("s:${base32.encode(s.bytes())}")
				//has joined the server
			}
			if s.contains( s_to_wide_s('has joined the server') ) {
				// if s.contains('h\0a\0s\0 \0j\0o\0i\0n\0e\0d\0 \0t\0h\0e\0 \0s\0e\0r\0v\0e\0r\0') {
				//println("=> joined the server ::: s:$s")
				id := s.all_after_first('@').all_before_last('@').all_after_last(')')
				println("Welcome back: ${id}")
				println("buf[..10]: ${buf[..10]}")

				if id != '=> ' && id != 'ChatterBox'{
					snd := chat_msg(mut cu, "Welcome back $id :)")
					println("snd: ${snd[..20]}")
					cu.upstream.write( snd ) or {
						log.info("welcome back message could not be sent: $snd")
					}

					// println("=> joined the server ::$sread: b:${buf[..sread]}")
					// println("s:${base32.encode(s.bytes())}")
					//has joined the server
				}
			}
		}
	}
}




// fn chat_pfx() []u8 {
// 	mut enc := []u8{cap: 5}
// 	for n in [79, 69, 116, 3] {
// 		enc << u8(n)
// 	}
// 	return enc
// }

fn chat_msg(mut cu ClientUpstream, s string) []u8 {
	mut msg := []u8{cap: ((2*s.len)+16)}
	// mut pfx := [79, 69, 116, 3, 87, 197, 0, 3, 255, 236, 1, 0, 50, 0, s.len, 0]
	// mut pfx := [79, 69, 116, 3, 88, 197, 0, 3, 255, 236, 1, 0, 50, 0, s.len, 0]
	// pr_id := 89

	// a := 55
	// b := 13 // or 9 or 12
	println("chat_msg: ${cu.pr_id}")

	cu.seq_inc[1]++
	mut pfx := [79, 69, 116, 3, cu.pr_id[0], cu.pr_id[1], 0, 3, cu.seq_inc[0], cu.seq_inc[1], 1, 0, 50, 0, s.len, 0]
	for n in pfx {
		msg << u8(n)
	}
	for i:=0; i<s.len; i++ {
		msg << s[i]
		msg << 0
	}
	return msg
}
