import envoy
import exception
import filepath
import gleam/bit_array
import gleam/crypto
import gleam/option.{type Option, None, Some}
import gleam/result
import simplifile

pub opaque type Builder {
  Builder(
    kind: Kind,
    temp_directory: Option(String),
    name_prefix: Option(String),
    name_suffix: Option(String),
  )
}

pub type Kind {
  File
  Directory
}

pub fn file() -> Builder {
  Builder(
    kind: File,
    temp_directory: None,
    name_prefix: None,
    name_suffix: None,
  )
}

pub fn directory() -> Builder {
  Builder(
    kind: Directory,
    temp_directory: None,
    name_prefix: None,
    name_suffix: None,
  )
}

pub fn in_directory(builder: Builder, directory: String) -> Builder {
  Builder(..builder, temp_directory: Some(directory))
}

pub fn with_prefix(builder: Builder, name_prefix: String) -> Builder {
  Builder(..builder, name_prefix: Some(name_prefix))
}

pub fn with_suffix(builder: Builder, name_suffix: String) -> Builder {
  Builder(..builder, name_suffix: Some(name_suffix))
}

pub fn create(builder: Builder, run fun: fn(String) -> a) -> Result(a, Nil) {
  let Builder(
    kind: kind,
    temp_directory: temp_directory,
    name_prefix: name_prefix,
    name_suffix: name_suffix,
  ) = builder
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
    Error(_) -> Error(Nil)
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
