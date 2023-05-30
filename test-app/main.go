package main

import (
	"log"
	"net/http"
	"os"
	"strconv"
	"time"
)

// simple golang webserver that listens on /api/test, sleeps 200ms and returns status 200

var (
	counter = 0
)

func main() {
	sleepDelay, _ := strconv.Atoi(os.Args[1])

	http.HandleFunc("/api/test", func(w http.ResponseWriter, r *http.Request) {
		counter++
		log.Printf("request %d: received msg at, sleeping for %d ms..", counter, sleepDelay)
		time.Sleep(time.Duration(sleepDelay) * time.Millisecond)
		log.Printf("request %d: woke up.", counter)

		w.WriteHeader(http.StatusOK)
	})
	log.Printf("listening on port 8080.. with sleep delay of %d ms", sleepDelay)
	http.ListenAndServe(":8080", nil)
}
