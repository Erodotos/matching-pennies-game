// Program to generate obscured bet

package main

import (
	"flag"
	"fmt"

	"github.com/ethereum/go-ethereum/crypto"
)

func main() {
	bet := flag.String("bet", "0", "Provide bet option, 0 or 1!")
	salt := flag.String("salt", "random", "Provide a random salt")
	flag.Parse()

	input := []byte(*bet + *salt)
	hash := crypto.Keccak256Hash(input)
	fmt.Println(hash)
}
