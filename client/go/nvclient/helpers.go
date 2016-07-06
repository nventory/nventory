package nvclient

import (
	"bufio"
	"fmt"
)

func PromptUserConfirmation(message string, f *bufio.Reader) bool {
	fmt.Print(message)
	response, err := readLine(f)
	if err != nil {
		return false
	}
	r := []rune(response)
	if len(r) > 0 {
		if r[0] == 'y' || r[0] == 'Y' {
			return true
		} else {
			return false
		}
	}
	return PromptUserConfirmation(message, f)
}

func readLine(f *bufio.Reader) (string, error) {
	line, prefix, err := f.ReadLine()
	for prefix && err == nil {
		var l []byte
		l, prefix, err = f.ReadLine()
		line = append(line, l...)
	}
	return string(line), err
}
