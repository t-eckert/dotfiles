package main

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNormalize(t *testing.T) {
	cases := map[string]struct {
		text     string
		expected string
	}{
		"Shorter than 80 characters": {
			"This input is shorter than 80 characters",
			"This input is shorter than 80 characters",
		},
		"Greater than 80 characters": {
			"This input is longer than 80 characters, but does not have a word that needs to break at 80 characters.",
			"This input is longer than 80 characters, but does not have a word that needs to\nbreak at 80 characters.",
		},
		"Greater than 80 characters, with word at break": {
			"This input is longer than 80 characters, and has a word that needs to not be broken at 80 characters.",
			"This input is longer than 80 characters, and has a word that needs to not be\nbroken at 80 characters.",
		},
		"Very long input": {
			`Lorem ipsum dolor sit amet,
consectetur adipiscing elit. Nam cursus orci dolor, id feugiat metus facilisis nec. Proin efficitur, leo vitae fermentum
ornare, enim ligula
aliquet risus, in rhoncus erat magna vel nisl. Maecenas eu purus non orci
interdum consectetur nec eget massa.
Class aptent taciti sociosqu ad litora torquent per conubia
nostra, per inceptos himenaeos. Proin
sit amet nisi sagittis, varius metus ut, mattis felis. In placerat mi justo. Maecenas blandit, massa sit amet tristique eleifend, ex velit condimentum massa,
nec sollicitudin lacus
eros ac nibh. Interdum et malesuada fames ac ante ipsum
primis in faucibus. Pellentesque sed malesuada turpis. Proin eget est non
felis mattis sagittis condimentum ut lectus.`,
			`Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam cursus orci dolor,
id feugiat metus facilisis nec. Proin efficitur, leo vitae fermentum ornare,
enim ligula aliquet risus, in rhoncus erat magna vel nisl. Maecenas eu purus non
orci interdum consectetur nec eget massa. Class aptent taciti sociosqu ad litora
torquent per conubia nostra, per inceptos himenaeos. Proin sit amet nisi
sagittis, varius metus ut, mattis felis. In placerat mi justo. Maecenas blandit,
massa sit amet tristique eleifend, ex velit condimentum massa, nec sollicitudin
lacus eros ac nibh. Interdum et malesuada fames ac ante ipsum primis in
faucibus. Pellentesque sed malesuada turpis. Proin eget est non felis mattis
sagittis condimentum ut lectus.`,
		},
	}

	for name, tc := range cases {
		t.Run(name, func(t *testing.T) {
			actual := Normalize(tc.text, 80)
			require.Equal(t, tc.expected, actual)
		})
	}
}
