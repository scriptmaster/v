import log
import time

fn main() {
	log.info("spawn")

	mut n := 0

	n++
	go worker(n)
	n++
	go worker(n)

	for {
		n++
		spawn worker(n)
		log.info('main thread ${n}')
		//time.sleep(500_000_000)
		time.sleep(1000_000)
	}
}

fn worker(num int) {
	log.info('worker ${num}')

	for {
		//log.info('worker $num time: ${time.now().unix_time_nano()}')
		time.sleep(1000_000_000)
	}
}
