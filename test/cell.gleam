pub type Cell(a)

@external(erlang, "cell_ffi", "new")
@external(javascript, "./cell_ffi.mjs", "new_cell")
pub fn new() -> Cell(a)

@external(erlang, "cell_ffi", "set")
@external(javascript, "./cell_ffi.mjs", "set_cell")
pub fn set(cell: Cell(a), value: a) -> Nil

@external(erlang, "cell_ffi", "get")
@external(javascript, "./cell_ffi.mjs", "get_cell")
pub fn get(cell: Cell(a)) -> Result(a, Nil)
