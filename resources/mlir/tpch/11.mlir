module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp::@ps_availqty({type = i32}), ps_comment => @partsupp::@ps_comment({type = !db.string}), ps_partkey => @partsupp::@ps_partkey({type = i32}), ps_suppkey => @partsupp::@ps_suppkey({type = i32}), ps_supplycost => @partsupp::@ps_supplycost({type = !db.decimal<15, 2>})}
    %1 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation::@n_name({type = !db.string}), n_nationkey => @nation::@n_nationkey({type = i32}), n_regionkey => @nation::@n_regionkey({type = i32})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.selection %4 (%arg0: !relalg.tuple){
      %11 = relalg.getcol %arg0 @partsupp::@ps_suppkey : i32
      %12 = relalg.getcol %arg0 @supplier::@s_suppkey : i32
      %13 = db.compare eq %11 : i32, %12 : i32
      %14 = relalg.getcol %arg0 @supplier::@s_nationkey : i32
      %15 = relalg.getcol %arg0 @nation::@n_nationkey : i32
      %16 = db.compare eq %14 : i32, %15 : i32
      %17 = relalg.getcol %arg0 @nation::@n_name : !db.string
      %18 = db.constant("GERMANY") : !db.string
      %19 = db.compare eq %17 : !db.string, %18 : !db.string
      %20 = db.and %13, %16, %19 : i1, i1, i1
      relalg.return %20 : i1
    }
    %6 = relalg.map %5 computes : [@map0::@tmp_attr3({type = !db.decimal<30, 4>}),@map0::@tmp_attr1({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuple){
      %11 = relalg.getcol %arg0 @partsupp::@ps_supplycost : !db.decimal<15, 2>
      %12 = relalg.getcol %arg0 @partsupp::@ps_availqty : i32
      %13 = db.cast %12 : i32 -> !db.decimal<15, 2>
      %14 = db.mul %11 : !db.decimal<15, 2>, %13 : !db.decimal<15, 2>
      %15 = relalg.getcol %arg0 @partsupp::@ps_supplycost : !db.decimal<15, 2>
      %16 = relalg.getcol %arg0 @partsupp::@ps_availqty : i32
      %17 = db.cast %16 : i32 -> !db.decimal<15, 2>
      %18 = db.mul %15 : !db.decimal<15, 2>, %17 : !db.decimal<15, 2>
      relalg.return %14, %18 : !db.decimal<30, 4>, !db.decimal<30, 4>
    }
    %7 = relalg.aggregation %6 [@partsupp::@ps_partkey] computes : [@aggr0::@tmp_attr2({type = !db.decimal<30, 4>}),@aggr0::@tmp_attr0({type = !db.decimal<30, 4>})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %11 = relalg.aggrfn sum @map0::@tmp_attr3 %arg0 : !db.decimal<30, 4>
      %12 = relalg.aggrfn sum @map0::@tmp_attr1 %arg0 : !db.decimal<30, 4>
      relalg.return %11, %12 : !db.decimal<30, 4>, !db.decimal<30, 4>
    }
    %8 = relalg.selection %7 (%arg0: !relalg.tuple){
      %11 = relalg.getcol %arg0 @aggr0::@tmp_attr2 : !db.decimal<30, 4>
      %12 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp1::@ps_availqty({type = i32}), ps_comment => @partsupp1::@ps_comment({type = !db.string}), ps_partkey => @partsupp1::@ps_partkey({type = i32}), ps_suppkey => @partsupp1::@ps_suppkey({type = i32}), ps_supplycost => @partsupp1::@ps_supplycost({type = !db.decimal<15, 2>})}
      %13 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier1::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier1::@s_address({type = !db.string}), s_comment => @supplier1::@s_comment({type = !db.string}), s_name => @supplier1::@s_name({type = !db.string}), s_nationkey => @supplier1::@s_nationkey({type = i32}), s_phone => @supplier1::@s_phone({type = !db.string}), s_suppkey => @supplier1::@s_suppkey({type = i32})}
      %14 = relalg.crossproduct %12, %13
      %15 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation1::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation1::@n_name({type = !db.string}), n_nationkey => @nation1::@n_nationkey({type = i32}), n_regionkey => @nation1::@n_regionkey({type = i32})}
      %16 = relalg.crossproduct %14, %15
      %17 = relalg.selection %16 (%arg1: !relalg.tuple){
        %24 = relalg.getcol %arg1 @partsupp1::@ps_suppkey : i32
        %25 = relalg.getcol %arg1 @supplier1::@s_suppkey : i32
        %26 = db.compare eq %24 : i32, %25 : i32
        %27 = relalg.getcol %arg1 @supplier1::@s_nationkey : i32
        %28 = relalg.getcol %arg1 @nation1::@n_nationkey : i32
        %29 = db.compare eq %27 : i32, %28 : i32
        %30 = relalg.getcol %arg1 @nation1::@n_name : !db.string
        %31 = db.constant("GERMANY") : !db.string
        %32 = db.compare eq %30 : !db.string, %31 : !db.string
        %33 = db.and %26, %29, %32 : i1, i1, i1
        relalg.return %33 : i1
      }
      %18 = relalg.map %17 computes : [@map1::@tmp_attr5({type = !db.decimal<30, 4>})] (%arg1: !relalg.tuple){
        %24 = relalg.getcol %arg1 @partsupp1::@ps_supplycost : !db.decimal<15, 2>
        %25 = relalg.getcol %arg1 @partsupp1::@ps_availqty : i32
        %26 = db.cast %25 : i32 -> !db.decimal<15, 2>
        %27 = db.mul %24 : !db.decimal<15, 2>, %26 : !db.decimal<15, 2>
        relalg.return %27 : !db.decimal<30, 4>
      }
      %19 = relalg.aggregation %18 [] computes : [@aggr1::@tmp_attr4({type = !db.nullable<!db.decimal<30, 4>>})] (%arg1: !relalg.tuplestream,%arg2: !relalg.tuple){
        %24 = relalg.aggrfn sum @map1::@tmp_attr5 %arg1 : !db.nullable<!db.decimal<30, 4>>
        relalg.return %24 : !db.nullable<!db.decimal<30, 4>>
      }
      %20 = relalg.map %19 computes : [@map2::@tmp_attr6({type = !db.nullable<!db.decimal<35, 8>>})] (%arg1: !relalg.tuple){
        %24 = relalg.getcol %arg1 @aggr1::@tmp_attr4 : !db.nullable<!db.decimal<30, 4>>
        %25 = db.constant("0.0001") : !db.decimal<5, 4>
        %26 = db.mul %24 : !db.nullable<!db.decimal<30, 4>>, %25 : !db.decimal<5, 4>
        relalg.return %26 : !db.nullable<!db.decimal<35, 8>>
      }
      %21 = relalg.getscalar @map2::@tmp_attr6 %20 : !db.nullable<!db.decimal<35, 8>>
      %22 = db.cast %11 : !db.decimal<30, 4> -> !db.decimal<35, 8>
      %23 = db.compare gt %22 : !db.decimal<35, 8>, %21 : !db.nullable<!db.decimal<35, 8>>
      relalg.return %23 : !db.nullable<i1>
    }
    %9 = relalg.sort %8 [(@aggr0::@tmp_attr0,desc)]
    %10 = relalg.materialize %9 [@partsupp::@ps_partkey,@aggr0::@tmp_attr0] => ["ps_partkey", "value"] : !dsa.table
    return %10 : !dsa.table
  }
}
