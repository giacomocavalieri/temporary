import exception
import filepath
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import simplifile
import temporary

import cell

pub fn main() {
  gleeunit.main()
}

pub fn create_performs_cleanup_test() {
  let assert Ok(file) = temporary.create(temporary.file(), fn(file) { file })
  simplifile.is_file(file) |> should.equal(Ok(False))
}

pub fn create_performs_cleanup_directory_test() {
  let assert Ok(file) =
    temporary.create(temporary.directory(), fn(file) { file })
  simplifile.is_directory(file) |> should.equal(Ok(False))
}

pub fn create_performs_cleanup_even_after_panic_test() {
  let cell = cell.new()

  let assert Error(_) =
    exception.rescue(fn() {
      use file <- temporary.create(temporary.file())
      cell.set(cell, file)
      panic
    })

  let assert Ok(file) = cell.get(cell)
  simplifile.is_file(file) |> should.equal(Ok(False))
}

pub fn the_file_is_created_test() {
  use file <- temporary.create(temporary.file())
  simplifile.is_file(file) |> should.equal(Ok(True))
  simplifile.read(file) |> should.equal(Ok(""))
  file
}

pub fn the_directory_is_created_test() {
  use dir <- temporary.create(temporary.directory())
  simplifile.is_directory(dir) |> should.equal(Ok(True))
  simplifile.read_directory(dir) |> should.equal(Ok([]))
}

pub fn suffix_is_added_test() {
  let file = temporary.file() |> temporary.with_suffix("wibble")
  use file <- temporary.create(file)
  string.ends_with(file, "wibble") |> should.be_true
}

pub fn prefix_is_added_test() {
  let file = temporary.file() |> temporary.with_prefix("wibble")
  use file <- temporary.create(file)

  let assert Ok(name) = filepath.split(file) |> list.last
  string.starts_with(name, "wibble") |> should.be_true
}

pub fn in_directory_test() {
  use dir <- temporary.create(temporary.directory())
  simplifile.is_directory(dir) |> should.equal(Ok(True))

  use file <- temporary.create(temporary.file() |> temporary.in_directory(dir))
  simplifile.is_file(file) |> should.equal(Ok(True))

  let assert Ok([written_file]) = simplifile.read_directory(dir)
  filepath.join(dir, written_file) |> should.equal(file)
}

pub fn in_directory_with_directory_test() {
  use dir <- temporary.create(temporary.directory())
  simplifile.is_directory(dir) |> should.equal(Ok(True))

  let dir2 = temporary.directory() |> temporary.in_directory(dir)
  use dir2 <- temporary.create(dir2)
  simplifile.is_directory(dir2) |> should.equal(Ok(True))

  let assert Ok([written_dir]) = simplifile.read_directory(dir)
  filepath.join(dir, written_dir) |> should.equal(dir2)
}
