module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp::@ps_availqty({type = i32}), ps_comment => @partsupp::@ps_comment({type = !db.string}), ps_partkey => @partsupp::@ps_partkey({type = i32}), ps_suppkey => @partsupp::@ps_suppkey({type = i32}), ps_supplycost => @partsupp::@ps_supplycost({type = !db.decimal<15, 2>})}
    %1 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.selection %2 (%arg0: !relalg.tuple){
      %7 = relalg.getcol %arg0 @part::@p_partkey : i32
      %8 = relalg.getcol %arg0 @partsupp::@ps_partkey : i32
      %9 = db.compare eq %7 : i32, %8 : i32
      %10 = relalg.getcol %arg0 @part::@p_brand : !db.string
      %11 = db.constant("Brand#45") : !db.string
      %12 = db.compare neq %10 : !db.string, %11 : !db.string
      %13 = relalg.getcol %arg0 @part::@p_type : !db.string
      %14 = db.constant("MEDIUM POLISHED%") : !db.string
      %15 = db.runtime_call "Like"(%13, %14) : (!db.string, !db.string) -> i1
      %16 = db.not %15 : i1
      %17 = db.constant(49 : i32) : i32
      %18 = db.constant(14 : i32) : i32
      %19 = db.constant(23 : i32) : i32
      %20 = db.constant(45 : i32) : i32
      %21 = db.constant(19 : i32) : i32
      %22 = db.constant(3 : i32) : i32
      %23 = db.constant(36 : i32) : i32
      %24 = db.constant(9 : i32) : i32
      %25 = relalg.getcol %arg0 @part::@p_size : i32
      %26 = db.oneof %25 : i32 ? %17, %18, %19, %20, %21, %22, %23, %24 : i32, i32, i32, i32, i32, i32, i32, i32
      %27 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
      %28 = relalg.selection %27 (%arg1: !relalg.tuple){
        %33 = relalg.getcol %arg1 @supplier::@s_comment : !db.string
        %34 = db.constant("%Customer%Complaints%") : !db.string
        %35 = db.runtime_call "Like"(%33, %34) : (!db.string, !db.string) -> i1
        relalg.return %35 : i1
      }
      %29 = relalg.selection %28 (%arg1: !relalg.tuple){
        %33 = relalg.getcol %arg1 @partsupp::@ps_suppkey : i32
        %34 = relalg.getcol %arg1 @supplier::@s_suppkey : i32
        %35 = db.compare eq %33 : i32, %34 : i32
        relalg.return %35 : i1
      }
      %30 = relalg.exists %29
      %31 = db.not %30 : i1
      %32 = db.and %9, %12, %16, %26, %31 : i1, i1, i1, i1, i1
      relalg.return %32 : i1
    }
    %4 = relalg.aggregation %3 [@part::@p_brand,@part::@p_type,@part::@p_size] computes : [@aggr0::@tmp_attr0({type = i64})] (%arg0: !relalg.tuplestream,%arg1: !relalg.tuple){
      %7 = relalg.projection distinct [@partsupp::@ps_suppkey] %arg0
      %8 = relalg.aggrfn count @partsupp::@ps_suppkey %7 : i64
      relalg.return %8 : i64
    }
    %5 = relalg.sort %4 [(@aggr0::@tmp_attr0,desc),(@part::@p_brand,asc),(@part::@p_type,asc),(@part::@p_size,asc)]
    %6 = relalg.materialize %5 [@part::@p_brand,@part::@p_type,@part::@p_size,@aggr0::@tmp_attr0] => ["p_brand", "p_type", "p_size", "supplier_cnt"] : !dsa.table
    return %6 : !dsa.table
  }
}
