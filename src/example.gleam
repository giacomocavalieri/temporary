import simplifile
import temporary

pub fn main() {
  todo as "Done"
}

pub fn without_use() {
  temporary.create(temporary.directory(), fn(dir) {
    temporary.create(temporary.file() |> temporary.in_directory(dir), fn(file) {
      let assert Ok(_) = simplifile.write("Hello!", to: file)
      todo as "Done"
    })
  })
}
