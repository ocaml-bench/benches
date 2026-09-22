let bench_type = Sys.argv.(1)
let length = int_of_string Sys.argv.(2)
let iterations = int_of_string Sys.argv.(3)

let bytes_unaligned_get_int64 iterations length =
  let b = Bytes.make length 'x' in
  let n = (length - 3) / 8 in
  let acc = ref 0 in
  for _ = 1 to iterations do
    for k = 0 to n - 1 do
      acc := !acc + Int64.to_int (Bytes.get_int64_ne b (3 + k * 8))
    done
  done;
  ignore (Sys.opaque_identity !acc)

let bytes_unaligned_set_int64 iterations length =
  let b = Bytes.make length 'x' in
  let n = (length - 3) / 8 in
  for _ = 1 to iterations do
    for k = 0 to n - 1 do
      Bytes.set_int64_ne b (3 + k * 8) (Int64.of_int k)
    done
  done;
  ignore (Sys.opaque_identity b)

let bytes_unaligned_get_int32 iterations length =
  let b = Bytes.make length 'x' in
  let n = (length - 3) / 4 in
  let acc = ref 0 in
  for _ = 1 to iterations do
    for k = 0 to n - 1 do
      acc := !acc + Int32.to_int (Bytes.get_int32_ne b (3 + k * 4))
    done
  done;
  ignore (Sys.opaque_identity !acc)

let bytes_unaligned_set_int32 iterations length =
  let b = Bytes.make length 'x' in
  let n = (length - 3) / 4 in
  for _ = 1 to iterations do
    for k = 0 to n - 1 do
      Bytes.set_int32_ne b (3 + k * 4) (Int32.of_int k)
    done
  done;
  ignore (Sys.opaque_identity b)

let bytes_unaligned_get_uint16 iterations length =
  let b = Bytes.make length 'x' in
  let n = (length - 3) / 2 in
  let acc = ref 0 in
  for _ = 1 to iterations do
    for k = 0 to n - 1 do
      acc := !acc + Bytes.get_uint16_ne b (3 + k * 2)
    done
  done;
  ignore (Sys.opaque_identity !acc)

let bytes_unaligned_set_uint16 iterations length =
  let b = Bytes.make length 'x' in
  let n = (length - 3) / 2 in
  for _ = 1 to iterations do
    for k = 0 to n - 1 do
      Bytes.set_uint16_ne b (3 + k * 2) k
    done
  done;
  ignore (Sys.opaque_identity b)

let () =
  match bench_type with
  | "bytes_unaligned_get_int64" ->
      bytes_unaligned_get_int64 iterations length
  | "bytes_unaligned_set_int64" ->
      bytes_unaligned_set_int64 iterations length
  | "bytes_unaligned_get_int32" ->
      bytes_unaligned_get_int32 iterations length
  | "bytes_unaligned_set_int32" ->
      bytes_unaligned_set_int32 iterations length
  | "bytes_unaligned_get_uint16" ->
      bytes_unaligned_get_uint16 iterations length
  | "bytes_unaligned_set_uint16" ->
      bytes_unaligned_set_uint16 iterations length
  | _ ->
      ()
