import envoy
import exception
import filepath
import gleam/bit_array
import gleam/crypto
import gleam/option.{type Option, None, Some}
import gleam/result
import simplifile

pub opaque type TempFile {
  TempFile(
    kind: Kind,
    temp_directory: Option(String),
    name_prefix: Option(String),
    name_suffix: Option(String),
  )
}

type Kind {
  File
  Directory
}

/// The description of a new default temporary file.
///
/// It can be customised using the `set_prefix`, `set_suffix` or `in_directory`
/// functions.
///
pub fn file() -> TempFile {
  TempFile(
    kind: File,
    temp_directory: None,
    name_prefix: None,
    name_suffix: None,
  )
}

/// The description of a new default temporary directory.
///
/// It can be customised using the `set_prefix`, `set_suffix` or `in_directory`
/// functions.
///
pub fn directory() -> TempFile {
  TempFile(
    kind: Directory,
    temp_directory: None,
    name_prefix: None,
    name_suffix: None,
  )
}

/// Set the directory the random file is going to be placed into.
/// If this value is not set, the system's default temp directory is picked,
/// searching in the following order:
///
/// 1. The value of the `TMPDIR` environment variable, if it is set
/// 2. The value of the `TEMP` environment variable, if it is set
/// 3. The value of the `TMP` environment variable, if it is set
/// 4. `C:\TMP` on Windows or `/tmp` on Unix-like operating systems
///
/// ## Examples
///
/// If you don't want to put the temporary file under the system's default temp
/// directory you can set your own:
///
/// ```gleam
/// temporary.file()
/// |> temporary.in_directory("/Users/me/custom_temp_dir")
/// ```
///
pub fn in_directory(temp_file: TempFile, directory: String) -> TempFile {
  TempFile(..temp_file, temp_directory: Some(directory))
}

/// Set a fixed prefix that is going to be added to the temporary file's name.
///
/// ## Examples
///
/// ```
/// temporary.file()
/// |> temporary.with_prefix("wibble")
/// |> temporary.create(fn(file) {
///   // The temporary file will have a random
///   // name that starts with `wibble`.
/// })
/// ```
///
pub fn with_prefix(temp_file: TempFile, name_prefix: String) -> TempFile {
  TempFile(..temp_file, name_prefix: Some(name_prefix))
}

/// Set a fixed suffix that is going to be added to the temporary file's name.
///
/// ## Examples
///
/// ```
/// temporary.file()
/// |> temporary.with_suffix("wibble")
/// |> temporary.create(fn(file) {
///   // The temporary file will have a random name
///   // that ends with `wibble`.
/// })
///
/// ```
///
pub fn with_suffix(temp_file: TempFile, name_suffix: String) -> TempFile {
  TempFile(..temp_file, name_suffix: Some(name_suffix))
}

/// Creates a temporary file and runs the given function passing it the full
/// path to that file.
///
/// Returns the result of the function wrapped in `Ok`, or `Error` wrapping a
/// [`simplifile.FileError`](https://hexdocs.pm/simplifile/simplifile.html#FileError)
/// if the file could not be created.
///
/// In any case, any temporary file will automatically be deleted!
///
/// ## Examples
///
/// To create a default temporary file:
///
/// ```gleam
/// pub fn main() {
///   use file <- temporary.create(temporary.file())
///   let assert Ok(_) = simplifile.write("Hello!", to: file)
/// }
/// ```
///
/// You can even create more complex temporary directories with temporary files
/// inside:
///
/// ```gleam
/// pub fn main() {
///   use dir <- temporary.create(temporary.directory())
///   let file = temporary.file() |> temporary.in_directory(dir)
///   use file <- temporary.create(file)
///   //  ^^^^ `file` will be under the `dir` temporary directory!
///
///   let assert Ok(_) = simplifile.write("Hello!", to: file)
/// }
/// ```
///
pub fn create(
  temp_file: TempFile,
  run fun: fn(String) -> a,
) -> Result(a, simplifile.FileError) {
  let TempFile(
    kind: kind,
    temp_directory: temp_directory,
    name_prefix: name_prefix,
    name_suffix: name_suffix,
  ) = temp_file
  let temp = option.unwrap(temp_directory, get_temp_directory())
  let name =
    option.unwrap(name_prefix, "")
    <> get_random_name()
    <> option.unwrap(name_suffix, "")

  let path = filepath.join(temp, name)
  let result = case kind {
    File -> simplifile.create_file(path)
    Directory -> simplifile.create_directory(path)
  }

  case result {
    Error(error) -> Error(error)
    Ok(_) -> {
      use <- exception.defer(fn() { simplifile.delete(path) })
      Ok(fun(path))
    }
  }
}

fn get_temp_directory() -> String {
  let temp = {
    use <- result.lazy_or(envoy.get("TMPDIR"))
    use <- result.lazy_or(envoy.get("TEMP"))
    envoy.get("TMP")
  }

  case temp {
    Ok(temp) -> temp
    Error(_) ->
      case is_windows() {
        True -> "C:\\TMP"
        False -> "/tmp"
      }
  }
}

fn get_random_name() -> String {
  crypto.strong_random_bytes(16)
  |> bit_array.base16_encode
}

@external(erlang, "temporary_ffi", "is_windows")
@external(javascript, "./temporary_ffi.mjs", "is_windows")
fn is_windows() -> Bool
