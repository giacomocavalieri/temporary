# temporary

[![Package Version](https://img.shields.io/hexpm/v/temporary)](https://hex.pm/packages/temporary)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/temporary/)
![Supported targets](https://img.shields.io/badge/supports-all_targets-ffaff3)

🗂️ A package to work with temporary files and directories in Gleam!

## Installation

To add this package to your Gleam project:

```sh
gleam add temporary
```

## Usage

You can create temporary files and directories using the `temporary.create`
function. And you don't have to worry about cleaning up, any temporary file will
be deleted automatically once the function is over!

```gleam
import temporary
import simplifile

pub fn main() {
  use file <- temporary.create(temporary.file())
  let assert Ok(_) = simplifile.write("Hello, world!", to: file)
}
```

You can find the full documentation on [Hex!](https://hex.pm/packages/temporary)
