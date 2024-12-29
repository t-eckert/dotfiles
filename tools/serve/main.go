package main

import (
	"flag"
	"fmt"
	"log"
	"net/http"
)

func main() {
	var port string
	flag.StringVar(&port, "port", "8080", "define what TCP port to bind to")
	flag.Parse()

	fs := http.FileServer(http.Dir("."))
	http.Handle("/", fs)

	addr := fmt.Sprintf(":%s", port)

	fmt.Printf("Serving current directory on HTTP port: %s\n", port)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatalf("Error starting server: %s\n", err)
	}
}
