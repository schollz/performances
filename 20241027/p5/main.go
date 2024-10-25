package main

import (
	"fmt"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/hypebeast/go-osc/osc"
	log "github.com/schollz/logger"
)

var mutex sync.Mutex
var connections = make(map[*websocket.Conn]bool)
var supercollider *osc.Client

func main() {
	log.SetLevel("debug")

	supercollider = osc.NewClient("127.0.0.1", 7771)

	// go func() {
	// 	time.Sleep(2 * time.Second)
	// 	// open browser
	// 	exec.Command("open", "http://localhost:8098").Start()
	// }()

	go func() {
		addr := "127.0.0.1:8123"
		d := osc.NewStandardDispatcher()
		d.AddMsgHandler("/texty", func(msg *osc.Message) {
			mutex.Lock()
			for c := range connections {
				err := c.WriteJSON(struct {
					Text1 string `json:"text1"`
					Text2 string `json:"text2"`
					Text3 string `json:"text3"`
				}{
					msg.Arguments[0].(string),
					msg.Arguments[1].(string),
					msg.Arguments[2].(string),
				})
				if err != nil {
					log.Error(err)
				}
			}
			mutex.Unlock()
		})
		d.AddMsgHandler("/loopinfo", func(msg *osc.Message) {
			loopNum := msg.Arguments[0].(int32)
			x := msg.Arguments[1].(float32)
			y := msg.Arguments[2].(float32)
			db := msg.Arguments[3].(int32)
			mutex.Lock()
			for c := range connections {
				err := c.WriteJSON(struct {
					LoopNum int32   `json:"loop"`
					X       float32 `json:"x"`
					Y       float32 `json:"y"`
					DB      int32   `json:"db"`
				}{
					loopNum, x, y, db,
				})
				if err != nil {
					log.Error(err)
				}
			}
			mutex.Unlock()
		})
		d.AddMsgHandler("/note", func(msg *osc.Message) {
			mutex.Lock()
			for c := range connections {
				err := c.WriteJSON(struct {
					Note int32 `json:"n"`
				}{
					msg.Arguments[0].(int32),
				})
				if err != nil {
					log.Error(err)
				}
			}
			mutex.Unlock()
		})

		server := &osc.Server{
			Addr:       addr,
			Dispatcher: d,
		}
		server.ListenAndServe()
	}()

	port := 8098
	log.Infof("listening on :%d", port)
	http.HandleFunc("/", handler)
	http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
}

func handler(w http.ResponseWriter, r *http.Request) {
	t := time.Now().UTC()
	err := handle(w, r)
	if err != nil {
		log.Error(err)
	}
	log.Infof("%v %v %v %s\n", r.RemoteAddr, r.Method, r.URL.Path, time.Since(t))
}

func handle(w http.ResponseWriter, r *http.Request) (err error) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

	// very special paths
	if r.URL.Path == "/ws" {
		return handleWebsocket(w, r)
	} else if strings.HasPrefix(r.URL.Path, "/static/") {
		http.ServeFile(w, r, r.URL.Path[1:])
	} else {
		http.ServeFile(w, r, "index.html")
	}

	return
}

var wsupgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type Message struct {
	Action string `json:"action"`
	Number int32  `json:"number"`
	Index  int32  `json:"index"`
}

func handleWebsocket(w http.ResponseWriter, r *http.Request) (err error) {
	c, errUpgrade := wsupgrader.Upgrade(w, r, nil)
	if errUpgrade != nil {
		return errUpgrade
	}
	mutex.Lock()
	connections[c] = true
	mutex.Unlock()

	defer func() {
		mutex.Lock()
		delete(connections, c)
		mutex.Unlock()
		c.Close()
	}()

	for {
		var p Message
		err := c.ReadJSON(&p)
		if err != nil {
			log.Debug("read:", err)
			break
		}
		if p.Action == "slider" {
			log.Debugf("%d: %v", p.Index, p.Number)
			msg := osc.NewMessage("/slider")
			msg.Append(int32(p.Index))
			msg.Append(p.Number)
			supercollider.Send(msg)
		}
	}
	return
}
