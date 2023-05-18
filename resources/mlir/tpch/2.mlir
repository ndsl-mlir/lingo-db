module {
  func.func @main() -> !dsa.table {
    %0 = relalg.basetable  {table_identifier = "part"} columns: {p_brand => @part::@p_brand({type = !db.string}), p_comment => @part::@p_comment({type = !db.string}), p_container => @part::@p_container({type = !db.string}), p_mfgr => @part::@p_mfgr({type = !db.string}), p_name => @part::@p_name({type = !db.string}), p_partkey => @part::@p_partkey({type = i32}), p_retailprice => @part::@p_retailprice({type = !db.decimal<15, 2>}), p_size => @part::@p_size({type = i32}), p_type => @part::@p_type({type = !db.string})}
    %1 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier::@s_address({type = !db.string}), s_comment => @supplier::@s_comment({type = !db.string}), s_name => @supplier::@s_name({type = !db.string}), s_nationkey => @supplier::@s_nationkey({type = i32}), s_phone => @supplier::@s_phone({type = !db.string}), s_suppkey => @supplier::@s_suppkey({type = i32})}
    %2 = relalg.crossproduct %0, %1
    %3 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp::@ps_availqty({type = i32}), ps_comment => @partsupp::@ps_comment({type = !db.string}), ps_partkey => @partsupp::@ps_partkey({type = i32}), ps_suppkey => @partsupp::@ps_suppkey({type = i32}), ps_supplycost => @partsupp::@ps_supplycost({type = !db.decimal<15, 2>})}
    %4 = relalg.crossproduct %2, %3
    %5 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation::@n_name({type = !db.string}), n_nationkey => @nation::@n_nationkey({type = i32}), n_regionkey => @nation::@n_regionkey({type = i32})}
    %6 = relalg.crossproduct %4, %5
    %7 = relalg.basetable  {table_identifier = "region"} columns: {r_comment => @region::@r_comment({type = !db.nullable<!db.string>}), r_name => @region::@r_name({type = !db.string}), r_regionkey => @region::@r_regionkey({type = i32})}
    %8 = relalg.crossproduct %6, %7
    %9 = relalg.selection %8 (%arg0: !relalg.tuple){
      %13 = relalg.getcol %arg0 @part::@p_partkey : i32
      %14 = relalg.getcol %arg0 @partsupp::@ps_partkey : i32
      %15 = db.compare eq %13 : i32, %14 : i32
      %16 = relalg.getcol %arg0 @supplier::@s_suppkey : i32
      %17 = relalg.getcol %arg0 @partsupp::@ps_suppkey : i32
      %18 = db.compare eq %16 : i32, %17 : i32
      %19 = relalg.getcol %arg0 @part::@p_size : i32
      %20 = db.constant(15 : i32) : i32
      %21 = db.compare eq %19 : i32, %20 : i32
      %22 = relalg.getcol %arg0 @part::@p_type : !db.string
      %23 = db.constant("%BRASS") : !db.string
      %24 = db.runtime_call "Like"(%22, %23) : (!db.string, !db.string) -> i1
      %25 = relalg.getcol %arg0 @supplier::@s_nationkey : i32
      %26 = relalg.getcol %arg0 @nation::@n_nationkey : i32
      %27 = db.compare eq %25 : i32, %26 : i32
      %28 = relalg.getcol %arg0 @nation::@n_regionkey : i32
      %29 = relalg.getcol %arg0 @region::@r_regionkey : i32
      %30 = db.compare eq %28 : i32, %29 : i32
      %31 = relalg.getcol %arg0 @region::@r_name : !db.string
      %32 = db.constant("EUROPE") : !db.string
      %33 = db.compare eq %31 : !db.string, %32 : !db.string
      %34 = relalg.getcol %arg0 @partsupp::@ps_supplycost : !db.decimal<15, 2>
      %35 = relalg.basetable  {table_identifier = "partsupp"} columns: {ps_availqty => @partsupp1::@ps_availqty({type = i32}), ps_comment => @partsupp1::@ps_comment({type = !db.string}), ps_partkey => @partsupp1::@ps_partkey({type = i32}), ps_suppkey => @partsupp1::@ps_suppkey({type = i32}), ps_supplycost => @partsupp1::@ps_supplycost({type = !db.decimal<15, 2>})}
      %36 = relalg.basetable  {table_identifier = "supplier"} columns: {s_acctbal => @supplier1::@s_acctbal({type = !db.decimal<15, 2>}), s_address => @supplier1::@s_address({type = !db.string}), s_comment => @supplier1::@s_comment({type = !db.string}), s_name => @supplier1::@s_name({type = !db.string}), s_nationkey => @supplier1::@s_nationkey({type = i32}), s_phone => @supplier1::@s_phone({type = !db.string}), s_suppkey => @supplier1::@s_suppkey({type = i32})}
      %37 = relalg.crossproduct %35, %36
      %38 = relalg.basetable  {table_identifier = "nation"} columns: {n_comment => @nation1::@n_comment({type = !db.nullable<!db.string>}), n_name => @nation1::@n_name({type = !db.string}), n_nationkey => @nation1::@n_nationkey({type = i32}), n_regionkey => @nation1::@n_regionkey({type = i32})}
      %39 = relalg.crossproduct %37, %38
      %40 = relalg.basetable  {table_identifier = "region"} columns: {r_comment => @region1::@r_comment({type = !db.nullable<!db.string>}), r_name => @region1::@r_name({type = !db.string}), r_regionkey => @region1::@r_regionkey({type = i32})}
      %41 = relalg.crossproduct %39, %40
      %42 = relalg.selection %41 (%arg1: !relalg.tuple){
        %47 = relalg.getcol %arg1 @part::@p_partkey : i32
        %48 = relalg.getcol %arg1 @partsupp1::@ps_partkey : i32
        %49 = db.compare eq %47 : i32, %48 : i32
        %50 = relalg.getcol %arg1 @supplier1::@s_suppkey : i32
        %51 = relalg.getcol %arg1 @partsupp1::@ps_suppkey : i32
        %52 = db.compare eq %50 : i32, %51 : i32
        %53 = relalg.getcol %arg1 @supplier1::@s_nationkey : i32
        %54 = relalg.getcol %arg1 @nation1::@n_nationkey : i32
        %55 = db.compare eq %53 : i32, %54 : i32
        %56 = relalg.getcol %arg1 @nation1::@n_regionkey : i32
        %57 = relalg.getcol %arg1 @region1::@r_regionkey : i32
        %58 = db.compare eq %56 : i32, %57 : i32
        %59 = relalg.getcol %arg1 @region1::@r_name : !db.string
        %60 = db.constant("EUROPE") : !db.string
        %61 = db.compare eq %59 : !db.string, %60 : !db.string
        %62 = db.and %49, %52, %55, %58, %61 : i1, i1, i1, i1, i1
        relalg.return %62 : i1
      }
      %43 = relalg.aggregation %42 [] computes : [@aggr0::@tmp_attr0({type = !db.nullable<!db.decimal<15, 2>>})] (%arg1: !relalg.tuplestream,%arg2: !relalg.tuple){
        %47 = relalg.aggrfn min @partsupp1::@ps_supplycost %arg1 : !db.nullable<!db.decimal<15, 2>>
        relalg.return %47 : !db.nullable<!db.decimal<15, 2>>
      }
      %44 = relalg.getscalar @aggr0::@tmp_attr0 %43 : !db.nullable<!db.decimal<15, 2>>
      %45 = db.compare eq %34 : !db.decimal<15, 2>, %44 : !db.nullable<!db.decimal<15, 2>>
      %46 = db.and %15, %18, %21, %24, %27, %30, %33, %45 : i1, i1, i1, i1, i1, i1, i1, !db.nullable<i1>
      relalg.return %46 : !db.nullable<i1>
    }
    %10 = relalg.sort %9 [(@supplier::@s_acctbal,desc),(@nation::@n_name,asc),(@supplier::@s_name,asc),(@part::@p_partkey,asc)]
    %11 = relalg.limit 100 %10
    %12 = relalg.materialize %11 [@supplier::@s_acctbal,@supplier::@s_name,@nation::@n_name,@part::@p_partkey,@part::@p_mfgr,@supplier::@s_address,@supplier::@s_phone,@supplier::@s_comment] => ["s_acctbal", "s_name", "n_name", "p_partkey", "p_mfgr", "s_address", "s_phone", "s_comment"] : !dsa.table
    return %12 : !dsa.table
  }
}
