import log
import time

struct Worker {
	mut:
	n i64
	ch chan string
}

fn main() {
	log.info("spawn")

	mut n := 0

	mut wthreads := []thread{} // no documentation on thread type/struct
	mut workers := []Worker{}

	n++
	mut w1 := &Worker{ n: n }
	workers << w1
	wthreads << go worker(mut w1)

	n++
	mut w2 := &Worker{ n: n }
	workers << w2
	wthreads << go worker(mut w2)

	mut cw := ""
	for {
		log.info('\nmain thread ${n}')
		for w in workers {
			log.info('wt: $w.n')
			for {
				if w.ch.try_pop(mut cw) != .success { break }
				log.info('message: $w.n: $cw')
			}
		}
		//time.sleep(500_000_000)
		time.sleep(2000_000_000)
	}

}


fn worker(mut w Worker) {
	log.info('worker ${w.n}')

	for {
		ns := time.now().unix_time_nano()
		log.info('worker $w.n time: $ns')
		w.ch <- "msg: $ns"
		w.ch <- "message again $ns"
		time.sleep(300_000_000)
	}
}
