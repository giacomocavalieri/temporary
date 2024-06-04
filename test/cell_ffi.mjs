import { Ok, Error } from "./gleam.mjs";

export function new_cell() {
  return { value: new Error() };
}

export function set_cell(cell, value) {
  cell.value = new Ok(value);
  return undefined;
}

export function get_cell(cell) {
  return cell.value;
}
