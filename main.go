package main

import (
	"context"
	"log"
	"os"
	"strings"

	daprd "github.com/dapr/go-sdk/server/grpc"
)

var (
	logger      = log.New(os.Stdout, "", 0)
	servicePort = getEnvVar("PORT", "50001")
)

func main() {
	// create serving server
	server, err := daprd.NewServer(servicePort)
	if err != nil {
		log.Fatalf("failed to start the server: %v", err)
	}

	// add handler to it a handler
	server.AddInvocationHandler("echo", echoHandler)

	// start the server to handle incoming events
	if err := server.Start(); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func echoHandler(ctx context.Context, contentTypeIn string, dataIn []byte) (contentTypeOut string, dataOut []byte) {
	logger.Printf("received invocation (content type:%s sie:%d)", contentTypeIn, len(dataIn))

	// TODO: implement handling logic here

	contentTypeOut = contentTypeIn
	dataOut = dataIn

	return
}

func getEnvVar(key, fallbackValue string) string {
	if val, ok := os.LookupEnv(key); ok {
		return strings.TrimSpace(val)
	}
	return fallbackValue
}
