
let parse f s  = 
  f Lexer.lexer (Lexing.from_string s)
  
let () = 
  let s = "
  message TestM { 
    enum TestE {
      TestE_Value1 = 1; 
      TestE_Value2 = 2; 
    }
    required TestE teste_field = 1; 
  }"
  in 
  let m = parse Parser.message_ s in 
  let all_types = Pbtt_util.compile_message_p1 Pbtt_util.empty_scope m in 
  assert (2 =List.length all_types); 
  let (Pbtt.Enum {
    Pbtt.enum_scope;
    Pbtt.enum_name; 
    Pbtt.enum_values
  }) = List.nth all_types 0 in 
  assert ("TestE" = enum_name); 
  assert (2 = List.length enum_values); 
  assert ({Pbtt.namespaces = []; Pbtt.message_names = ["TestM"]} = enum_scope);
  ()

let () = 
  let s = "
  message Test {
    required int64 ival  = 1;
    required string sval = 2;
  }"
  in 
  let ast  = parse Parser.message_ s in 
  let all_messages = Pbtt_util.compile_message_p1 Pbtt_util.empty_scope ast in  
  assert (List.length all_messages = 1);
  let (Pbtt.Message {
    Pbtt.message_scope; 
    Pbtt.message_name;
    Pbtt.message_body; 
  }) = List.hd all_messages in 
  assert (Pbtt_util.empty_scope = message_scope);
  assert ("Test" = message_name); 
  assert (2 = List.length message_body); 
  

  let test_fields message_body = 
    let f1 = List.nth message_body 0 in 
    let f1 = match f1 with 
      | Pbtt.Message_field f -> f
      | _ -> assert(false)
    in 
    assert (Pbtt_util.field_name f1 = "ival"); 
    assert (f1.Pbtt.field_type  = Pbtt.Field_type_int64);
    assert (Pbtt_util.field_number f1 = 1); 
    assert (None = f1.Pbtt.field_default); 
    
    let f2 = List.nth message_body 1 in 
    let f2 = match f2 with 
      | Pbtt.Message_field f -> f
      | _ -> assert(false)
    in 
    assert (Pbtt_util.field_name f2 = "sval"); 
    assert (f2.Pbtt.field_type  = Pbtt.Field_type_string);
    assert (Pbtt_util.field_number f2 = 2); 
    assert (None = f2.Pbtt.field_default); 
    ()
  in 
  test_fields message_body; 
  let s = "
  message Test {
    message Inner {
      required int64 ival  = 1;
      required string sval = 2;
    }
  }"
  in 
  let ast  = parse Parser.message_ s in 
  let all_messages = Pbtt_util.compile_message_p1 Pbtt_util.empty_scope ast in  
  assert (List.length all_messages = 2);
  let (Pbtt.Message {
    Pbtt.message_scope; 
    Pbtt.message_name;
    Pbtt.message_body; 
  }) = List.hd all_messages in 
  assert (1 = List.length message_scope.Pbtt.message_names);
  assert ("Inner" = message_name); 
  assert (2 = List.length message_body); 
  test_fields message_body; 
  let expected_scope = {
    Pbtt.namespaces = []; 
    Pbtt.message_names = [ "Test" ] 
  } in 
  assert(expected_scope = message_scope);
  let (Pbtt.Message {
    Pbtt.message_scope; 
    Pbtt.message_name;
    Pbtt.message_body; 
  }) = List.nth all_messages 1 in 
  assert (Pbtt_util.empty_scope = message_scope);
  assert ("Test" = message_name); 
  assert (0 = List.length message_body); 
  ()

let () = 
  let s = "
  message Test {
    required Msg1.Msg2.SubMessage mval  = 1;
  }"
  in 
  let ast  = parse Parser.message_ s in 
  let all_messages = Pbtt_util.compile_message_p1 Pbtt_util.empty_scope ast in  
  assert (List.length all_messages = 1);
  let (Pbtt.Message {
    Pbtt.message_scope; 
    Pbtt.message_name;
    Pbtt.message_body; 
  }) = List.hd all_messages in 
  assert (Pbtt_util.empty_scope  = message_scope);
  assert ("Test" = message_name); 
  assert (1 = List.length message_body); 
  let f1 = List.nth message_body 0 in 
  let f1 = match f1 with | Pbtt.Message_field f -> f | _ -> assert(false) in 
  assert ("mval" = Pbtt_util.field_name f1); 
  assert (1 = Pbtt_util.field_number f1); 
  let unresolved = {
    Pbtt.scope     = ["Msg1";"Msg2"];
    Pbtt.type_name = "SubMessage";
    Pbtt.from_root = false;
  } in 
  assert ((Pbtt.Field_type_type unresolved) = f1.Pbtt.field_type); 
  ()

let () = 
  let s = "
  message M1 { 
    message M2 { message M21 { } } 
    message M3 { message M31 { message M311 { } } } 
  }
  " in 
  let ast = parse Parser.message_ s in 
  let all_messages = Pbtt_util.compile_message_p1 Pbtt_util.empty_scope  ast in 
  assert (6 = List.length all_messages); 
  let filtered = Pbtt_util.find_all_types_in_field_scope all_messages [] in 
  assert (1 = List.length filtered);
  let filtered = Pbtt_util.find_all_types_in_field_scope all_messages ["M1"] in 
  assert (2 = List.length filtered);
  let filtered = Pbtt_util.find_all_types_in_field_scope all_messages ["M1";"M2"] in 
  assert (1 = List.length filtered);
  let filtered = Pbtt_util.find_all_types_in_field_scope all_messages ["M1";"M3"] in 
  assert (1 = List.length filtered);
  let filtered = Pbtt_util.find_all_types_in_field_scope all_messages ["M1";"M3";"M31"] in 
  assert (1 = List.length filtered);
  ()


let () = 
  print_endline "Pbtt Compile P1 ... Ok"
