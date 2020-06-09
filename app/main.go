package main

import (
	"flag"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"strings"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

var addr = flag.String("addr", ":8080", "http service address")

func wsEcho(w http.ResponseWriter, r *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	c, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Print("upgrade:", err)
		return
	}
	defer c.Close()
	for {
		mt, message, err := c.ReadMessage()
		if err != nil {
			break
		}
		err = c.WriteMessage(mt, message)
		if err != nil {
			break
		}
	}
}

func getIP(r *http.Request) string {
	forwarded := r.Header.Get("X-FORWARDED-FOR")
	if forwarded != "" {
		return forwarded
	}

	pieces := strings.Split(r.RemoteAddr, ":")
	return strings.Join(pieces[:len(pieces)-1], ":")
}

func home(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	requestIp := getIP(r)
	if requestIp == "" {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "500 - No request ip found")
	}

	homeTemplate.Execute(w, requestIp)
}

func health(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "ok")
}

func main() {
	flag.Parse()
	http.HandleFunc("/", home)
	http.HandleFunc("/health", health)
	http.HandleFunc("/ws", wsEcho)

	log.Printf("application listening on %s", *addr)

	err := http.ListenAndServe(*addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

var homeTemplate = template.Must(template.New("").Parse(`
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
</head>
<body>
<h1>Welcome</h1>
<h2>Your IP is: {{.}}</h2>
<p id="ws" style="display: none;">Websocket connection established</p>
<p id="ws-counter" style="display: none;"></p>
<script>  
let counter = 0;
let ws = new WebSocket("ws://" + location.host + "/ws");

ws.onmessage = function(e) {
    counter++;
    document.getElementById("ws").style.display = "block";
    document.getElementById("ws-counter").style.display = "block";
    document.getElementById("ws-counter").innerHTML = "Websocket message count: " + counter;
};

ws.onopen = function(e) {
  console.log("ws connection open")
  ws.send("connection established");
};

ws.onerror = function(error) {
  console.log("error", error.message)
};

setInterval(function(){
    ws.send("tick")
}, 2000);
</script>
</body>
</html>
`))