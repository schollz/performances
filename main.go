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
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	movingaverage "github.com/RobinUS2/golang-moving-average"
	RF "github.com/fxsjy/RF.go/RF"
	"github.com/gorilla/websocket"
	"github.com/hypebeast/go-osc/osc"
	"github.com/pkg/browser"
	log "github.com/schollz/logger"
	"gonum.org/v1/gonum/stat"
)

var client *osc.Client
var mutex sync.Mutex

//go:embed static
var static embed.FS
var fsStatic http.Handler
var forest [2]*RF.Forest
var classifications [][]string
var classifyCurrent []string

var flagLearn string
var flagFrameRate, flagOSCPort, flagPort int
var flagOSCHost string
var flagOpen, flagBuildRF bool
var ma map[string][]*movingaverage.ConcurrentMovingAverage
var lrName map[string]int

func init() {
	lrName = make(map[string]int)
	lrName["left"] = 0
	lrName["right"] = 1

	classifications = make([][]string, 2)
	classifications[0] = make([]string, 3)
	classifications[1] = make([]string, 3)
	classifyCurrent = make([]string, 2)

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
	flag.BoolVar(&flagBuildRF, "build", false, "don't build")
	flag.StringVar(&flagOSCHost, "osc host", "127.0.0.1", "host to send osc messages")
	flag.StringVar(&flagLearn, "learn", "", "gesture learning file")
}

func main() {
	flag.Parse()
	client = osc.NewClient("127.0.0.1", 57120)

	if flagBuildRF {
		for i := 0; i < 2; i++ {
			buildRandomForests(i)
		}
	}

	for i := 0; i < 2; i++ {
		forest[i] = RF.LoadForest(fmt.Sprintf("%d.bin", i))
	}

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
			go processScore(p, c)
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

func distances(xs []float64, ys []float64) (d []float64) {
	if len(xs) != len(ys) {
		return
	}
	d = make([]float64, len(xs)*(len(xs)-1)/2)
	k := 0
	for i, x1 := range xs {
		for j, x2 := range xs {
			if j <= i {
				continue
			}
			y1 := ys[i]
			y2 := ys[j]
			d[k] = math.Sqrt(math.Pow(x1-x2, 2) + math.Pow(y1-y2, 2))
			k++
		}
	}
	return
}

func buildRandomForests(hand int) {
	start := time.Now()
	f, _ := os.Open(fmt.Sprintf("%d.learn", hand))
	defer f.Close()
	content, _ := ioutil.ReadAll(f)
	s_content := string(content)
	lines := strings.Split(s_content, "\n")

	// set up variables for random forest
	inputs := make([][]interface{}, 0)
	targets := make([]string, 0)
	for _, line := range lines {
		line = strings.TrimRight(line, "\r\n")
		if len(line) == 0 {
			continue
		}
		tup := strings.Split(line, ",")
		pattern := tup[:len(tup)-1]
		target := tup[len(tup)-1]
		X := make([]interface{}, 0)
		for _, x := range pattern {
			f_x, _ := strconv.ParseFloat(x, 64)
			X = append(X, f_x)
		}
		inputs = append(inputs, X)

		targets = append(targets, target)
	}
	train_inputs := make([][]interface{}, 0)
	train_targets := make([]string, 0)

	test_inputs := make([][]interface{}, 0)
	test_targets := make([]string, 0)

	for i, x := range inputs {
		if i%3 == 0 {
			test_inputs = append(test_inputs, x)
		} else {
			train_inputs = append(train_inputs, x)
		}
	}

	for i, y := range targets {
		if i%3 == 0 {
			test_targets = append(test_targets, y)
		} else {
			train_targets = append(train_targets, y)
		}
	}

	forest := RF.DefaultForest(inputs, targets, 150) //100 trees

	RF.DumpForest(forest, fmt.Sprintf("%d.bin", hand))

	forest = RF.LoadForest(fmt.Sprintf("%d.bin", hand))

	err_count := 0.0
	for i := 0; i < len(test_inputs); i++ {
		output := forest.Predicate(test_inputs[i])
		expect := test_targets[i]
		fmt.Println(output, expect)
		if output != expect {
			err_count += 1
		}
	}
	fmt.Println("success rate:", 1.0-err_count/float64(len(test_inputs)))

	fmt.Println(time.Since(start))
}

type Message struct {
	Kind string `json:"kind"`
	Ele  string `json:"ele"`
	Data string `json:"data"`
}

// https://developers.google.com/static/mediapipe/images/solutions/hand-landmarks.png
func processScore(p HandData, c *websocket.Conn) {
	// reduce frame rate a little bit
	if rand.Float64() > float64(flagFrameRate)/100.0 {
		return
	}
	for i, hand := range p.MultiHandLandmarks {
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
		handedness := strings.ToLower(p.MultiHandedness[i].Label)
		points := []int{0, 4, 8, 9, 12, 16, 20}
		xgood := make([]float64, len(points))
		ygood := make([]float64, len(points))
		for k, v := range points {
			if len(xs) < v {
				return
			}
			if len(xs) == 0 {
				return
			}
			xgood[k] = xs[v]
			ygood[k] = ys[v]
		}
		dgood := distances(xgood, ygood)
		if flagLearn != "" {
			learnFileName := fmt.Sprintf("%d.learn", lrName[handedness])
			mutex.Lock()

			file, err := os.OpenFile(learnFileName, os.O_APPEND|os.O_WRONLY, 0644)
			if err != nil {
				log.Error(err)
				mutex.Unlock()
				continue
			}
			for _, v := range dgood {
				fmt.Fprintf(file, "%f,", v)
			}
			fmt.Fprintf(file, "%s\n", flagLearn)
			file.Close()
			log.Debugf("learning %s", handedness)
			mutex.Unlock()
			continue
		}
		// predict hand formation
		test_inputs := make([]interface{}, 0)
		for _, v := range dgood {
			test_inputs = append(test_inputs, v)
		}
		output := forest[lrName[handedness]].Predicate(test_inputs)
		classifications[lrName[handedness]][2] = classifications[lrName[handedness]][1]
		classifications[lrName[handedness]][1] = classifications[lrName[handedness]][0]
		classifications[lrName[handedness]][0] = output
		log.Debugf("%s prediction: %s", handedness, output)

		meanX, _ := stat.MeanStdDev(xs, ws)
		meanY, _ := stat.MeanStdDev(ys, ws)
		ma[p.MultiHandedness[i].Label][0].Add(meanX)
		ma[p.MultiHandedness[i].Label][1].Add(meanY)

		meanX = ma[p.MultiHandedness[i].Label][0].Avg()
		meanY = 1.0 - ma[p.MultiHandedness[i].Label][1].Avg()
		// log.Debugf("%s: (%2.2f, %2.2f, %2.2f)", p.MultiHandedness[i].Label, meanX, meanY, meanZ)

		if classifications[lrName[handedness]][0] == classifications[lrName[handedness]][1] && classifications[lrName[handedness]][0] == classifications[lrName[handedness]][2] {
			classifyCurrent[lrName[handedness]] = output
		}

		if classifyCurrent[lrName[handedness]] != "" {
			mutex.Lock()
			c.WriteJSON(Message{
				"updateElement",
				handedness,
				fmt.Sprintf("%s [%2.2f,%2.2f]", classifyCurrent[lrName[handedness]], meanX, meanY),
			})
			log.Debug("sending osc message", meanX, meanY)
			msg := osc.NewMessage("/conductor")
			msg.Append(handedness)
			msg.Append(classifyCurrent[lrName[handedness]])
			msg.Append(meanX)
			msg.Append(meanY)
			cErr := client.Send(msg)
			if cErr != nil {
				log.Error(cErr)
			}
			mutex.Unlock()
		}

	}
}

func dist(x1, y1, x2, y2 float64) float64 {
	return math.Sqrt(math.Pow(x1-x2, 2) + math.Pow(y1-y2, 2))
}
