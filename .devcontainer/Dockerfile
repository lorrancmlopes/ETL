# Base image with VS Code setup
FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu-22.04

# Install dependencies for OCaml
RUN apt-get update && apt-get install -y \
    opam \
    m4 \
    pkg-config \
    git \
    curl \
    build-essential && \
    opam init -y && \
    eval $(opam env) && \
    opam switch create 4.14.0 && \
    opam install -y dune utop ocaml-lsp-server

USER vscode


#  RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh -s -- -y && \
#      ~/.ghcup/bin/ghcup install ghc && \
#      ~/.ghcup/bin/ghcup install cabal && \
#      ~/.ghcup/bin/ghcup install stack && \
     #~/.ghcup/bin/ghcup set ghc default

     
#     cabal update && \
#    cabal install hlint stylish-haskell

# Add paths for GHCup and opam
#ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:/root/.local/bin:$PATH"
#RUN ls -l ./
COPY postCreate.sh /home/vscode/postCreate.sh
USER root
RUN chmod +x /home/vscode/postCreate.sh