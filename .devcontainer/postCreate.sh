#!/bin/bash
echo "Setting up environment..."

# Initialize opam
opam init -y
opam switch create 4.14.0
eval $(opam env)
