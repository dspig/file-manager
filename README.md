# MsFs

An in-memory file system implementation to satisfy a takehome coding exercise.

TODO: documentation of approach, including mermaid diagrams

## Installation

This repo uses Elixir 1.17.2. You can find install instructions [here](https://elixir-lang.org/install.html).

### Step 1: Setup Elixir

On Mac, it's easy to install using either Homebrew or asdf-vm.

With homebrew:

```bash
brew install elixir
```

Or with asdf:

These instructions are drawn from [Thinking Elixir](https://thinkingelixir.com/install-elixir-using-asdf/). It's a little difficult for me to validate these instructions since my system already has everything setup and I might have missed some steps.

1. Install [asdf](https://asdf-vm.com/guide/getting-started.html)

2. Install `asdf/erlang` plugin:

    ```bash
    asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
    ```

3. Install `asdf/elixir` plugin:

    ```bash
    asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
    ```

4. Run `asdf install`
5. Confirm elixir version with `elixir --version`

### Install dependencies

Once you've installed Elixir, next you'll need to install all the dependices with `mix deps.get`

## Running the code

Once you've install all the dependencies, you can launch the code using the "interactive elixir REPL", `iex`, like this:

```bash
iex -S mix
```

## Testing

Tests can be run with the command `mix test`.
