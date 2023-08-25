package main

import (
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"io/ioutil"
	"math"
	"math/rand"
	"net/http"
	"strings"
	"time"

	movingaverage "github.com/RobinUS2/golang-moving-average"
	"github.com/gorilla/websocket"
	"github.com/hypebeast/go-osc/osc"
	"github.com/pkg/browser"
	log "github.com/schollz/logger"
	"gonum.org/v1/gonum/stat"
)

var client *osc.Client

//go:embed static
var static embed.FS
var fsStatic http.Handler

var flagFrameRate, flagOSCPort, flagPort int
var flagOSCHost string
var flagOpen bool
var ma map[string][]*movingaverage.ConcurrentMovingAverage

func init() {
	ma = make(map[string][]*movingaverage.ConcurrentMovingAverage)
	ma["Left"] = make([]*movingaverage.ConcurrentMovingAverage, 3)
	ma["Right"] = make([]*movingaverage.ConcurrentMovingAverage, 3)
	for i := 0; i < 3; i++ {
		ma["Left"][i] = movingaverage.Concurrent(movingaverage.New(5))
		ma["Right"][i] = movingaverage.Concurrent(movingaverage.New(5))
	}
	flag.IntVar(&flagFrameRate, "reduce-fps", 70, "reduce frame rate (default 70% of max), [0-100]")
	flag.IntVar(&flagPort, "video server port", 8085, "port for website")
	flag.IntVar(&flagOSCPort, "osc port", 57120, "port to send osc messages")
	flag.BoolVar(&flagOpen, "open", false, "don't open browser")
	flag.StringVar(&flagOSCHost, "osc host", "localhost", "host to send osc messages")
}

func main() {
	flag.Parse()
	client = osc.NewClient(flagOSCHost, flagOSCPort)

	fsRoot, _ := fs.Sub(static, "static")
	fsStatic = http.FileServer(http.FS(fsRoot))
	log.SetLevel("debug")
	log.Infof("listening on :%d", flagPort)
	if flagOpen {
		browser.OpenURL(fmt.Sprintf("http://localhost:%d/", flagPort))
	}
	http.HandleFunc("/", handler)
	http.ListenAndServe(fmt.Sprintf(":%d", flagPort), nil)
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
	} else {
		if strings.HasSuffix(r.URL.Path, ".js") {
			w.Header().Set("Content-Type", "text/javascript")
		}
		fsStatic.ServeHTTP(w, r)
		return
		var b []byte
		if r.URL.Path == "/" {
			log.Debug("loading index")
			b, err = ioutil.ReadFile("static/hands.html")
			if err != nil {
				return
			}
		} else {
			b, err = ioutil.ReadFile("static" + r.URL.Path)
			if err != nil {
				return
			}
		}
		w.Write(b)
	}

	return
}

type HandData struct {
	MultiHandLandmarks [][]struct {
		X float64 `json:"x"`
		Y float64 `json:"y"`
		Z float64 `json:"z"`
	} `json:"multiHandLandmarks"`
	MultiHandedness []struct {
		Index int     `json:"index"`
		Score float64 `json:"score"`
		Label string  `json:"label"`
	} `json:"multiHandedness"`
}

var wsupgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func handleWebsocket(w http.ResponseWriter, r *http.Request) (err error) {
	defer func() {
		if r := recover(); r != nil {
			log.Debug(r)
		}
	}()
	c, errUpgrade := wsupgrader.Upgrade(w, r, nil)
	if errUpgrade != nil {
		return errUpgrade
	}
	defer c.Close()

	for {
		var p HandData
		err := c.ReadJSON(&p)
		if err != nil {
			log.Debug("read:", err)
			break
		} else {
			go processScore(p)
		}
	}
	return
}

func maxDistance(numbers []float64) float64 {
	mmax := -1000000.0
	mmin := 10000000.0
	for _, n := range numbers {
		if n < mmin {
			mmin = n
		}
		if n > mmax {
			mmax = n
		}
	}
	log.Debug(mmin, mmax)
	return mmax - mmin
}

func multiply(ds []float64, x float64) []float64 {
	for i, v := range ds {
		ds[i] = v * x
	}
	return ds
}

func normalize(ds []float64) []float64 {
	return multiply(ds, 1.0/maxDistance(ds))
}

func processScore(p HandData) {
	// reduce frame rate a little bit
	if rand.Float64() > float64(flagFrameRate)/100.0 {
		return
	}
	for i, hand := range p.MultiHandLandmarks {
		log.Debugf("len(hand)=%d", len(hand))
		xs := make([]float64, len(hand))
		ys := make([]float64, len(hand))
		zs := make([]float64, len(hand))
		ws := make([]float64, len(hand))

		for j, coord := range hand {
			xs[j] = coord.X
			ys[j] = coord.Y
			zs[j] = coord.Z
			ws[j] = 1.0
		}
		xsn := multiply(xs, 1)
		ysn := multiply(ys, 1.0)
		log.Debugf("maxDistance(ys): %f", maxDistance(ys))
		log.Debugf("x: %+v", xsn)
		log.Debugf("y: %+v", ysn)
		// log.Debugf("y: %+v", ys, maxDistance(ys))
		// log.Debugf("z: %+v", zs, maxDistance(zs))

		meanX, stdX := stat.MeanStdDev(xsn, ws)
		meanY, stdY := stat.MeanStdDev(ysn, ws)
		meanZ, stdZ := stat.MeanStdDev(zs, ws)
		_ = meanZ
		_ = stdZ
		_ = stdX
		_ = stdY
		spread := dist(hand[0].X, hand[0].Y, hand[12].X, hand[12].Y) / dist(hand[0].X, hand[0].Y, hand[17].X, hand[17].Y)
		spread = spread - 0.4
		spread = spread / 1.9
		if spread < 0 {
			spread = 0
		}
		if spread > 1 {
			spread = 1
		}
		ma[p.MultiHandedness[i].Label][0].Add(meanX)
		ma[p.MultiHandedness[i].Label][1].Add(meanY)
		ma[p.MultiHandedness[i].Label][2].Add(meanZ)

		meanX = ma[p.MultiHandedness[i].Label][0].Avg()
		meanY = ma[p.MultiHandedness[i].Label][1].Avg()
		spread = ma[p.MultiHandedness[i].Label][2].Avg()
		log.Debugf("%s: (%2.2f, %2.2f, %2.2f)", p.MultiHandedness[i].Label, meanX, meanY, meanZ)
		// msg := osc.NewMessage("/" + strings.ToLower(p.MultiHandedness[i].Label))
		// msg.Append(meanX)
		// msg.Append(meanY)
		// msg.Append(spread)
		// client.Send(msg)
	}
}

func dist(x1, y1, x2, y2 float64) float64 {
	return math.Sqrt(math.Pow(x1-x2, 2) + math.Pow(y1-y2, 2))
}
